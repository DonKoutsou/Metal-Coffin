@tool
extends PanelContainer

class_name WorldViewSetting

@export var menu : PopupMenu
@export var valueLabel : Label
@export var slid : HSlider

func _ready() -> void:
	for g in WorldView.WorldViews.keys():
		menu.add_item(g)
	menu.title = WorldView.WorldViews.keys()[0]

func SetWorldView(view : WorldView.WorldViews, amm : float) -> void:
	menu.title = WorldView.WorldViews.keys()[view]
	slid.value = amm
	valueLabel.text = var_to_str(amm)

func _on_popup_menu_index_pressed(index: int) -> void:
	menu.title = WorldView.WorldViews.keys()[index]


func _on_h_slider_value_changed(value: float) -> void:
	valueLabel.text = var_to_str(value)
	
