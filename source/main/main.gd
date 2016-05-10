
extends Node2D

onready var global = get_node("/root/global")
onready var join = get_node("join")
onready var create = get_node("create")
onready var disconnect = get_node("disconnect")
onready var refresh = get_node("refresh")
onready var error_dialog = get_node("error_dialog")
onready var lobby_detail = get_node("lobby_detail")
onready var lobby_list = get_node("lobby_list")

var firebase
var disconnect_request
var join_request
var create_request
var refresh_request
var selected_lobby

func _ready():
	firebase = global.create_firebase()
	firebase.connect("firebase_on_success", self, "firebase_on_success")
	firebase.connect("firebase_on_error", self, "firebase_on_error")
	
	join.connect("pressed", self, "on_join")
	create.connect("pressed", self, "on_create")
	disconnect.connect("pressed", self, "on_disconnect")
	refresh.connect("pressed", self, "on_refresh")
	lobby_list.connect("item_selected", self, "on_lobby_selected")
	
	join.set_disabled(true)
	
	on_refresh()

func on_join():
	var lobby = selected_lobby["id"]
	var id = global.get_connection_id()
	var player = global.get_connected_player()
	var data = {id: {"id": id, "player": player}}
	if selected_lobby["connected"].has(id):
		data[id]["creator"] = true
	var path = str("/lobby/", lobby, "/connected")
	join_request = firebase.patch(path, data.to_json())

func on_create():
	var lobby_id = str("lobby_", OS.get_unix_time())
	var id = global.get_connection_id()
	var player = global.get_connected_player()
	var data = {"id": lobby_id, "connected": {id: {"id": id, "player": player, "creator": true}}}
	var path = str("/lobby/", lobby_id)
	create_request = firebase.patch(path, data.to_json())

func on_disconnect():
	var connection_id = global.get_connection_id()
	var path = str("/connection/", connection_id)
	disconnect_request = firebase.delete(path)

func on_refresh():
	refresh_request = firebase.get("/lobby")

func on_lobby_selected(index):
	if join.is_disabled():
		join.set_disabled(false)
	
	selected_lobby = lobby_list.get_item_metadata(index)
	lobby_detail.set_text("")
	var text = "connected:\n"
	var connected = selected_lobby["connected"]
	for id in connected:
		text += "> " + connected[id]["player"] + "\n"
	lobby_detail.set_text(text)

func firebase_on_success(firebase, request, info):
	if request == disconnect_request:
		call_deferred("on_disconnect_success")
	elif request == create_request:
		call_deferred("on_create_success", info["id"])
	elif request == join_request:
		call_deferred("on_join_success")
	elif request == refresh_request:
		call_deferred("on_refresh_success", Dictionary(info))
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
	var id = selected_lobby["id"]
	goto_lobby(id)

func on_refresh_success(lobbies):
	lobby_list.clear()
	for lobby in lobbies:
		lobby_list.add_item(lobby)
		var index = lobby_list.get_item_count() - 1
		var metadata = Dictionary(lobbies[lobby])
		metadata["id"] = lobby
		lobby_list.set_item_metadata(index, metadata)

func goto_lobby(id):
	global.set_lobby_id(id)
	global.goto_lobby()

func is_valid_input():
	return false

func get_lobby_id():
	return ""
