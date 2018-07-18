extends Node

enum PIECE_COLOR {
	white,
	black
}

var you_color
var enemy_color

func show_game_scene_from(tree):
	tree.change_scene("res://new-source/game/game-scene.tscn")

func is_your_turn_with(current_color):
	return you_color == current_color

func is_enemys_turn_with(current_color):
	return enemy_color == current_color
