extends PanelContainer

class_name InventoryUI

signal OnUiToggled(t)

func _ready() -> void:
	ToggleUI(false)

func ToggleUI(t : bool) -> void:
	visible = t
	OnUiToggled.emit(!t)
	#Map.GetInstance().OnScreenUiToggled(!t)
