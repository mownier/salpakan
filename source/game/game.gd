
extends Node2D

const PHASE_INITIAL = 0
const PHASE_START = 1
const TURN_WHITE = 0
const TURN_BLACK = 1
const CHAT_COMMANDS = [
	":new game:",
	":quit:"
]

onready var global = get_node("/root/global")
onready var board = get_node("board")
onready var black_start = get_node("black_start")
onready var white_start = get_node("white_start")
onready var messages = get_node("messages")
onready var message = get_node("message")
onready var send = get_node("send")
onready var lobby_id = global.get_lobby_id()
onready var game_id = global.get_game_id()

var Arbiter = preload("res://source/common/arbiter.gd")

var player
var opponent
var arbiter

var eliminated
var pre_winner
var winner
var turn

var firebase

var phase = PHASE_INITIAL
var black_ready = false
var white_ready = false

func _ready():
	firebase = global.create_firebase()
	player = global.get_player()
	opponent = global.get_opponent()
	arbiter = Arbiter.new(firebase, get_arbiter_path())
	
	send.connect("pressed", self, "on_send")
	board.connect("board_on_drop", self, "board_on_drop")
	firebase.connect("firebase_on_success", self, "firebase_on_success")
	firebase.connect("firebase_on_error", self, "firebase_on_error")
	firebase.connect("firebase_on_stream", self, "firebase_on_stream")
	
	setup_start_buttons()
	setup_black()
	setup_white()
	
	reveal(opponent.get_color(), false)
	freeze(opponent.get_color())
	disable_start(opponent.get_color())
	
	var path = get_game_path()
	firebase.listen(path)

func setup_start_buttons():
	black_start.connect("pressed", self, "on_black_ready")
	white_start.connect("pressed", self, "on_white_ready")
	
	var board_width = board.get_size().width
	var board_height = board.get_size().height
	
	var y_offset = 64
	var x = (board_width - black_start.get_size().width) / 2
	var y = (y_offset - black_start.get_size().height) / 2
	black_start.set_pos(Vector2(x, y))
	
	x = (board_width - white_start.get_size().width) / 2 
	y = board_height - white_start.get_size().height - (y_offset - white_start.get_size().height) / 2
	white_start.set_pos(Vector2(x, y))

func on_black_ready():
	arbiter.on_ready(global.PIECE_BLACK)

func on_white_ready():
	arbiter.on_ready(global.PIECE_WHITE)

func set_black_ready(ready):
	var ignore = false
	var text = "END PHASE"
	if ready:
		ignore = true
		text = "READY"
		freeze(global.PIECE_BLACK)
	else:
		unfreeze(global.PIECE_BLACK)
	
	black_ready = ready
	black_start.set_text(text)
	black_start.set_ignore_mouse(ignore)

func set_white_ready(ready):
	var ignore = false
	var text = "END PHASE"
	if ready:
		ignore = true
		text = "READY"
		freeze(global.PIECE_WHITE)
	else:
		unfreeze(global.PIECE_WHITE)
	
	white_ready = ready
	white_start.set_text(text)
	white_start.set_ignore_mouse(ignore)

func freeze(color):
	get_tree().call_group(0, color, "enable_drag", false)

func unfreeze(color):
	get_tree().call_group(0, color, "enable_drag", true)

func on_ready():
	phase = PHASE_START
	black_start.set_hidden(true)
	white_start.set_hidden(true)
	
	seed(OS.get_unix_time())
	turn = randi() % 2
	
	var piece = get_current_piece()
	var owner = get_piece_owner(piece)
	if owner == player:
		unfreeze(piece)

func get_current_piece():
	if is_white_turn():
		return global.PIECE_WHITE
	elif is_black_turn():
		return global.PIECE_BLACK

func get_next_piece():
	if is_white_turn():
		return global.PIECE_BLACK
	elif is_black_turn():
		return global.PIECE_WHITE

func get_next_turn():
	if is_white_turn():
		return TURN_BLACK
	elif is_black_turn():
		return TURN_WHITE

func is_ready():
	return is_black_ready() and is_white_ready()

func is_black_ready():
	return black_ready

func is_white_ready():
	return white_ready

func is_white_turn():
	return turn == TURN_WHITE

func is_black_turn():
	return turn == TURN_BLACK

func get_pieces(color):
	return get_tree().get_nodes_in_group(color)

