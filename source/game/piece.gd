
extends TextureFrame

signal piece_on_swap(piece1, piece2)
signal piece_on_clash(piece1, piece2)

var type
var rank
var special_rank_kill
var drag_enable = true

func set_type(what):
	type = what

func get_type():
	return type

func set_rank(what):
	rank = what

func get_rank():
	return rank

func set_cover(path):
	set_texture(load(path))

func enable_drag(enable):
	drag_enable = enable

func is_drag_enable():
	return drag_enable

func reveal(show):
	var appearance = get_node("appearance")
	appearance.set_hidden(!show)

func set_region_position(pos):
	var appearance = get_node("appearance")
	var size = Vector2(72, 64)
	var rect = Rect2(pos, size)
	appearance.set_region_rect(rect)

func get_drag_data(pos):
	if drag_enable:
		var icon = load("res://source/game/piece.scn").instance()
		var appearance = get_node("appearance")
		var region = appearance.get_region_rect()
		icon.set_region_position(region.pos)
		set_drag_preview(icon)
		return self

func can_drop_data(pos, data):
	return true

func drop_data(pos, piece):
	if get_type() != piece.get_type():
		emit_signal("piece_on_clash", self, piece)
	else:
		emit_signal("piece_on_swap", self, piece)
