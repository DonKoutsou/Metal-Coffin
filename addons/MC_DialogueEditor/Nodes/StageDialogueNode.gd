@tool
extends BaseDialogueNode

class_name StageDialogueNode

@export var resPicker : EditorResourcePicker
@export var textInput : TextEdit
@export var rich : RichTextLabel
@export var PicPicket : EditorResourcePicker

var text : HappeningText
var stage : HappeningStage
var textIndex : int

var currentlyChanging : bool = false

func ConfigureStage(st : HappeningStage, textI : int) -> void:
	resPicker.edited_resource = st
	stage = st
	textIndex = textI
	textInput.text = st.Texts[textI].Text
	rich.text = st.Texts[textI].Text
	text = st.Texts[textI]
	text.changed.connect(TextChanged.bind(text))
	if (text.Pic != ""):
		PicPicket.edited_resource = load(text.Pic)

func TextChanged(t : HappeningText) -> void:
	if (currentlyChanging):
		return
	textInput.text = t.Text
	rich.text = t.Text

func _on_text_edit_text_changed() -> void:
	var newText = textInput.text
	text.Text = newText
	rich.text = newText
	
	currentlyChanging = true
	text.emit_changed()
	currentlyChanging = false
	
	if (stage == null):
		return
	stage.Texts[textIndex].Text = newText
	
	Changed.emit()


func _on_editor_resource_picker_resource_changed(resource: Resource) -> void:
	text.Pic = resource.resource_path
	Changed.emit()


func _on_res_picker_resource_changed(resource: Resource) -> void:
	var st : HappeningStage = resource
	if (stage == null):
		var t : Array[HappeningText] = []
		t.append(HappeningText.new())
		st.Texts = t
		ConfigureStage(resource, 0)
	else:
		st.Texts = stage.Texts
		st.Options = stage.Options
		ConfigureStage(st, textIndex)


func _on_editor_resource_picker_resource_selected(resource: Resource, inspect: bool) -> void:
	EditorInterface.edit_resource(resource)


func _on_res_picker_resource_selected(resource: Resource, inspect: bool) -> void:
	EditorInterface.edit_resource(resource)