func setup_pieces(type, y_sign, row_start, row_increment):
	var pieces = global.get_player_pieces(type)
	var row = row_start
	var col = 0
	var h = 64
	var w = 72
	var y_offset = 64 * y_sign
	var x_offset = 36
	for piece in pieces:
		var x = (col * w) + x_offset
		var y = (row * h) + y_offset
		var pos = Vector2(x, y)
		piece.set_pos(pos)
		piece.connect("piece_on_swap", self, "piece_on_swap")
		piece.connect("piece_on_clash", self, "piece_on_clash")
		piece.add_to_group(type)
		add_child(piece)
		col += 1
		if col >= 9:
			row += row_increment
			col = 0

func setup_black():
	setup_pieces(global.PIECE_BLACK, 1, 0, 1) 

func setup_white():
	setup_pieces(global.PIECE_WHITE, -1, 9, -1)

func piece_on_swap(piece1, piece2):
	if is_initial_phase():
		var pos1 = piece1.get_pos()
		var pos2 = piece2.get_pos()
		arbiter.on_swap(piece1.get_type(), pos1, pos2)
		piece1.set_pos(pos2)
		piece2.set_pos(pos1)

# piece1 is neutral. piece2 is aggressive
func piece_on_clash(piece1, piece2):
	if (is_start_phase() and 
		is_adjacent(piece2.get_pos(), piece1.get_pos())):
		
		# Flag vs Flag: The aggressive player will win.
		if piece2.get_rank() == 1 and piece1.get_rank() == 1:
			winner = piece2.get_type()
			game_on_win()
			
		# Flag vs Other: The neutral player will win.
		elif piece2.get_rank() == 1:
			winner = piece1.get_type()
			game_on_win()
			
		# Other vs Flag: The aggressive player will win.
		elif piece1.get_rank() == 1:
			winner = piece2.get_type()
			game_on_win()
			
		else:
			# If the neutral piece is eliminated, the postiion
			# of the aggressive piece will now be the neutral
			# piece's position.
			
			# Same rank: They are both out of the game.
			if piece2.get_rank() == piece1.get_rank():
				game_on_split(piece1.get_type(), piece2.get_type(), piece1.get_pos(), piece2.get_pos())
				piece2.queue_free()
				piece1.queue_free()
				
			# Spy vs Private: Spy will be eliminated.
			elif piece2.get_rank() == 15 and piece1.get_rank() == 2:
				game_on_eliminated(piece1.get_type(), piece2.get_type(), piece1.get_pos(), piece2.get_pos())
				piece2.queue_free() 
				
			# Private vs Spy: Spy will be eliminated.
			elif piece2.get_rank() == 2 and piece1.get_rank() == 15:
				game_on_eliminated(piece2.get_type(), piece1.get_type(), piece2.get_pos(), piece1.get_pos())
				piece2.set_pos(piece1.get_pos())
				piece1.queue_free()
				
			# Low rank vs High rank: Low rank will be eliminated.
			elif piece2.get_rank() < piece1.get_rank():
				game_on_eliminated(piece1.get_type(), piece2.get_type(), piece1.get_pos(), piece2.get_pos())
				piece2.queue_free()
				
			# High rank vs Low rank: Low rank will be eliminated.
			elif piece2.get_rank() > piece1.get_rank():
				game_on_eliminated(piece2.get_type(), piece1.get_type(), piece2.get_pos(), piece1.get_pos())
				piece2.set_pos(piece1.get_pos())
				piece1.queue_free()
			
			if (not has_pieces(global.PIECE_WHITE) and 
				not has_pieces(global.PIECE_BLACK)):
				game_on_draw()
			elif not has_pieces(global.PIECE_WHITE):
				winner = global.PIECE_BLACK
				game_on_win()
			elif not has_pieces(global.PIECE_BLACK):
				winner = global.PIECE_WHITE
				game_on_win()

func board_on_drop(pos, piece):
	if is_valid_pos(pos, piece):
		var new_pos = get_proper_pos(pos)
		
		if is_initial_phase():
			arbiter.on_arrange(piece.get_type(), piece.get_pos(), new_pos)
			piece.set_pos(new_pos)
			
		elif is_start_phase():
			if is_adjacent(piece.get_pos(), new_pos):
				if not has_pre_winner():
					# If Flag is placed at the 1st row relative to
					# the opponents place, the color is considered 
					# as pre-winner. If there's nothing that will
					# challenge, the color wins.
					if piece.get_rank() == 1:
						if can_have_pre_winner(new_pos):
							pre_winner = piece.get_type()
					
					game_on_move(piece.get_pos(), new_pos)
					piece.set_pos(new_pos)
					
				else:
					winner = pre_winner
					game_on_win()

