extends Reference
	
var firebase
var arbiter_path

func _init(firebase, arbiter_path):
	self.firebase = firebase
	self.arbiter_path = arbiter_path

func request(data):
	firebase.put(arbiter_path, data.to_json())

func send(event, next, current, message, info):
	var timestamp = OS.get_unix_time()
	var data = {
		"event": event,
		"next": next,
		"current": current,
		"message": message,
		"timestamp": timestamp,
		"info": info
	}
	request(data)


func on_piece_moved(next, current, old_pos, new_pos):
	var event = "move"
	var message = str(next.to_upper(), "'s turn.")
	var info = {
		"old_pos": {
			"x": old_pos.x,
			"y": old_pos.y
		},
		"new_pos": {
			"x": new_pos.x,
			"y": new_pos.y
		}
	}
	send(event, next, current, message, info)

func on_clash_split(next, current, color1, color2, pos1, pos2):
	var event = "split"
	var message = "Clash is split."
	message += str("\n", next.to_upper(), "'s turn.")
	var info =  {
		"color1": color1,
		"color2": color2,
		"pos1": {
			"x": pos1.x,
			"y": pos1.y
		},
		"pos2": {
			"x": pos2.x,
			"y": pos2.y
		}
	}
	send(event, next, current, message, info)

func on_clash_eliminated(next, current, win, lose, wpos, lpos):
	var event = "eliminated"
	var message = str(lose.to_upper(), " is eliminated.")
	message += str("\n", next.to_upper(), "'s turn.")
	var info = {
		"win": win,
		"lose": lose,
		"win_pos": {
			"x": wpos.x,
			"y": wpos.y
		},
		"lose_pos": {
			"x": lpos.x,
			"y": lpos.y
		}
	}
	send(event, next, current, message, info)

func on_post_game(event, message, win, lose):
	var timestamp = OS.get_unix_time()
	var data = {
		"event": event,
		"win": win,
		"lose": lose,
		"message": message,
		"timestamp": timestamp
	}
	request(data)

func on_draw():
	var event = "draw"
	var message = "Game is draw."
	on_post_game(event, message, "none", "none")

func on_win(win, lose):
	var event = "win"
	var message = str(win.to_upper(), " wins.")
	on_post_game(event, message, win, lose)

func on_pre_game(event, message, info):
	var timestamp = OS.get_unix_time()
	var data = {
		"event": event,
		"message": message,
		"timestamp": timestamp,
		"info": info
	}
	request(data)

func on_ready(color):
	var event = "ready"
	var message = str(color.to_upper(), " is ready.")
	var info = {"color": color}
	on_pre_game(event, message, info)

func on_first_move(color):
	var event = "first_move"
	var message = str(color.to_upper(), " moves first.")
	var info = {"color": color}
	on_pre_game(event, message, info)

func on_swap(color, pos1, pos2):
	var event = "swap"
	var message = "On swap"
	var info = {
		"color": color,
		"pos1": {
			"x": pos1.x,
			"y": pos1.y
		},
		"pos2": {
			"x": pos2.x,
			"y": pos2.y
		}
	}
	on_pre_game(event, message, info)

func on_arrange(color, old_pos, new_pos):
	var event = "arrange"
	var message = "On arrange"
	var info = {
		"color": color,
		"old_pos": {
			"x": old_pos.x,
			"y": old_pos.y
		},
		"new_pos": {
			"x": new_pos.x,
			"y": new_pos.y
		}
	}
	on_pre_game(event, message, info)
