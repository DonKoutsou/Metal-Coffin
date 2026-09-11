@tool
extends BaseDialogueNode

class_name OptionDialogueNode

@export var worldViewSet : WorldViewSetting
@export var worldvewCheckSet : WorldViewCheckSetting
@export var textInput : TextEdit
@export var text2 : TextEdit

var option : Happening_Option

func ConfigureOption(options : Happening_Option) -> void:
	worldViewSet.SetWorldView(options.WorldviewEffect, options.WorldviewEffectAmm)
	option = options
	
	textInput.text = options.OptionName
	
	if (options is String_Happening_Option):
		text2.text = options.StringReply
	else:
		$VBoxContainer/Label2.visible = false
		text2.visible = false
	
	if (options.WorldviewCheck !=  WorldView.WorldViews.NONE):
		print("Thing")
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