func can_have_pre_winner(flag_pos):
	var board_height = board.get_size().height
	var piece_height = 64
	var y_offset = 64
	var top_endpoint = y_offset
	var bottom_endpoint = board_height - y_offset - piece_height
	if flag_pos.y == bottom_endpoint or flag_pos.y == top_endpoint:
		return true
	else:
		return false

func is_adjacent(pos1, pos2):
	var same_y = pos1.y == pos2.y
	var same_x = pos1.x == pos2.x
	var diff_y = abs(pos1.y - pos2.y) == 64
	var diff_x = abs(pos1.x - pos2.x) == 72
	
	if (same_y and diff_x) or (same_x and diff_y):
		return true
	else:
		return false

func is_valid_pos(pos, piece):
	var x_ok = is_valid_pos_x(pos.x, piece)
	var y_ok = is_valid_pos_y(pos.y, piece)
	return x_ok and y_ok

func is_valid_pos_x(x, piece):
	var x_ok = false
	var x_offset = 36
	var x_min
	var x_max
	
	if is_initial_phase():
		x_min = x_offset
		x_max = board.get_size().width - x_offset
		
	elif is_start_phase():
		var width = piece.get_size().width
		x_min = piece.get_pos().x - width
		x_max = piece.get_pos().x + width + (x_offset * 2)
	
	if x_min != null and x_max != null:
		if x > x_min and x < x_max:
			x_ok = true
	
	return x_ok

func is_valid_pos_y(y, piece):
	var y_ok = false
	var y_min
	var y_max
	
	if is_initial_phase():
		var y_range = get_valid_range_y(piece.get_type())
		if y_range != null:
			y_min = y_range.x
			y_max = y_range.y 
		
	elif is_start_phase():
		var y_offset = 64
		var height = piece.get_size().height
		y_min = piece.get_pos().y - height
		y_max = piece.get_pos().y + height + y_offset
	
	if y_min != null and y_max != null:
		if y > y_min and y < y_max:
			y_ok = true
	
	return y_ok

func is_initial_phase():
	return phase == PHASE_INITIAL

func is_start_phase():
	return phase == PHASE_START

func get_valid_range_y(color):
	var height = 64
	var y_offset = 64
	if color == global.PIECE_BLACK:
		return get_range(0, height, y_offset, 1)
	elif color == global.PIECE_WHITE:
		return get_range(8, height, y_offset, -1)

func get_range(row_start, height, y_offset, y_sign):
	var first = (row_start * height) + y_offset
	var second = first + (y_sign * height * 3)
	if first < second:
		return Vector2(first, second)
	else:
		return Vector2(second, first)

func get_proper_pos(pos):
	var width = 72
	var x_offset = 36
	var x = (int((pos.x - x_offset) / width) * width) + x_offset
	
	var height = 64
	var y_offset = 64
	var y = (int((pos.y - y_offset) / height) * height) + y_offset
	
	return Vector2(x, y)

func has_pieces(color):
	return get_pieces(color).size() > 0

func reveal(color, show):
	get_tree().call_group(0, color, "reveal", show)

func has_pre_winner():
	if (pre_winner != null and 
		(pre_winner == global.PIECE_WHITE or pre_winner == global.PIECE_BLACK)):
		return true
	else:
		return false

func has_winner():
	if (winner != null and 
		(winner == global.PIECE_WHITE or winner == global.PIECE_BLACK)):
		return true
	else:
		return false

func game_on_split(color1, color2, pos1, pos2):
	var next = get_next_piece()
	var current = get_current_piece()
	arbiter.on_clash_split(next, current, color1, color2, pos1, pos2)

func game_on_eliminated(winner, loser, winner_pos, loser_pos):
	var next = get_next_piece()
	var current = get_current_piece()
	arbiter.on_clash_eliminated(next, current, winner, loser, winner_pos, loser_pos)

func game_on_end():
	freeze(player.get_color())
	reveal(opponent.get_color(), true)

func game_on_move(old_pos, new_pos):
	var next = get_next_piece()
	var current = get_current_piece()
	on_turn_will_change()
	arbiter.on_piece_moved(next, current, old_pos, new_pos)

func game_on_win():
	var loser
	if winner == global.PIECE_BLACK:
		loser = global.PIECE_WHITE
	else:
		loser = global.PIECE_BLACK
	
	game_on_end()
	arbiter.on_win(winner, loser)

func game_on_draw():
	game_on_end()
	arbiter.on_draw()

