
extends Panel

signal board_on_drop(pos, data)

func can_drop_data(pos, data):
	return true

func drop_data(pos, data):
	emit_signal("board_on_drop", pos, data)