
extends AcceptDialog

func _ready():
	var label = get_child(1)
	label.set_align(label.ALIGN_CENTER)
	label.set_autowrap(true)
	label.set_max_lines_visible(4)
