
extends Node2D

onready var global = get_node("/root/global")
onready var start = get_node("start")

func _ready():
	start.connect("pressed", self, "on_start")

func on_start():
	global.goto_game()
