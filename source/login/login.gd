
extends Node2D

onready var global = get_node("/root/global")
onready var connect = get_node("container/connect")
onready var player_name = get_node("container/player_name")
onready var firebase_url = get_node("container/firebase_url")
onready var error_dialog = get_node("error_dialog")

var firebase

func _ready():
	if global.has_connection():
		global.goto_main()
	else:
		connect.connect("pressed", self, "on_connect")

func on_connect():
	if is_input_valid():
		var id = str("connection_", OS.get_unix_time())
		var url = get_firebase_url()
		var name = get_player_name()
		var data = {"player_name": name, "id": id}
		var path = str("/connection/", id)
		
		firebase = global.create_firebase(url)
		firebase.connect("firebase_on_success", self, "firebase_on_success")
		firebase.connect("firebase_on_error", self, "firebase_on_error")
		firebase.patch(path, data.to_json())
		
	else:
		show_error("Fill the fields appropriately.")

func get_firebase_url():
	return firebase_url.get_text()

func get_player_name():
	return player_name.get_text()

func show_error(error):
	error_dialog.set_text(error)
	error_dialog.popup_centered()

func is_input_valid():
	var url = get_firebase_url()
	var name = get_player_name()
	return not url.empty() and not name.empty()

func handle_success(id):
	var url = get_firebase_url()
	var name = get_player_name()
	global.save_connection(url, name, id)
	global.goto_main()

func firebase_on_success(firebase, request, info):
	var id = info["id"]
	call_deferred("handle_success", id)

func firebase_on_error(firebase, request, error):
	call_deferred("show_error", error)
