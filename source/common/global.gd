
extends Node

const PIECE_WHITE = "white"
const PIECE_BLACK = "black"
const PIECE_ATTRIB = {
	SPY = { rank = 15, white = Vector2(288, 128), black = Vector2(288, 320) },
	G_5 = { rank = 14, white = Vector2(0, 0), black = Vector2(0, 192) },
	G_4 = { rank = 13, white = Vector2(72, 0), black = Vector2(72, 192) },
	G_3 = { rank = 12, white = Vector2(144, 0), black = Vector2(144, 192) },
	G_2 = { rank = 11, white = Vector2(216, 0), black = Vector2(216, 192) },
	G_1 = { rank = 10, white = Vector2(288, 0), black = Vector2(288, 192) },
	COL = { rank = 9, white = Vector2(0, 64), black = Vector2(0, 256) },
	L_COL = { rank = 8, white = Vector2(72, 64), black = Vector2(72, 256) },
	MAJ = { rank = 7, white = Vector2(144, 64), black = Vector2(144, 256) },
	CAP = { rank = 6, white = Vector2(0, 128), black = Vector2(0, 320) },
	L_1 = { rank = 5, white = Vector2(72, 128), black = Vector2(72, 320) },
	L_2 = { rank = 5, white = Vector2(144, 128), black = Vector2(144, 320) },
	SGT = { rank = 4, white = Vector2(216, 64), black = Vector2(216, 256) },
	PVT = { rank = 2, white = Vector2(288, 64), black = Vector2(288, 256) },
	FLG = { rank = 1, white = Vector2(216, 128), black = Vector2(216, 320) }
}

var Firebase = preload("res://lib/ifmoan/firebase/firebase.gd")
var Pool = preload("res://lib/ifmoan/thread-pool/thread_pool.gd")
var Storage = preload("res://lib/ifmoan/storage/storage.gd")
var Piece = preload("res://source/game/piece.scn")
var Player = preload("res://source/common/player.gd")

var pool = Pool.new(12)
var storage = Storage.new("user://data.db", "XDvJ3YiQ9ouVoPiSIchR")

var connection
var lobby_id

var player = Player.new()
var opponent = Player.new()

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
	if connection == null:
		var json = storage.read()
		if json.empty():
			return Dictionary()
		else:
			var info = Dictionary()
			info.parse_json(json)
			return info
	else:
		return connection

func break_connection():
	connection.clear()
	storage.write("", false)

func set_lobby_id(id):
	lobby_id = id

func get_lobby_id():
	return lobby_id

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
	
	for key in PIECE_ATTRIB:
		var count = 1
		if key == "PVT":
			count = 6
		elif key == "SPY":
			count = 2
		
		var info = PIECE_ATTRIB[key]
		for i in range(count):
			var piece = Piece.instance()
			var pos = info[color]
			var rank = info["rank"]
			var cover = str("res://assets/cover_", color, ".png")
			piece.set_region_position(pos)
			piece.set_type(color)
			piece.set_rank(rank)
			piece.set_cover(cover)
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
