
extends AcceptDialog

const FIX_WIDTH = 258
const MIN_HEIGHT = 68

func _init():
	var size = Vector2(FIX_WIDTH, MIN_HEIGHT)
	set_size(size)
	
	var label = get_child(1)
	label.set_align(label.ALIGN_CENTER)
	label.set_autowrap(true)
	label.set_max_lines_visible(-1)

func set_text(text):
	.set_text(text)
	
	var label = get_child(1)
	var height = label.get_line_count() * label.get_line_height()
	var size = Vector2(label.get_size().width, height)
	label.set_size(size)
	
	height = MIN_HEIGHT + height
	size = Vector2(FIX_WIDTH, height)
	set_size(size)
