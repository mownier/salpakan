extends Node2D

onready var board = get_node("board_scene")

func _ready():
	network_controller.connect("network_controller_on_enemy_ready_with", self, "on_enemy_ready_with")
	network_controller.connect("network_controller_on_first_move_with", self, "on_first_move_with")
	board.connect("board_on_moved_piece", self, "board_on_moved_piece")
	match package.game.you_color:
		package.game.PIECE_COLOR.white:
			board.setup_revealed_white_pieces()
			board.setup_covered_black_pieces()
			
		package.game.PIECE_COLOR.black:
			board.setup_revealed_black_pieces()
			board.setup_covered_white_pieces()

func _on_start_button_pressed():
	board.change_state_to_game_started()
	get_node("start_button").queue_free()
	
	var color = package.game.you_color
	var slots
	match color:
		package.game.PIECE_COLOR.white:
			slots = board.get_initial_occupied_board_slots_for_white_piece()
			
		package.game.PIECE_COLOR.black:
			slots = board.get_initial_occupied_board_slots_for_black_piece()
	network_controller.register_initial_board_slots_for(color, slots)

func board_on_moved_piece(rank, color, current_slot, destination_slot):
	print("rank: ", rank, ", color: ", color, ", current_slot: ", current_slot, ", destination_slot: ", destination_slot)

func on_enemy_ready_with(slots):
	match package.game.enemy_color:
		package.game.PIECE_COLOR.white:
			board.set_initial_occupied_board_slots_for_white_piece_with(slots)
			
		package.game.PIECE_COLOR.black:
			board.set_initial_occupied_board_slots_for_black_piece_with(slots)

func on_first_move_with(color):
	match package.game.you_color:
		package.game.PIECE_COLOR.white:
			if package.game.is_your_turn_with(color):
				board.enable_white_pieces()
				return
			board.disable_white_pieces()
			
		package.game.PIECE_COLOR.black:
			if package.game.is_your_turn_with(color):
				board.enable_black_pieces()
				return
			board.disable_black_pieces()
