
extends Node

var Firebase = preload("res://lib/ifmoan/firebase/firebase.gd")
var Pool = preload("res://lib/ifmoan/thread-pool/thread_pool.gd")
var pool = Pool.new(12)
var storage = Storage.new("user://data.db", "XDvJ3YiQ9ouVoPiSIchR")
var connection
var lobby_id

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
