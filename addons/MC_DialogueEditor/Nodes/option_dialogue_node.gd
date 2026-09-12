@tool
extends BaseDialogueNode

class_name OptionDialogueNode

@export var worldViewSet : WorldViewSetting
@export var worldvewCheckSet : WorldViewCheckSetting
@export var resPicker : EditorResourcePicker
@export var textInput : TextEdit
@export var text2 : TextEdit

var option : Happening_Option

var currentlyUpdating : bool = false

func ConfigureOption(options : Happening_Option) -> void:
	resPicker.edited_resource = options
	worldViewSet.SetWorldView(options.WorldviewEffect, options.WorldviewEffectAmm)
	option = options
	option.changed.connect(OptionChanged.bind(option))
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

func OptionChanged(opt : Happening_Option) -> void:
	if (currentlyUpdating):
		return
	print("thing")
	currentlyUpdating = true
	textInput.text = opt.OptionName
	text2.text = option.StringReply
	worldViewSet.SetWorldView(opt.WorldviewEffect, opt.WorldviewEffectAmm)
	worldvewCheckSet.SetWorldViewCheck(opt)
	currentlyUpdating = false

func _on_text_edit_text_changed() -> void:
	var newText = textInput.text
	currentlyUpdating = true
	option.OptionName = newText
	currentlyUpdating = false

	Changed.emit()

func _on_text_edit_2_text_changed() -> void:
	var newText = text2.text
	
	
	currentlyUpdating = true
	option.StringReply = newText
	currentlyUpdating = false
	
	Changed.emit()


func _on_editor_resource_picker_resource_changed(resource: Resource) -> void:
	if (option == null):
		ConfigureOption(resource)
	else:
		var opt : Happening_Option = resource
		opt.OptionName = option.OptionName
		opt.FinishDiag = option.FinishDiag
		opt.Event = option.Event
		opt.Branch = option.Branch
		opt.WorldviewEffect = option.WorldviewEffect
		opt.WorldviewEffectAmm = option.WorldviewEffectAmm
		opt.WorldviewCheck = option.WorldviewCheck
		opt.CheckPossetive = option.CheckPossetive
		opt.CheckDifficulty = option.CheckDifficulty
		opt.WorldViewFailBranch = option.WorldViewFailBranch
		opt.ReverseEffectOnFail = option.ReverseEffectOnFail
		
		if (opt is String_Happening_Option and option is String_Happening_Option):
			opt.StringReply = option.StringReply
		ConfigureOption(opt)


func _on_world_view_setting_effect_ammount_changed(newAmm: int) -> void:
	option.WorldviewEffectAmm = newAmm
	
	currentlyUpdating = true
	option.emit_changed()
	currentlyUpdating = false
	
	Changed.emit()


func _on_world_view_setting_world_view_changed(newWorldView: WorldView.WorldViews) -> void:
	option.WorldviewEffect = newWorldView
	
	currentlyUpdating = true
	option.emit_changed()
	currentlyUpdating = false
	
	Changed.emit()


func _on_world_view_setting_2_worldview_check_ammount_changed(newAmm: float) -> void:
	option.CheckDifficulty = newAmm
	
	currentlyUpdating = true
	option.emit_changed()
	currentlyUpdating = false
	
	Changed.emit()


func _on_world_view_setting_2_worldview_check_changed(newType: WorldView.WorldViews) -> void:
	option.WorldviewCheck = newType
	
	currentlyUpdating = true
	option.emit_changed()
	currentlyUpdating = false
	
	Changed.emit()


func _on_editor_resource_picker_resource_selected(resource: Resource, inspect: bool) -> void:
	EditorInterface.edit_resource(resource)


func _on_option_picker_resource_selected(resource: Resource, inspect: bool) -> void:
	EditorInterface.edit_resource(resource)
