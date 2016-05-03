
extends Node2D

onready var global = get_node("/root/global")
onready var board = get_node("board")

func _ready():
	board.connect("board_on_drop", self, "board_on_drop")
	setup_black()
	setup_white()

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
	var pos1 = piece1.get_pos()
	var pos2 = piece2.get_pos()
	piece1.set_pos(pos2)
	piece2.set_pos(pos1)

func piece_on_clash(piece1, piece2):
	pass

func board_on_drop(pos, piece):
	if is_valid_pos(pos):
		var new_pos = get_proper_pos(pos)
		piece.set_pos(new_pos)

func is_valid_pos(pos):
	var x_ok = false
	var x_offset = 36
	if pos.x > x_offset and pos.x < board.get_size().width - x_offset:
		x_ok = true
	
	var y_ok = false
	var y_offset = 64
	if pos.y > y_offset and pos.y < board.get_size().height - y_offset:
		y_ok = true
	
	return x_ok and y_ok

func get_proper_pos(pos):
	var width = 72
	var x_offset = 36
	var x = (int((pos.x - x_offset) / width) * width) + x_offset
	
	var height = 64
	var y_offset = 64
	var y = (int((pos.y - y_offset) / height) * height) + y_offset
	
	return Vector2(x, y)
