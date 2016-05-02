tool

extends Sprite

export(String,\
"W_G_5", "W_G_4", "W_G_3", "W_G_2", "W_G_1", "W_COL", "W_L_COL", "W_MAJ",\
"W_SGT", "W_PVT", "W_CAP", "W_L_1", "W_L_2", "W_FLG", "W_SPY",\
"B_G_5", "B_G_4", "B_G_3", "B_G_2", "B_G_1", "B_COL", "B_L_COL", "B_MAJ",\
"B_SGT", "B_PVT", "B_CAP", "B_L_1", "B_L_2", "B_FLG", "B_SPY") var type = "W_G_5"

const PIECE_POS = {
	W_G_5 = Vector2(0, 0),
	W_G_4 = Vector2(72, 0),
	W_G_3 = Vector2(144, 0),
	W_G_2 = Vector2(216, 0),
	W_G_1 = Vector2(288, 0),
	W_COL = Vector2(0, 64),
	W_L_COL = Vector2(72, 64),
	W_MAJ = Vector2(144, 64),
	W_SGT = Vector2(216, 64),
	W_PVT = Vector2(288, 64),
	W_CAP = Vector2(0, 128),
	W_L_1 = Vector2(72, 128),
	W_L_2 = Vector2(144, 128),
	W_FLG = Vector2(216, 128),
	W_SPY = Vector2(288, 128),
	
	B_G_5 = Vector2(0, 192),
	B_G_4 = Vector2(72, 192),
	B_G_3 = Vector2(144, 192),
	B_G_2 = Vector2(216, 192),
	B_G_1 = Vector2(288, 192),
	B_COL = Vector2(0, 256),
	B_L_COL = Vector2(72, 256),
	B_MAJ = Vector2(144, 256),
	B_SGT = Vector2(216, 256),
	B_PVT = Vector2(288, 256),
	B_CAP = Vector2(0, 320),
	B_L_1 = Vector2(72, 320),
	B_L_2 = Vector2(144, 320),
	B_FLG = Vector2(216, 320),
	B_SPY = Vector2(288, 320)
}

func _ready():
	var pos = PIECE_POS[type]
	var size = Vector2(72, 64)
	var rect = Rect2(pos, size)
	set_region_rect(rect)


