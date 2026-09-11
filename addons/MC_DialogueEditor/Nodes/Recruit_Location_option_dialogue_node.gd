@tool
extends BaseDialogueNode

class_name RecruitLocatorOptionDialogueNode

@export var resourceLoc : EditorResourcePicker

var option : Recruit_Locator_Happening_Option

func ConfigureOption(options : Recruit_Locator_Happening_Option) -> void:
	resourceLoc.edited_resource = options
	option = options

func _on_editor_resource_picker_resource_changed(resource: Resource) -> void:
	ConfigureOption(resource)
