@tool
extends BaseDialogueNode

class_name OptionDialogueNode

@export var worldViewSet : WorldViewSetting
@export var worldvewCheckSet : WorldViewCheckSetting
@export var resPicker : EditorResourcePicker
@export var textInput : TextEdit
@export var text2 : TextEdit

var option : Happening_Option

func ConfigureOption(options : Happening_Option) -> void:
	resPicker.edited_resource = options
	worldViewSet.SetWorldView(options.WorldviewEffect, options.WorldviewEffectAmm)
	option = options
	
	textInput.text = option.OptionName
	
	if (options is String_Happening_Option):
		text2.text = options.StringReply
	else:
		$VBoxContainer/Label2.visible = false
		text2.visible = false
	
	if (options.WorldviewCheck !=  WorldView.WorldViews.NONE):
		add_child(Control.new())
		set_slot(1, false, 0, Color(1,1,1), true, 0, Color(1,0,0))
		worldvewCheckSet.SetWorldViewCheck(options)


func _on_text_edit_text_changed() -> void:
	var newText = textInput.text
	option.OptionName = newText
	Changed.emit()

func _on_text_edit_2_text_changed() -> void:
	var newText = text2.text
	option.StringReply = newText
	Changed.emit()


func _on_editor_resource_picker_resource_changed(resource: Resource) -> void:
	ConfigureOption(resource)


func _on_world_view_setting_effect_ammount_changed(newAmm: int) -> void:
	option.WorldviewEffectAmm = newAmm
	Changed.emit()


func _on_world_view_setting_world_view_changed(newWorldView: WorldView.WorldViews) -> void:
	option.WorldviewEffect = newWorldView
	Changed.emit()
