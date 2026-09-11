@tool
extends BaseDialogueNode

class_name StageDialogueNode

@export var textInput : TextEdit
@export var rich : RichTextLabel
@export var PicPicket : EditorResourcePicker

var stage : HappeningStage
var textIndex : int

func ConfigureStage(st : HappeningStage, textI : int) -> void:
	stage = st
	textIndex = textI
	textInput.text = st.HappeningTexts[textI]
	rich.text = st.HappeningTexts[textI]
	if (st.StagePic != ""):
		PicPicket.edited_resource = load(st.StagePic)

func _on_text_edit_text_changed() -> void:
	var newText = textInput.text
	stage.HappeningTexts[textIndex] = newText
	rich.text = newText
	Changed.emit()


func _on_editor_resource_picker_resource_changed(resource: Resource) -> void:
	Changed.emit()
