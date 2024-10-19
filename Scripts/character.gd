
extends  MeshInstance3D
@export var ManuverSpeed = 4
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
		
var GoingUp = false
var Jumpspot = 0
func Jump() ->void:
	var tw = get_tree().create_tween()
	tw.tween_property(self, "position:y", 3,1)
	tw.set_ease(Tween.EASE_OUT)
	pass
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:
	if (Input.is_action_pressed("MoveLeft") and position.x > -5):
		rotation.z = deg_to_rad(max(rad_to_deg(rotation.z) - ManuverSpeed, -30))
		position.x = max(-5, position.x - 0.1)
	else : if (Input.is_action_pressed("MoveRight") and position.x < 5):
		rotation.z = deg_to_rad(min(rad_to_deg(rotation.z) + ManuverSpeed, 30))
		position.x = min(5, position.x + 0.1)
	else :
		if (rotation.z > 0):
			rotation.z = deg_to_rad(max(rad_to_deg(rotation.z) - (ManuverSpeed * 2), 0))
		if (rotation.z < 0):
			rotation.z = deg_to_rad(min(rad_to_deg(rotation.z) + (ManuverSpeed * 2), 0))
	if (Input.is_action_pressed("MoveUp") and position.y < 3):
		rotation.x = deg_to_rad(max(rad_to_deg(rotation.x) - ManuverSpeed, -30))
		position.y = min(3, position.y + 0.1)
	else :if (Input.is_action_pressed("MoveDown") and position.y > -3):
		rotation.x = deg_to_rad(min(rad_to_deg(rotation.x) + ManuverSpeed, 30))
		position.y = max(-3, position.y - 0.1)
	else :
		if (rotation.x > 0):
			rotation.x = deg_to_rad(max(rad_to_deg(rotation.x) - (ManuverSpeed * 2), 0))
		if (rotation.x < 0):
			rotation.x = deg_to_rad(min(rad_to_deg(rotation.x) + (ManuverSpeed * 2), 0))
