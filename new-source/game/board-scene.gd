extends Control

signal board_on_moved_piece(rank, color, current_slot, destination_slot)

enum PIECE_COLOR {
	white,
	black
}

enum PIECE {
	flag,
	private,
	sergeant,
	second_lieutenant,
	first_lieutenant,
	captain,
	major,
	lieutenant_colonel,
	colonel,
	one_star_general,
	two_star_general,
	three_star_general,
	four_star_general,
	five_star_general,
	spy
}

enum PIECE_APPEARANCE {
	covered,
	revealed
}

enum BOARD_STATE {
	setting_up_pieces,
	game_started
}

enum BOARD_SLOT_STATE {
	occupied,
	vacant
}

const PIECES_GROUP = "pieces"

var board_state = BOARD_STATE.setting_up_pieces
var board_slots = []
var white_piece_appearance = PIECE_APPEARANCE.revealed
var black_piece_appearance = PIECE_APPEARANCE.covered

onready var piece_width = 72
onready var piece_height = 64
onready var piece_size = Vector2(piece_width, piece_height)
onready var board_slot_x = 9
onready var board_slot_y = 8
onready var board_width = piece_width * board_slot_x
onready var board_height = piece_height * board_slot_y
onready var board_size = Vector2(board_width, board_height)
onready var sprite_positions = get_sprite_positions()

func _ready():
	for x in range(board_slot_x):
		board_slots.append([])
		board_slots[x].resize(board_slot_y)
		for y in range(board_slot_y):
			board_slots[x][y] = BOARD_SLOT_STATE.vacant

func get_initial_occupied_board_slots_for_white_piece():
	return get_initial_occupied_board_slots_for(PIECE_COLOR.white)

func get_initial_occupied_board_slots_for_black_piece():
	return get_initial_occupied_board_slots_for(PIECE_COLOR.black)

func get_initial_occupied_board_slots_for(piece_color):
	var slots = []
	for x in range(board_slot_x):
		for y in range(board_slot_y):
			match board_slots[x][y]:
				BOARD_SLOT_STATE.occupied:
					var slot = Vector2(x, y)
					var piece = find_piece_by_color_at(slot, piece_color)
					if piece == null:
						continue
					slots.append(Vector3(x, y, piece.rank))
	return slots

func set_initial_occupied_board_slots_for_white_piece_with(slots):
	set_initial_occupied_board_slots_for(PIECE_COLOR.white, slots)

func set_initial_occupied_board_slots_for_black_piece_with(slots):
	set_initial_occupied_board_slots_for(PIECE_COLOR.black, slots)

func set_initial_occupied_board_slots_for(piece_color, slots):
	var group = group_for(piece_color)
	
	for node in get_tree().get_nodes_in_group(group):
		node.queue_free()
	
	var piece_scene = preload("res://new-source/game/piece-scene.tscn")
	
	for slot in slots:
		var position = Vector2(slot.x * piece_width, slot.y * piece_height)
		var piece = piece_scene.instance()
		piece.color = piece_color
		piece.is_cover_texture_enabled = true
		piece.set_position(position)
		piece.add_to_group(group)
		piece.add_to_group(PIECES_GROUP)
		add_child(piece)

func find_piece_by_color_at(slot, piece_color):
	return find_piece_in(group_for(piece_color), slot)

func find_piece_at(slot):
	return find_piece_in(PIECES_GROUP, slot)

func find_piece_in(group, slot):
	for piece in get_tree().get_nodes_in_group(group):
		var position = piece.get_position()
		var slot_x = int(position.x / piece_width)
		var slot_y = int(position.y / piece_height)
		var piece_slot = Vector2(slot_x, slot_y)
		if piece_slot == slot: return piece

func enable_white_pieces():
	enable_pieces_with(PIECE_COLOR.white)

func enable_black_pieces():
	enable_pieces_with(PIECE_COLOR.black)

func enable_pieces_with(color):
	get_tree().call_group(group_for(color), "enable_drag")

func disable_white_pieces():
	disable_pieces_with(PIECE_COLOR.white)

func disable_black_pieces():
	disable_pieces_with(PIECE_COLOR.black)

func disable_pieces_with(color):
	get_tree().call_group(group_for(color), "disable_drag")

func setup_covered_white_pieces():
	white_piece_appearance = PIECE_APPEARANCE.covered
	setup_pieces_with(PIECE_COLOR.white, 0)

func setup_revealed_white_pieces():
	white_piece_appearance = PIECE_APPEARANCE.revealed
	setup_pieces_with(PIECE_COLOR.white, 0)

