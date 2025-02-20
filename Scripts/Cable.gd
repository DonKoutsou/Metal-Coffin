extends TextureRect

var StartingPos : Vector2
var PosToGo : Vector2
var AmmWent : float = 0

func _ready() -> void:
	StartingPos = position
	PosToGo = position
var d = 0.2
func _physics_process(delta: float) -> void:
	position = position.lerp(PosToGo, AmmWent)
	AmmWent += 0.002
	d -= delta
	if (d > 0):
		return
	d = 0.2
	var posx = randf_range(StartingPos.x-10, StartingPos.x+10)
	var posy = randf_range(StartingPos.y-10, StartingPos.y+10)
	PosToGo = Vector2(posx, posy)
	AmmWent = 0
	#get_child(0).position = Vector2(StartingPos.x- posx, StartingPos.y - posy)
