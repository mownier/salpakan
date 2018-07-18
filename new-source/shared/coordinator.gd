extends Node

enum SCENE {
	main,
	LAN,
	lobby,
	game
}

var scene_navigation_history = []

func show_previous_scene():
	var scene = scene_navigation_history.pop_front()
	show_with(scene)

func show_first_scene():
	var scene = scene_navigation_history.pop_front()
	scene_navigation_history.resize(1)
	scene_navigation_history.push_front(scene)
	show_with(scene)

func show_main_scene():
	scene_navigation_history.push_front(SCENE.main)
	package.main.show_main_scene_from(get_tree())

func show_LAN_scene():
	scene_navigation_history.push_front(SCENE.LAN)
	package.LAN.show_LAN_scene_from(get_tree())

func show_lobby_scene():
	scene_navigation_history.push_front(SCENE.lobby)
	package.lobby.show_lobby_scene_from(get_tree())

func show_game_scene():
	scene_navigation_history.push_front(SCENE.game)
	package.game.show_game_scene_from(get_tree())

func show_with(scene):
	match scene:
		SCENE.main : show_main_scene()
		SCENE.LAN  : show_LAN_scene()
		SCENE.lobby: show_lobby_scene()
		SCENE.game : show_game_scene()
	