func setup_covered_black_pieces():
	black_piece_appearance = PIECE_APPEARANCE.covered
	setup_pieces_with(PIECE_COLOR.black, 5)

func setup_revealed_black_pieces():
	black_piece_appearance = PIECE_APPEARANCE.revealed
	setup_pieces_with(PIECE_COLOR.black, 5)

func setup_pieces_with(color, y_offset):
	var pieces
	match color:
		PIECE_COLOR.white:
			pieces = create_pieces_with(color)
			
		PIECE_COLOR.black:
			pieces = create_pieces_with(color)
			
		_:
			return
	
	var x = 0
	var y = y_offset
	for piece in pieces:
		var position = Vector2(x * piece_width, y * piece_height)
		piece.color = color
		piece.set_position(position)
		piece.connect("piece_on_swap", self, "piece_on_swap")
		piece.connect("piece_on_clash", self, "piece_on_clash")
		match color:
			PIECE_COLOR.white:
				match white_piece_appearance:
					PIECE_APPEARANCE.covered:
						piece.is_cover_texture_enabled = true
				
			PIECE_COLOR.black:
				match black_piece_appearance:
					PIECE_APPEARANCE.covered:
						piece.is_cover_texture_enabled = true
			
		piece.add_to_group(group_for(color))
		piece.add_to_group(PIECES_GROUP)
		add_child(piece)
		board_slots[x][y] = BOARD_SLOT_STATE.occupied
		x += 1
		if position.x + piece_width >= board_width:
			x = 0
			y += 1

func change_state_to_game_started():
	board_state = BOARD_STATE.game_started

func group_for(color):
	match color:
		PIECE_COLOR.white: return "white"
		PIECE_COLOR.black: return "black"

func piece_on_swap(piece1, piece2):
	match board_state:
		BOARD_STATE.setting_up_pieces:
			var pos1 = piece1.get_position()
			var pos2 = piece2.get_position()
			piece1.set_position(pos2)
			piece2.set_position(pos1)

func piece_on_clash(piece1, piece2):
	match board_state:
		BOARD_STATE.game_started:
			move_piece_on_game_started_to(piece1.get_position(), piece2)

func create_slot_for(position):
	var slot = Vector2()
	slot.x = int(position.x / piece_width)
	slot.y = int(position.y / piece_height)
	return slot

func can_drop_data(pos, data):
	return true

func drop_data(position, piece):
	match board_state:
		BOARD_STATE.setting_up_pieces:
			move_piece_on_setting_up_pieces_to(position, piece)
		_:
			move_piece_on_game_started_to(position, piece)

func move_piece_on_setting_up_pieces_to(position, piece):
	var row
	var y_lower_bound
	var y_upper_bound
	
	match piece.color:
		PIECE_COLOR.white:
			row = 2
			y_lower_bound = 0
			y_upper_bound = (row + 1) * piece_height
			
		PIECE_COLOR.black:
			row = 5
			y_lower_bound = row * piece_height
			y_upper_bound = board_height
			
		_:
			return
		
	var x_lower_bound = 0
	var x_upper_bound = board_width
	var destination_slot = create_slot_for(position)
	var current_slot = create_slot_for(piece.get_position())
	
	if position.x < x_lower_bound || position.x > x_upper_bound || position.y < y_lower_bound || position.y > y_upper_bound: return
	if board_slots[destination_slot.x][destination_slot.y] != BOARD_SLOT_STATE.vacant: return
	
	board_slots[destination_slot.x][destination_slot.y] = BOARD_SLOT_STATE.occupied
	board_slots[current_slot.x][current_slot.y] = BOARD_SLOT_STATE.vacant
	
	var new_position = Vector2()
	new_position.x = destination_slot.x * piece_width
	new_position.y = destination_slot.y * piece_height
	piece.set_position(new_position)

func move_piece_on_game_started_to(position, piece):
	var destination_slot = create_slot_for(position)
	var current_slot = create_slot_for(piece.get_position())
	var distance_x = abs(destination_slot.x - current_slot.x)
	var distance_y = abs(destination_slot.y - current_slot.y)
	
	if distance_x > 1 || distance_y > 1 || (distance_x >= 1 && distance_y >= 1): return
	
	var slot = Vector2(destination_slot.x, destination_slot.y)
	emit_signal("board_on_moved_piece", piece.rank, piece.color, current_slot, destination_slot)

func move_white_piece_from(current_slot, destination_slot):
	move_piece_with(PIECE_COLOR.white, current_slot, destination_slot)

func move_black_piece_from(current_slot, destination_slot):
	move_piece_with(PIECE_COLOR.black, current_slot, destination_slot)

