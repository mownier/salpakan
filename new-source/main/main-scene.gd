extends Node2D

func _ready():
	pass

func _on_online_button_pressed():
	var tree = get_tree()
	package.lobby.show_lobby_scene_from(tree)

func _on_lan_button_pressed():
	var tree = get_tree()
	package.LAN.show_LAN_scene_from(tree)
