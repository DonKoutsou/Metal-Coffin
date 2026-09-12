@tool
extends BaseDialogueNode

class_name StageDialogueNode

@export var resPicker : EditorResourcePicker
@export var textPicket : EditorResourcePicker
@export var textInput : TextEdit
@export var rich : RichTextLabel
@export var PicPicket : EditorResourcePicker

var text : HappeningText
var stage : HappeningStage

var currentlyChanging : bool = false

#------------------------------------------------------------------------
func ConfigureStage(st : HappeningStage, t : HappeningText) -> void:
	if (text != t):
		text = t
		text.changed.connect(TextChanged.bind(text))
		textPicket.edited_resource = text
	
	if (stage != st):
		stage = st
		resPicker.edited_resource = st

	textInput.text = text.Text
	rich.text = text.Text
	
	if (text.Pic != ""):
		PicPicket.edited_resource = load(text.Pic)

#------------------------------------------------------------------------
func TextChanged(t : HappeningText) -> void:
	if (currentlyChanging):
		return
		
	print("thing")
	textInput.text = t.Text
	rich.text = t.Text

#------------------------------------------------------------------------
func _on_text_edit_text_changed() -> void:
	var newText = textInput.text
	currentlyChanging = true
	text.Text = newText
	rich.text = newText
	currentlyChanging = false

	Changed.emit()

#------------------------------------------------------------------------
func _on_editor_resource_picker_resource_changed(resource: Resource) -> void:
	text.Pic = resource.resource_path
	Changed.emit()

#------------------------------------------------------------------------
func _on_res_picker_resource_changed(resource: Resource) -> void:
	ConfigureStage(resource, text)
	Changed.emit()

#------------------------------------------------------------------------
func _on_text_picket_resource_changed(resource: Resource) -> void:
	ConfigureStage(stage, resource)
	Changed.emit()

#------------------------------------------------------------------------
func _on_editor_resource_picker_resource_selected(resource: Resource, inspect: bool) -> void:
	EditorInterface.edit_resource(resource)

#------------------------------------------------------------------------
func _on_res_picker_resource_selected(resource: Resource, inspect: bool) -> void:
	EditorInterface.edit_resource(resource)

#------------------------------------------------------------------------
func _on_text_picket_resource_selected(resource: Resource, inspect: bool) -> void:
	EditorInterface.edit_resource(resource)
