@tool
extends BaseDialogueNode

class_name StageDialogueNode

@export var textInput : TextEdit
@export var rich : RichTextLabel
@export var PicPicket : EditorResourcePicker

var text : HappeningText
var stage : HappeningStage
var textIndex : int

func ConfigureStage(st : HappeningStage, textI : int) -> void:
	stage = st
	textIndex = textI
	textInput.text = st.Texts[textI].Text
	rich.text = st.Texts[textI].Text
	text = st.Texts[textI]
	if (text.Pic != ""):
		PicPicket.edited_resource = load(text.Pic)

func _on_text_edit_text_changed() -> void:
	var newText = textInput.text
	rich.text = newText
	text.Text = newText
	if (stage == null):
		return
	stage.Texts[textIndex] = newText
	
	Changed.emit()


func _on_editor_resource_picker_resource_changed(resource: Resource) -> void:
	text.Pic = resource.resource_path
	Changed.emit()