func move_piece_with(color, current_slot, destination_slot):
	var old_position = Vector2(current_slot.x * piece_width, current_slot.y * piece_height)
	var new_position = Vector2(destination_slot.x * piece_width, destination_slot.y * piece_height)
	var pieces = get_tree().get_nodes_in_group(group_for(color))
	for piece in pieces:
		if piece.get_position() == old_position:
			piece.set_position(new_position)
			break

func remove_white_piece_in(slot):
	remove_piece_with(PIECE_COLOR.white, slot)

func remove_black_piece_in(slot):
	remove_piece_with(PIECE_COLOR.black, slot)

func remove_piece_with(color, slot):
	var position = Vector2(slot.x * piece_width, slot.y * piece_height)
	var pieces = get_tree().get_nodes_in_group(group_for(color))
	for piece in pieces:
		if piece.get_position() == position:
			piece.queue_free()
			break

func create_pieces_with(piece_color):
	var piece = preload("res://new-source/game/piece-scene.tscn")
	var pieces = []
	var region_rect = Rect2(Vector2(), piece_size)
	
	region_rect.position = sprite_positions[PIECE.flag][piece_color]
	var flag_piece = piece.instance()
	flag_piece.sprite_region_rect = region_rect
	flag_piece.rank = PIECE.flag
	pieces.push_back(flag_piece)
	
	region_rect.position = sprite_positions[PIECE.private][piece_color]
	for i in range(6):
		var private_piece = piece.instance()
		private_piece.sprite_region_rect = region_rect
		private_piece.rank = PIECE.private
		pieces.push_back(private_piece)
	
	region_rect.position = sprite_positions[PIECE.sergeant][piece_color]
	var sergeant_piece = piece.instance()
	sergeant_piece.sprite_region_rect = region_rect
	sergeant_piece.rank = PIECE.sergeant
	pieces.push_back(sergeant_piece)
	
	region_rect.position = sprite_positions[PIECE.second_lieutenant][piece_color]
	var second_lieutenant_piece = piece.instance()
	second_lieutenant_piece.sprite_region_rect = region_rect
	second_lieutenant_piece.rank = PIECE.second_lieutenant
	pieces.push_back(second_lieutenant_piece)
	
	region_rect.position = sprite_positions[PIECE.first_lieutenant][piece_color]
	var first_lieutenant_piece = piece.instance()
	first_lieutenant_piece.sprite_region_rect = region_rect
	first_lieutenant_piece.rank = PIECE.first_lieutenant
	pieces.push_back(first_lieutenant_piece)
	
	region_rect.position = sprite_positions[PIECE.captain][piece_color]
	var captain_piece = piece.instance()
	captain_piece.sprite_region_rect = region_rect
	captain_piece.rank = PIECE.captain
	pieces.push_back(captain_piece)
	
	region_rect.position = sprite_positions[PIECE.major][piece_color]
	var major_piece = piece.instance()
	major_piece.sprite_region_rect = region_rect
	major_piece.rank = PIECE.major
	pieces.push_back(major_piece)
	
	region_rect.position = sprite_positions[PIECE.lieutenant_colonel][piece_color]
	var lieutenant_colonel_piece = piece.instance()
	lieutenant_colonel_piece.sprite_region_rect = region_rect
	lieutenant_colonel_piece.rank = PIECE.lieutenant_colonel
	pieces.push_back(lieutenant_colonel_piece)
	
	region_rect.position = sprite_positions[PIECE.colonel][piece_color]
	var colonel_piece = piece.instance()
	colonel_piece.sprite_region_rect = region_rect
	colonel_piece.rank = PIECE.colonel
	pieces.push_back(colonel_piece)
	
	region_rect.position = sprite_positions[PIECE.one_star_general][piece_color]
	var one_star_general_general_piece = piece.instance()
	one_star_general_general_piece.sprite_region_rect = region_rect
	one_star_general_general_piece.rank = PIECE.one_star_general
	pieces.push_back(one_star_general_general_piece)
	
	region_rect.position = sprite_positions[PIECE.two_star_general][piece_color]
	var two_star_general_piece = piece.instance()
	two_star_general_piece.sprite_region_rect = region_rect
	two_star_general_piece.rank = PIECE.two_star_general
	pieces.push_back(two_star_general_piece)
	
	region_rect.position = sprite_positions[PIECE.three_star_general][piece_color]
	var three_star_general_piece = piece.instance()
	three_star_general_piece.sprite_region_rect = region_rect
	three_star_general_piece.rank = PIECE.three_star_general
	pieces.push_back(three_star_general_piece)
	
	region_rect.position = sprite_positions[PIECE.four_star_general][piece_color]
	var four_star_general_piece = piece.instance()
	four_star_general_piece.sprite_region_rect = region_rect
	four_star_general_piece.rank = PIECE.four_star_general
	pieces.push_back(four_star_general_piece)
	
	region_rect.position = sprite_positions[PIECE.five_star_general][piece_color]
	var five_star_general_piece = piece.instance()
	five_star_general_piece.sprite_region_rect = region_rect
	five_star_general_piece.rank = PIECE.five_star_general
	pieces.push_back(five_star_general_piece)
	
	region_rect.position = sprite_positions[PIECE.spy][piece_color]
	for i in range(2):
		var spy_piece = piece.instance()
		spy_piece.sprite_region_rect = region_rect
		spy_piece.rank = PIECE.spy
		pieces.push_back(spy_piece)
	
	return pieces

