tool

extends Node2D

onready var global = get_node("/root/global")
onready var start = get_node("start")
onready var send = get_node("send")
onready var back = get_node("back")
onready var piece_selector = get_node("piece_selector")
onready var opponent_selector = get_node("opponent_selector")
onready var messages = get_node("messages")
onready var message = get_node("message")
onready var lobby_id = global.get_lobby_id()
onready var firebase = global.create_firebase()

var game_creator_id

func _ready():
	start.connect("pressed", self, "on_start")
	send.connect("pressed", self, "on_send")
	back.connect("pressed", self, "on_back")
	firebase.connect("firebase_on_success", self, "firebase_on_success")
	firebase.connect("firebase_on_error", self, "firebase_on_error")
	firebase.connect("firebase_on_stream", self, "firebase_on_stream")
	var path = get_lobby_path()
	firebase.listen(path)

func get_lobby_path():
	return str("/lobby/", lobby_id)

func get_message_path():
	return str(get_lobby_path(), "/message")

func get_game_path(id):
	return str(get_lobby_path(), "/game/", id)

func can_send():
	return not message.get_text().empty()

func can_start():
	if opponent_selector.get_selected() > -1:
		var opponent = opponent_selector.get_selected_metadata()
		var oppon_id = opponent["id"]
		var player_id = global.get_connection_id()
		if oppon_id != player_id:
			return true
	return false

func get_message_content():
	return message.get_text()

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
		call_deferred("on_player_connected", connected, true)
	elif path == "/connected":
		call_deferred("on_player_connected", info["data"], false)
	elif path == "/message":
		call_deferred("on_receive_message", info["data"])
	elif path.begins_with("/game"):
		call_deferred("on_game_start", info["data"])

func on_receive_message(message):
	for key in message:
		var info = message[key]
		var content = info["content"]
		var player = info["player"]
		var text = str("[", player, "]:", content)
		messages.add_item(text, null, false)

func on_player_connected(connected, initial):
	for key in connected:
		var connection = connected[key]
		var player = connection["player"]
		var text = str(player, " is connected...")
		messages.add_item(text, null, false)
		
		var id = connection["id"]
		if id != global.get_connection_id():
			opponent_selector.add_item(player, OS.get_unix_time())
			var idx = opponent_selector.get_item_count() - 1
			var metadata = Dictionary(connection)
			opponent_selector.set_item_metadata(idx, metadata)
			
		else:
			if initial:
				if connection.has("creator") and connection["creator"]:
					game_creator_id = id
				else:
					start.set_hidden(true)
					piece_selector.set_hidden(true)
					opponent_selector.set_hidden(true)

func on_back():
	global.goto_main()

func on_send():
	if can_send():
		var path = get_message_path()
		var content = get_message_content()
		var conn_id = global.get_connection_id()
		var player = global.get_connected_player()
		var timestamp = OS.get_unix_time()
#		var data = {conn_id: {"id": conn_id, "player": player, "timestamp": timestamp, "content": content}}
#		firebase.patch(path, data.to_json())
#		message.clear()
		
		var id = "conn_12345"
		var sender = "kangaroo"
		var data = {
			"key": {
				"id": id,
				"content": content,
				"player": sender,
				"timestamp": timestamp
			}
		}
		message.clear()
		on_receive_message(data)
		

func on_start():
	if can_start():
		var player_color = piece_selector.get_text()
		var opponent_color
		if player_color == global.PIECE_WHITE:
			opponent_color = global.PIECE_BLACK
		else:
			opponent_color = global.PIECE_WHITE
		
		var player_id = global.get_connection_id()
		var player_name = global.get_connected_player()
		var opponent = opponent_selector.get_selected_metadata()
		var opponent_id = opponent["id"]
		var opponent_name = opponent["player"]
		
		var game_id = str("game_", OS.get_unix_time())
		var data = {
			"id": game_id,
			"players": {
				player_id: {"id": player_id, "player": player_name, "color": player_color},
				opponent_id: {"id": opponent_id, "player": opponent_name, "color": opponent_color}
			}
		}
		var path = get_game_path(game_id)
		firebase.patch(path, data.to_json())

func on_game_start(game_info):
	var game_id = game_info["id"]
	var players = game_info["players"]
	var conn_id = global.get_connection_id()
	if players.has(conn_id):
		if players.size() == 2:
			for key in players:
				var info = players[key]
				if info["id"] == conn_id:
					global.set_player_info(info["id"], info["player"], info["color"])
				else:
					global.set_opponent_info(info["id"], info["player"], info["color"])
				
				if global.get_player().get_connection_id() == game_creator_id:
					global.get_player().set_game_creator(true)
				elif global.get_opponent().get_connection_id() == game_creator_id:
					global.get_opponent().set_game_creator(true)
				
			global.set_game_id(game_id)
			global.goto_game()
