extends Control

signal piece_on_swap(piece1, piece2)
signal piece_on_clash(piece1, piece2)

var sprite_region_rect = Rect2()
var is_cover_texture_enabled = false
var rank = -1
var color = 0
var is_drag_enabled = true

func _ready():
	var sprite = get_node("sprite")
	if is_cover_texture_enabled:
		var path = str("res://assets/cover_", color_string_for(color), ".png")
		sprite.set_texture(load(path))
		return
	sprite.set_region_rect(sprite_region_rect)

func can_drop_data(position, data):
	return true

func get_drag_data(position):
	if !is_drag_enabled || is_cover_texture_enabled: return
	var icon = load("res://new-source/game/piece-scene.tscn").instance()
	icon.sprite_region_rect = sprite_region_rect
	set_drag_preview(icon)
	return self

func drop_data(pos, piece):
	if color == piece.color:
		emit_signal("piece_on_swap", self, piece)
		return
	emit_signal("piece_on_clash", self, piece)

func color_string_for(color):
	match color:
		0: return "white"
		_: return "black"

func enable_drag():
	is_drag_enabled = true

func disable_drag():
	is_drag_enabled = false

