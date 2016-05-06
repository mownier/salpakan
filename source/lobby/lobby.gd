
extends Node2D

onready var global = get_node("/root/global")
onready var start = get_node("start")
onready var piece_selector = get_node("piece_selector")
onready var messages = get_node("messages")

var lobby_id
var firebase

func _ready():	
	lobby_id = global.get_lobby_id()
	firebase = global.create_firebase()
	
	start.connect("pressed", self, "on_start")
	firebase.connect("firebase_on_success", self, "firebase_on_success")
	firebase.connect("firebase_on_error", self, "firebase_on_error")
	firebase.connect("firebase_on_stream", self, "firebase_on_stream")
	
	var path = str("/lobby/", lobby_id)
	firebase.listen(path)

func firebase_on_success(firebase, request, info):
	pass

func firebase_on_error(firebase, object, error):
	print("error:", error)

func firebase_on_stream(firebase, source, event, data):
	if data == "null":
		return
	
	var info = Dictionary()
	info.parse_json(data)
	var path = info["path"]
	if path == "/":
		var connected = info["data"]["connected"]
		call_deferred("on_player_connected", connected)
	elif path == "/connected":
		call_deferred("on_player_connected", info["data"])

func on_player_connected(connected):
	for id in connected:
		var connection = connected[id]
		var player = connection["player"]
		var text = str(player, " is connected...")
		messages.add_item(text)

func on_start():
	var connection = global.get_connection()
	var player_color = piece_selector.get_text()
	var opponent_color
	if player_color == global.PIECE_WHITE:
		opponent_color = global.PIECE_BLACK
	else:
		opponent_color = global.PIECE_WHITE
	global.set_player_info(connection["id"], connection["name"], player_color)
	global.set_opponent_info("213jdiwurIkXMM123", "opponent", opponent_color)
	global.goto_game()
