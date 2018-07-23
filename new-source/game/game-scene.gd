extends Node2D

onready var board = get_node("board_scene")
onready var white_status_label = board.get_node("white_status_label")
onready var black_status_label = board.get_node("black_status_label")

func _ready():
	white_status_label.hide()
	black_status_label.hide()
	
	network_controller.connect("network_controller_on_enemy_ready_with", self, "on_enemy_ready_with")
	network_controller.connect("network_controller_on_first_move_with", self, "on_first_move_with")
	network_controller.connect("network_controller_on_moved_piece_from", self, "on_moved_piece_from")
	network_controller.connect("network_controller_on_next_move_with", self, "on_next_move_with")
	network_controller.connect("network_controller_on_game_over_with", self, "on_game_over_with")
	network_controller.connect("network_controller_on_reveal_enemy_pieces_with", self, "on_reveal_enemy_pieces_with")
	network_controller.connect("network_controller_on_both_pieces_removed_with", self, "on_both_pieces_removed_with")
	network_controller.connect("network_controller_on_removed_aggressive_piece_with", self, "on_removed_aggressive_piece_with")
	network_controller.connect("network_controller_on_removed_neutral_piece_with", self, "on_removed_neutral_piece_with")
	
	board.connect("board_on_moved_piece", self, "board_on_moved_piece_with")
	
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

func board_on_moved_piece_with(color, current_slot, destination_slot):
	network_controller.notify_on_moved_piece_with(color, current_slot, destination_slot)

func on_enemy_ready_with(slots):
	match package.game.enemy_color:
		package.game.PIECE_COLOR.white:
			board.set_initial_occupied_board_slots_for_white_piece_with(slots)
			
		package.game.PIECE_COLOR.black:
			board.set_initial_occupied_board_slots_for_black_piece_with(slots)

func on_first_move_with(color):
	on_next_move_with(color)

func on_moved_piece_from(current_slot, destination_slot):
	board.move_piece_from(current_slot, destination_slot)

func on_next_move_with(color):
	match color:
		package.game.PIECE_COLOR.white:
			white_status_label.show()
			black_status_label.hide()
			
		package.game.PIECE_COLOR.black:
			white_status_label.hide()
			black_status_label.show()
	
	match package.game.you_color:
		package.game.PIECE_COLOR.white:
			if package.game.is_your_turn_with(color):
				board.enable_white_pieces()
				return
			board.disable_white_pieces()
			black_status_label.show()
			white_status_label.hide()
			
		package.game.PIECE_COLOR.black:
			if package.game.is_your_turn_with(color):
				board.enable_black_pieces()
				return
			board.disable_black_pieces()

func on_game_over_with(winner, color):
	match color:
		package.game.PIECE_COLOR.white:
			white_status_label.show()
			black_status_label.hide()
			white_status_label.text = "White wins"
			
		package.game.PIECE_COLOR.black:
			white_status_label.hide()
			black_status_label.show()
			black_status_label.text = "Black wins"

func on_reveal_enemy_pieces_with(slots):
	match package.game.enemy_color:
		package.game.PIECE_COLOR.white:
			board.reveal_white_pieces_in(slots)
			
		package.game.PIECE_COLOR.black:
			board.reveal_black_pieces_in(slots)
		
	board.disable_black_pieces()
	board.disable_white_pieces()

func on_both_pieces_removed_with(current_slot, destination_slot):
	board.remove_pieces_in([current_slot, destination_slot])

func on_removed_aggressive_piece_with(slot):
	board.remove_pieces_in([slot])

func on_removed_neutral_piece_with(vacant_slot, occupied_slot):
	board.remove_pieces_in([occupied_slot])
	board.move_piece_from(vacant_slot, occupied_slot)