@tool
extends PanelContainer

class_name WorldViewCheckSetting

@export var menu : PopupMenu
@export var valueLabel : Label
@export var slid : HSlider
@export var possitiveCheckBox : CheckBox

func _ready() -> void:
	for g in WorldView.WorldViews.keys():
		menu.add_item(g)
	menu.title = WorldView.WorldViews.keys()[0]

func SetWorldViewCheck(option : Happening_Option) -> void:
	menu.title = WorldView.WorldViews.keys()[option.WorldviewCheck]
	possitiveCheckBox.set_pressed_no_signal(option.CheckPossetive)
	slid.value = option.CheckDifficulty
	valueLabel.text = var_to_str(option.CheckDifficulty)

func _on_popup_menu_index_pressed(index: int) -> void:
	menu.title = WorldView.WorldViews.keys()[index]


func _on_h_slider_value_changed(value: float) -> void:
	valueLabel.text = var_to_str(value)
	


func _on_check_box_pressed() -> void:
	pass # Replace with function body.
