
extends Node2D

const PHASE_INITIAL = 0
const PHASE_START = 1
const TURN_WHITE = 0
const TURN_BLACK = 1

onready var global = get_node("/root/global")
onready var board = get_node("board")
onready var black_start = get_node("black_start")
onready var white_start = get_node("white_start")
onready var info = get_node("info")

var turn
var phase = PHASE_INITIAL
var black_ready = false
var white_ready = false

func _ready():
	turn = OS.get_unix_time() % 2
	board.connect("board_on_drop", self, "board_on_drop")
	
	setup_start_buttons()
	setup_info_label()
	setup_black()
	setup_white()

func setup_info_label():
	var board_width = board.get_size().width
	var y_offset = 64
	info.set_pos(Vector2(0, 0))
	info.set_size(Vector2(board_width, y_offset))
	info.set_hidden(true)

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
	check_ready(global.PIECE_BLACK, global.PIECE_WHITE)

func on_white_ready():
	white_ready = true
	white_start.set_text("READY")
	white_start.set_ignore_mouse(true)
	check_ready(global.PIECE_WHITE, global.PIECE_BLACK)

func check_ready(piece, other):
	if is_ready():
		get_tree().call_group(0, other, "set_ignore_mouse", false)
		on_ready()
	else:
		get_tree().call_group(0, piece, "set_ignore_mouse", true)

func on_ready():
	phase = PHASE_START
	black_start.set_hidden(true)
	white_start.set_hidden(true)
	var message = ""
	
	if is_white_turn():
		message = "White on first move"
	elif is_black_turn():
		message = "Black on first move"
	
	if not message.empty():
		set_info(message)

func set_info(message):
	info.set_text(message)
	info.set_hidden(false)

func is_ready():
	return is_black_ready() and is_white_ready()

func is_black_ready():
	return black_ready

func is_white_ready():
	return white_ready

func is_white_turn():
	turn == TURN_WHITE

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

# piece1 is prey. piece2 is predator
func piece_on_clash(piece1, piece2):
	if is_start_phase():
		print("clashing...")

func board_on_drop(pos, piece):
	if is_valid_pos(pos, piece):
		var new_pos = get_proper_pos(pos)
		if (is_initial_phase() or 
			(is_start_phase() and is_adjacent(piece.get_pos(), new_pos))):
			piece.set_pos(new_pos)

func is_adjacent(pos1, pos2):
	return pos1.x == pos2.x or pos1.y == pos2.y

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
