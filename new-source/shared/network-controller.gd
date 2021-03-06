extends Node

signal network_controller_on_connected_player_with(id)
signal network_controller_on_disconnected_player_with(id)
signal network_controller_on_connected_server()
signal network_controller_on_disconnected_server()
signal network_controller_on_failed_connecting_to_server()

signal network_controller_on_assigned_piece_color(color)
signal network_controller_on_enemy_connected_with(color)

signal network_controller_on_game_started()
signal network_controller_on_game_over_with(winner, color)
signal network_controller_on_stalemate()

signal network_controller_on_enemy_ready_with(slots)
signal network_controller_on_first_move_with(color)
signal network_controller_on_next_move_with(color)

signal network_controller_on_moved_piece_from(current_slot, destination_slot)
signal network_controller_on_removed_neutral_piece_with(vacant_slot, occupied_slot)
signal network_controller_on_removed_aggressive_piece_with(slot)
signal network_controller_on_both_pieces_removed_with(current_slot, destination_slot)

signal network_controller_on_reveal_enemy_pieces_with(slots)

func _ready():
	get_tree().connect("network_peer_connected"   , self, "player_on_connected"        )
	get_tree().connect("network_peer_disconnected", self, "player_on_disconnected"     )
	get_tree().connect("connected_to_server"      , self, "server_on_connected"        )
	get_tree().connect("connection_failed"        , self, "server_on_failed_connection")
	get_tree().connect("server_disconnected"      , self, "server_on_disconnected"     )

func disconnect_to_LAN_server():
	get_tree().set_network_peer(null)

func player_on_connected(id):
	print("player ", id, " is connected")
	emit_signal("network_controller_on_connected_player_with", id)

func player_on_disconnected(id):
	print("player ", id, " is disconnected")
	emit_signal("network_controller_on_disconnected_player_with", id)

func server_on_connected():
	print("server connected")
	emit_signal("network_controller_on_connected_server")

func server_on_disconnected():
	print("server disconnected")
	emit_signal("network_controller_on_disconnected_server")

func server_on_failed_connection():
	print("failed connecting to server")
	emit_signal("network_controller_on_failed_connecting_to_server")

func connect_to_LAN_server_with(host, port):
	var peer = NetworkedMultiplayerENet.new()
	peer.set_compression_mode(NetworkedMultiplayerENet.COMPRESS_RANGE_CODER)
	peer.create_client(host, port)
	get_tree().set_network_peer(peer)
	print("connecting to ", host, ":", port)

func notify_to_start_the_game():
	rpc("start_game")

func notify_on_moved_piece_with(color, current_slot, destination_slot):
	rpc("process_moved_piece_with", color, current_slot, destination_slot)

func register_initial_board_slots_for(color, slots):
	rpc("register_initial_board_slots_for", color, slots)

slave func on_assigned_piece_color(color):
	emit_signal("network_controller_on_assigned_piece_color", color)

slave func on_new_connected_player_with(id, color):
	emit_signal("network_controller_on_enemy_connected_with", color)

slave func on_already_connected_player_with(id, color):
	emit_signal("network_controller_on_enemy_connected_with", color)

slave func on_game_started():
	emit_signal("network_controller_on_game_started")

slave func on_enemy_ready_with(slots):
	emit_signal("network_controller_on_enemy_ready_with", slots)

slave func on_first_move_with(color):
	emit_signal("network_controller_on_first_move_with", color)

slave func on_next_move_with(color):
	emit_signal("network_controller_on_next_move_with", color)

slave func on_moved_piece_from(current_slot, destination_slot, color):
	emit_signal("network_controller_on_moved_piece_from", current_slot, destination_slot)

slave func on_both_pieces_removed_with(current_slot, destination_slot):
	emit_signal("network_controller_on_both_pieces_removed_with", current_slot, destination_slot)

slave func on_removed_neutral_piece_with(vacant_slot, occupied_slot):
	emit_signal("network_controller_on_removed_neutral_piece_with", vacant_slot, occupied_slot)

slave func on_removed_aggressive_piece_with(slot):
	emit_signal("network_controller_on_removed_aggressive_piece_with", slot)

slave func on_game_over_with(winner, color):
	emit_signal("network_controller_on_game_over_with", winner, color)
	
slave func on_reveal_enemy_pieces_with(slots):
	emit_signal("network_controller_on_reveal_enemy_pieces_with", slots)

slave func on_stalemate():
	emit_signal("network_controller_on_stalemate")