func get_sprite_positions():
	var sprite_positions = []
	var pieces_count = 15
	var color_count = 2
	
	for x in range(pieces_count):
		sprite_positions.append([])
		sprite_positions[x].resize(color_count)
	
	sprite_positions[PIECE.flag              ][PIECE_COLOR.white] = Vector2(216, 128)
	sprite_positions[PIECE.private           ][PIECE_COLOR.white] = Vector2(288, 64 ) 
	sprite_positions[PIECE.sergeant          ][PIECE_COLOR.white] = Vector2(216, 64 )
	sprite_positions[PIECE.first_lieutenant  ][PIECE_COLOR.white] = Vector2(72 , 128)
	sprite_positions[PIECE.second_lieutenant ][PIECE_COLOR.white] = Vector2(144, 128)
	sprite_positions[PIECE.captain           ][PIECE_COLOR.white] = Vector2(0  , 128)
	sprite_positions[PIECE.major             ][PIECE_COLOR.white] = Vector2(144, 64 )
	sprite_positions[PIECE.lieutenant_colonel][PIECE_COLOR.white] = Vector2(72 , 64 )
	sprite_positions[PIECE.colonel           ][PIECE_COLOR.white] = Vector2(0  , 64 )
	sprite_positions[PIECE.one_star_general  ][PIECE_COLOR.white] = Vector2(288, 0  )
	sprite_positions[PIECE.two_star_general  ][PIECE_COLOR.white] = Vector2(216, 0  )
	sprite_positions[PIECE.three_star_general][PIECE_COLOR.white] = Vector2(144, 0  )
	sprite_positions[PIECE.four_star_general ][PIECE_COLOR.white] = Vector2(72 , 0  )
	sprite_positions[PIECE.five_star_general ][PIECE_COLOR.white] = Vector2(0  , 0  )
	sprite_positions[PIECE.spy               ][PIECE_COLOR.white] = Vector2(288, 128)
	
	sprite_positions[PIECE.flag              ][PIECE_COLOR.black] = Vector2(216, 320)
	sprite_positions[PIECE.private           ][PIECE_COLOR.black] = Vector2(288, 256)
	sprite_positions[PIECE.sergeant          ][PIECE_COLOR.black] = Vector2(216, 256)
	sprite_positions[PIECE.first_lieutenant  ][PIECE_COLOR.black] = Vector2(72 , 320)
	sprite_positions[PIECE.second_lieutenant ][PIECE_COLOR.black] = Vector2(144, 320)
	sprite_positions[PIECE.captain           ][PIECE_COLOR.black] = Vector2(0  , 320)
	sprite_positions[PIECE.major             ][PIECE_COLOR.black] = Vector2(144, 256)
	sprite_positions[PIECE.lieutenant_colonel][PIECE_COLOR.black] = Vector2(72 , 256)
	sprite_positions[PIECE.colonel           ][PIECE_COLOR.black] = Vector2(0  , 256)
	sprite_positions[PIECE.one_star_general  ][PIECE_COLOR.black] = Vector2(288, 192)
	sprite_positions[PIECE.two_star_general  ][PIECE_COLOR.black] = Vector2(216, 192)
	sprite_positions[PIECE.three_star_general][PIECE_COLOR.black] = Vector2(144, 192)
	sprite_positions[PIECE.four_star_general ][PIECE_COLOR.black] = Vector2(72 , 192)
	sprite_positions[PIECE.five_star_general ][PIECE_COLOR.black] = Vector2(0  , 192)
	sprite_positions[PIECE.spy               ][PIECE_COLOR.black] = Vector2(288, 320)
	
	return sprite_positions
