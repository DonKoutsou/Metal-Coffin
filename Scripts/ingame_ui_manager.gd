extends CanvasLayer
class_name Ingame_UIManager

static var Instance :Ingame_UIManager
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Instance = self
static func GetInstance() -> Ingame_UIManager:
	return Instance
