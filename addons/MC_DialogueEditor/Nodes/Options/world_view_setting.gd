@tool
extends PanelContainer

class_name WorldViewSetting

@export var menu : OptionButton
@export var valueLabel : Label
@export var slid : HSlider

signal WorldViewChanged(newWorldView : WorldView.WorldViews)
signal EffectAmmountChanged(newAmm : int)

func _ready() -> void:
	for g in WorldView.WorldViews.keys():
		menu.add_item(g)

func SetWorldView(view : WorldView.WorldViews, amm : float) -> void:
	menu.selected = view
	slid.set_value_no_signal(amm)
	valueLabel.text = var_to_str(amm)

func _on_popup_menu_index_pressed(index: int) -> void:
	WorldViewChanged.emit(index)

func _on_h_slider_value_changed(value: float) -> void:
	valueLabel.text = var_to_str(value)
	EffectAmmountChanged.emit(value)
	
