extends PanelContainer

class_name InventoryUI

static var Instance : InventoryUI
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Instance = self
static func GetInstance() -> InventoryUI:
	return Instance
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
func ToggleUI(t : bool) -> void:
	visible = t
	$"../../../../../../..".OnScreenUiToggled(!t)