func on_turn_will_change():
	var current = get_current_piece()
	if player.get_color() == current:
		freeze(current)

func get_piece_owner(color):
	if player.get_color() == color:
		return player
	elif opponent.get_color() == color:
		return opponent

func disable_start(color, disable=true):
	if color == global.PIECE_WHITE:
		white_start.set_ignore_mouse(disable)
	elif color == global.PIECE_BLACK:
		black_start.set_ignore_mouse(disable)

func get_lobby_path():
	return str("/lobby/", lobby_id)

func get_game_path():
	return str(get_lobby_path(), "/game/", game_id)

func get_arbiter_path():
	return str(get_game_path(), "/arbiter")

func get_chat_path():
	return str(get_game_path(), "/chat")

func get_status_path():
	return str(get_game_path(), "/status")

func firebase_on_success(firebase, request, info):
	print(info)

func firebase_on_error(firebase, object, error):
	print(error)

func firebase_on_stream(firebase, source, event, data):
	if data == "null":
		return
	
	var info = Dictionary()
	info.parse_json(data)
	
	var path = info["path"]
	if path == "/arbiter":
		var arbiter_data = info["data"]
		var event = arbiter_data["event"]
		var callback
		if event == "ready":
			callback = "arbiter_on_ready"
		elif event == "arrange":
			callback = "arbiter_on_arrange"
		elif event == "swap":
			callback = "arbiter_on_swap"
		elif event == "first_move":
			callback = "arbiter_on_first_move"
		elif event == "move":
			callback = "arbiter_on_move"
		elif event == "split":
			callback = "arbiter_on_split"
		elif event == "eliminated":
			callback = "arbiter_on_eliminated"
		elif event == "win":
			callback = "arbiter_on_win"
		elif event == "draw":
			callback = "arbiter_on_draw"
		
		if callback != null:
			call_deferred(callback, Dictionary(arbiter_data))
		
	elif path == "/chat":
		var chat_data = info["data"]
		var message = chat_data["message"]
		var sender = chat_data["sender"]
		var timestamp = chat_data["timestamp"]
		call_deferred("chat_on_receive", sender, message, timestamp)
		
	elif path == "/status":
		var status_data = info["data"]
		var status = status_data["status"]
		var timestamp = status_data["timestamp"]
		call_deferred("game_on_update", status, timestamp)

func append_chat_message(sender, message, timestamp):
	var lines = message.split("\n", false)
	if lines.size() == 0:
		lines.push_back(message)
	
	for line in lines:
		var text = str("[", sender, "]:", line)
		messages.add_item(text, null, false)

func arbiter_on_ready(data):
	append_chat_message("arbiter", data["message"], data["timestamp"])
	var info = data["info"]
	var color = info["color"]
	if color == global.PIECE_WHITE:
		set_white_ready(true)
	if color == global.PIECE_BLACK:
		set_black_ready(true)
	if is_ready():
		on_ready()
		if player.is_game_creator():
			arbiter.on_first_move(get_current_piece())

func arbiter_on_swap(data):
	var info = data["info"]
	var color = info["color"]
	if opponent.get_color() == color:
		var pos1 = Vector2(info["pos1"]["x"], info["pos1"]["y"])
		var pos2 = Vector2(info["pos2"]["x"], info["pos2"]["y"])
		swap(color, pos1, pos2)

func arbiter_on_arrange(data):
	var info = data["info"]
	var color = info["color"]
	if opponent.get_color() == color:
		var old_pos = Vector2(info["old_pos"]["x"], info["old_pos"]["y"])
		var new_pos = Vector2(info["new_pos"]["x"], info["new_pos"]["y"])
		arrange(color, old_pos, new_pos)

func arbiter_on_first_move(data):
	append_chat_message("arbiter", data["message"], data["timestamp"])
	var next = data["info"]["color"]
	setup_next_turn(next)

func arbiter_on_move(data):
	append_chat_message("arbiter", data["message"], data["timestamp"])
	var next = data["next"]
	var current = data["current"]
	if opponent.get_color() == current:
		var info = data["info"]
		var old_pos = Vector2(info["old_pos"]["x"], info["old_pos"]["y"])
		var new_pos = Vector2(info["new_pos"]["x"], info["new_pos"]["y"])
		arrange(current, old_pos, new_pos)
	setup_next_turn(next)

