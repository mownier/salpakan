
extends Node2D

onready var global = get_node("/root/global")

func _ready():
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
		add_child(piece)
		col += 1
		if col >= 9:
			row += row_increment
			col = 0

func setup_black():
	setup_pieces("black", 1, 0, 1) 


func setup_white():
	setup_pieces("white", -1, 9, -1)