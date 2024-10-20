extends TouchScreenButton
@export var buttontext : String

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var lab = get_node("Label") as Label
	lab.text = buttontext
	pass # Replace with function body.
