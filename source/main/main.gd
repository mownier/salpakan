
extends Node2D

onready var global = get_node("/root/global")
onready var lobby_id = get_node("container/lobby_id")
onready var join = get_node("container/join")
onready var create = get_node("container/create")
onready var disconnect = get_node("container/disconnect")
onready var error_dialog = get_node("error_dialog")

var firebase
var disconnect_request
var join_request
var create_request

func _ready():
	firebase = global.create_firebase()
	firebase.connect("firebase_on_success", self, "firebase_on_success")
	firebase.connect("firebase_on_error", self, "firebase_on_error")
	
	join.connect("pressed", self, "on_join")
	create.connect("pressed", self, "on_create")
	disconnect.connect("pressed", self, "on_disconnect")

func on_join():
	pass

func on_create():
	pass

func on_disconnect():
	var connection_id = global.get_connection_id()
	var path = str("/connections/", connection_id)
	disconnect_request = firebase.delete(path)

func firebase_on_success(firebase, request, info):
	if request == disconnect_request:
		call_deferred("on_disconnect_success")
	elif request == create_request:
		call_deferred("on_create_success", info["name"])
	elif request == join_request:
		call_deferred("on_join_success")
	else:
		print("Unhandled request...")

func firebase_on_error(firebase, request, error):
	call_deferred("show_error", error)

func show_error(error):
	error_dialog.set_text(error)
	error_dialog.popup_centered()

func on_disconnect_success():
	global.break_connection()
	global.goto_login()

func on_create_success(id):
	goto_lobby(id)

func on_join_success():
	var id = lobby_id.get_text()
	goto_lobby(id)

func goto_lobby(id):
	global.set_lobby_id(id)
	global.goto_lobby()
