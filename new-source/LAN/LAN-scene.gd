extends Node2D

onready var host_line_edit = get_node("host_line_edit")
onready var port_line_edit = get_node("port_line_edit")
onready var you_label = get_node("you_label")
onready var enemy_label = get_node("enemy_label")
onready var start_button = get_node("start_button")

func _ready():
	network_controller.connect("network_controller_on_enemy_connected_with", self, "on_enemy_connected_with")
	network_controller.connect("network_controller_on_assigned_piece_color", self, "on_assigned_piece_color")
	network_controller.connect("network_controller_on_game_started", self, "on_game_started")

func _on_start_button_pressed():
	network_controller.notify_to_start_the_game()

func _on_connect_button_pressed():
	var host = host_line_edit.text
	var port = int(port_line_edit.text)
	network_controller.connect_to_LAN_server_with(host, port)

func on_enemy_connected_with(color):
	enemy_label.text = str("Enemy: ", color)
	package.game.enemy_color = color
	start_button.set_disabled(false)

func on_assigned_piece_color(color):
	you_label.text = str("You: ", color)
	package.game.you_color = color

func on_game_started():
	coordinator.show_game_scene()
