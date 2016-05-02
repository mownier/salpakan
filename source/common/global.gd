
extends Node

var Firebase = preload("res://lib/ifmoan/firebase/firebase.gd")
var Pool = preload("res://lib/ifmoan/thread-pool/thread_pool.gd")
var pool = Pool.new(12)
var storage = Storage.new("user://data.db", "XDvJ3YiQ9ouVoPiSIchR")
var connection
var lobby_id
var Piece = preload("res://source/game/piece.scn")

func _ready():
	connection = get_connection()
	pool.start()

func create_firebase(url=""):
	var app_url = url
	if app_url.empty():
		app_url = get_connection_url()
	var firebase = Firebase.new(app_url)
	firebase.set_pool(pool)
	return firebase

func has_connection():
	if (not get_connection_id().empty() and
		not get_connected_player().empty() and
		not get_connection_url().empty()):
		return true
	else:
		return false

func get_connection_url():
	return get_connection_info("url")

func get_connected_player():
	return get_connection_info("name")

func get_connection_id():
	return get_connection_info("id")

func save_connection(firebase_url, player_name, connection_id):
	var data = {"url": firebase_url, "name": player_name, "id": connection_id}
	connection = data
	storage.write(data.to_json(), false)

func get_connection_info(key):
	if (connection != null and 
		not connection.empty() and 
		connection.has(key)):
		return connection[key]
	else:
		return ""

func get_connection():
	var json = storage.read()
	if json.empty():
		return Dictionary()
	else:
		var info = Dictionary()
		info.parse_json(json)
		return info

func break_connection():
	connection.clear()
	storage.write("", false)

func set_lobby_id(id):
	lobby_id = id

func goto_main():
	get_tree().change_scene("res://source/main/main.scn")

func goto_login():
	get_tree().change_scene("res://source/login/login.scn")

func goto_lobby():
	get_tree().change_scene("res://source/lobby/lobby.scn")

func goto_game():
	get_tree().change_scene("res://source/game/game.scn")

func get_opponent_pieces(color):
	return get_pieces(color)

func get_player_pieces(color):
	return get_pieces(color)

func get_pieces(color):
	var pieces = []
	var keys = []
	if color == "white":
		keys = [
			"W_G_5", "W_G_4",   "W_G_3", "W_G_2", "W_G_1",\
			"W_COL", "W_L_COL", "W_MAJ", "W_SGT", "W_PVT",\
			"W_CAP", "W_L_1",   "W_L_2", "W_FLG", "W_SPY"]
	elif color == "black":
		keys = [
			"B_G_5", "B_G_4",   "B_G_3", "B_G_2", "B_G_1",\
			"B_COL", "B_L_COL", "B_MAJ", "B_SGT", "B_PVT",\
			"B_CAP", "B_L_1",   "B_L_2", "B_FLG", "B_SPY"]
	
	for key in keys:
		var count = 1
		if key.ends_with("_PVT"):
			count = 6
		elif key.ends_with("_SPY"):
			count = 2
		
		for i in range(count):
			var piece = Piece.instance()
			piece.type = key
			pieces.push_back(piece)
	
	return pieces


class Storage extends Reference:
	
	var path
	var key
	var writer = File.new()
	var reader = File.new()
	
	func _init(path, key=""):
		self.path = path
		self.key = key
	
	func write(data, append=true):
		var content = ""
		if append:
			content += read()
		writer.open(path, File.WRITE)
		content += str(data)
		writer.store_string(content)
		writer.close()
	
	func read():
		var data = ""
		if reader.file_exists(path):
			reader.open(path, File.READ)
			data = reader.get_as_text()
		if reader.is_open():
			reader.close()
		return data
