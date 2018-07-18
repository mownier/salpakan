extends Node2D

func _on_start_button_pressed():
	var tree = get_tree()
	package.game.show_game_scene_from(tree)
