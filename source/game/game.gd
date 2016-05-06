
extends Node2D

const PHASE_INITIAL = 0
const PHASE_START = 1
const TURN_WHITE = 0
const TURN_BLACK = 1

onready var global = get_node("/root/global")
onready var board = get_node("board")
onready var black_start = get_node("black_start")
onready var white_start = get_node("white_start")
onready var messages = get_node("messages")

var player
var opponent

var eliminated
var pre_winner
var winner
var turn

var phase = PHASE_INITIAL
var black_ready = false
var white_ready = false

func _ready():
	player = global.get_player()
	opponent = global.get_opponent()

	seed(OS.get_unix_time())
	turn = randi() % 2
	board.connect("board_on_drop", self, "board_on_drop")
	
	setup_start_buttons()
	setup_black()
	setup_white()
	
	reveal(opponent.get_color(), false)
	freeze(opponent.get_color())

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
	black_ready = true
	black_start.set_text("READY")
	black_start.set_ignore_mouse(true)
	freeze(global.PIECE_BLACK)
	check_ready()

func on_white_ready():
	white_ready = true
	white_start.set_text("READY")
	white_start.set_ignore_mouse(true)
	freeze(global.PIECE_WHITE)
	check_ready()

func check_ready():
	if is_ready():
		on_ready()

func freeze(color):
	get_tree().call_group(0, color, "enable_drag", false)

func unfreeze(color):
	get_tree().call_group(0, color, "enable_drag", true)

func on_ready():
	phase = PHASE_START
	black_start.set_hidden(true)
	white_start.set_hidden(true)
	
	var piece = get_current_piece()
	if piece == player.get_color():
		unfreeze(piece)
	
	send_arbiter_message("turn")

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
		piece1.set_pos(pos2)
		piece2.set_pos(pos1)

# piece1 is neutral. piece2 is aggressive
func piece_on_clash(piece1, piece2):
	if (is_start_phase() and 
		is_adjacent(piece2.get_pos(), piece1.get_pos())):
		
		# Flag vs Flag: The aggressive player will win.
		if piece2.get_rank() == 1 and piece1.get_rank() == 1:
			winner = piece2.get_type()
			on_winner_determined()
			
		# Flag vs Other: The neutral player will win.
		elif piece2.get_rank() == 1:
			winner = piece1.get_type()
			on_winner_determined()
			
		# Other vs Flag: The aggressive player will win.
		elif piece1.get_rank() == 1:
			winner = piece2.get_type()
			on_winner_determined()
			
		else:
			# If the neutral piece is eliminated, the postiion
			# of the aggressive piece will now be the neutral
			# piece's position.
			
			# Same rank: They are both out of the game.
			if piece2.get_rank() == piece1.get_rank():
				piece2.queue_free()
				piece1.queue_free()
				on_clash_split()
				
			# Spy vs Private: Spy will be eliminated.
			elif piece2.get_rank() == 15 and piece1.get_rank() == 2:
				eliminated = piece2.get_type()
				piece2.queue_free() 
				on_clash_eliminated()
				
			# Private vs Spy: Spy will be eliminated.
			elif piece2.get_rank() == 2 and piece1.get_rank() == 15:
				piece2.set_pos(piece1.get_pos())
				eliminated = piece1.get_type()
				piece1.queue_free()
				on_clash_eliminated()
				
			# Low rank vs High rank: Low rank will be eliminated.
			elif piece2.get_rank() < piece1.get_rank():
				eliminated = piece2.get_type()
				piece2.queue_free()
				on_clash_eliminated()
				
			# High rank vs Low rank: Low rank will be eliminated.
			elif piece2.get_rank() > piece1.get_rank():
				piece2.set_pos(piece1.get_pos())
				eliminated = piece1.get_type()
				piece1.queue_free()
				on_clash_eliminated()
			
			if (not has_pieces(global.PIECE_WHITE) and 
				not has_pieces(global.PIECE_BLACK)):
				on_game_draw()
			elif not has_pieces(global.PIECE_WHITE):
				winner = global.PIECE_BLACK
				on_winner_determined()
			elif not has_pieces(global.PIECE_BLACK):
				winner = global.PIECE_WHITE
				on_winner_determined()
			else:
				configure_next_turn()

func board_on_drop(pos, piece):
	if is_valid_pos(pos, piece):
		var new_pos = get_proper_pos(pos)
		if (is_initial_phase() or 
			(is_start_phase() and is_adjacent(piece.get_pos(), new_pos))):
			piece.set_pos(new_pos)
			
			if is_start_phase():
				
				if not has_pre_winner():
					# If Flag is placed at the 1st row relative to
					# the opponents place, the color is considered 
					# as pre-winner. If there's nothing that will
					# challeng, the color wins.
					if piece.get_rank() == 1:
						if (new_pos.y == board.get_size().height - 64 - piece.get_size().height or
							new_pos.y == 64):
							pre_winner = piece.get_type()
					
					configure_next_turn()
					
				else:
					winner = pre_winner
					on_winner_determined()

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
	return get_tree().get_nodes_in_group(color).size() > 0

func reveal(color, show):
	get_tree().call_group(0, color, "reveal", show)

func configure_next_turn():
	var next = get_next_piece()
	var current = get_current_piece()
	freeze(current)
	if next == player.get_color():
		unfreeze(next)
	turn = get_next_turn()
	
	on_turn_changed()

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

func send_arbiter_message(event):
	var message = ""
	
	if event == "turn":
		var current = get_current_piece().to_upper()
		message = str(current, "'s turn")
		
	elif event == "win":
		if has_winner():
			var piece = winner.to_upper()
			message = str(piece, " wins")
		
	elif event == "split":
		message = "Clash is split"
		
	elif event == "draw":
		message = "Game is draw"
		
	elif event == "eliminated":
		var piece = eliminated.to_upper()
		message = str(piece, " is eliminated")
		
	if not message.empty():
		var sender = "arbiter"
		var timestamp = OS.get_unix_time()
		send_message(sender, timestamp, message)

func send_message(sender, timestamp, message):
	var text = str("[", sender, "]: ", message)
	messages.add_item(text, null, false)

func on_winner_determined():
	freeze(player.get_color())
	reveal(opponent.get_color(), true)
	send_arbiter_message("win")

func on_clash_split():
	send_arbiter_message("split")

func on_clash_eliminated():
	send_arbiter_message("eliminated")

func on_game_draw():
	freeze(player.get_color())
	reveal(opponent.get_color(), true)
	send_arbiter_message("draw")

func on_turn_changed():
	send_arbiter_message("turn")
