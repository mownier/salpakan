
extends Reference

var connection_id
var name
var color
var game_creator = false

func set_connection_id(id):
	connection_id = id

func get_connection_id():
	return connection_id

func set_name(player_name):
	name = player_name

func get_name():
	return name

func set_color(piece_color):
	color = piece_color

func get_color():
	return color

func set_game_creator(creator):
	game_creator = creator

func is_game_creator():
	return game_creator