func arbiter_on_split(data):
	append_chat_message("arbiter", data["message"], data["timestamp"])
	var next = data["next"]
	var current = data["current"]
	if opponent.get_color() == current:
		var info = data["info"]
		var color1 = info["color1"]
		var color2 = info["color2"]
		var pos1 = Vector2(info["pos1"]["x"], info["pos1"]["y"])
		var pos2 = Vector2(info["pos2"]["x"], info["pos2"]["y"])
		clash_split(color1, pos1)
		clash_split(color2, pos2)
	setup_next_turn(next)

func arbiter_on_eliminated(data):
	append_chat_message("arbiter", data["message"], data["timestamp"])
	var next = data["next"]
	var current = data["current"]
	if opponent.get_color() == current:
		var info = data["info"]
		var win = info["win"]
		var lose = info["lose"]
		var win_pos = Vector2(info["win_pos"]["x"], info["win_pos"]["y"])
		var lose_pos = Vector2(info["lose_pos"]["x"], info["lose_pos"]["y"])
		clash_eliminate(current, win, lose, win_pos, lose_pos)
	setup_next_turn(next)

func arbiter_on_win(data):
	append_chat_message("arbiter", data["message"], data["timestamp"])
	if opponent.get_color() == get_current_piece():
		game_on_end()

func arbiter_on_draw(data):
	append_chat_message("arbiter", data["message"], data["timestamp"])
	if opponent.get_color() == get_current_piece():
		game_on_end()

func setup_next_turn(color):
	if color == global.PIECE_WHITE:
		turn = TURN_WHITE
	elif color == global.PIECE_BLACK:
		turn = TURN_BLACK
	
	var piece = get_current_piece()
	var owner = get_piece_owner(piece)
	if owner == opponent:
		freeze(player.get_color())
	else:
		unfreeze(player.get_color())

func swap(color, pos1, pos2):
	var pieces = get_pieces(color)
	var piece1
	var piece2
	
	for piece in pieces:
		if piece.get_pos() == pos1 or piece.get_pos() == pos2:
			if piece1 == null:
				piece1 = piece
			else:
				piece2 = piece
				break
	
	if piece1 != null and piece2 != null:
		var pos = piece1.get_pos()
		piece1.set_pos(piece2.get_pos())
		piece2.set_pos(pos)

func arrange(color, old_pos, new_pos):
	var pieces = get_pieces(color)
	for piece in pieces:
		if piece.get_pos() == old_pos:
			piece.set_pos(new_pos)
			if is_start_phase() and piece.get_rank() == 1:
				if can_have_pre_winner(new_pos):
					pre_winner = color
			break

func clash_split(color, pos):
	var pieces = get_pieces(color)
	for piece in pieces:
		if piece.get_pos() == pos:
			piece.queue_free()
			break

func clash_eliminate(current, win, lose, win_pos, lose_pos):
	if current == win:
		for piece in get_pieces(win):
			if piece.get_pos() == win_pos:
				piece.set_pos(lose_pos)
				break
	
	for piece in get_pieces(lose):
		if piece.get_pos() == lose_pos:
			piece.queue_free()
			break

func on_send():
	if is_chat_valid():
		var chat_message = get_chat_message()
		if is_valid_command(chat_message) and player.is_game_creator():
			var cmd = chat_message.to_lower()
			if cmd == ":new game:":
				game_on_reload()
			elif cmd == ":quit:":
				game_on_quit()
			
		else:
			send_chat_message(player.get_name(), chat_message)
		
		message.clear()

func send_game_status(status):
	var timestamp = OS.get_unix_time()
	var data = {
		"status": status,
		"timestamp": timestamp
	}
	var path = get_status_path()
	firebase.put(path, data.to_json())

func game_on_reload():
	send_game_status("new game")

func game_on_quit():
	send_game_status("quit")

func game_on_update(status, timestamp):
	if status == "new game":
		get_tree().reload_current_scene()
	elif status == "quit":
		global.goto_lobby()

func send_chat_message(sender, msg):
	var timestamp = OS.get_unix_time()
	var data = {
		"sender": sender,
		"message": msg,
		"timestamp": timestamp
	}
#	var path = get_chat_path()
#	firebase.put(path, data.to_json())
	append_chat_message("kangaroo", msg, timestamp)

func chat_on_receive(sender, message, timestamp):
	append_chat_message(sender, message, timestamp)

func get_chat_message():
	return message.get_text().strip_edges()

func is_chat_valid():
	return not get_chat_message().empty()

func is_valid_command(command):
	var len = command.length()
	if len > 2:
		if command[0] == ":" and command[len - 1] == ":":
			var cmd = command.to_lower()
			if CHAT_COMMANDS.find(cmd) > -1:
				return true
	return false

