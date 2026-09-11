@tool
extends BaseDialogueNode

class_name VillageLocatorOptionDialogueNode

@export var resourceLoc : EditorResourcePicker

var option : Village_Locator_Happening_Option

func ConfigureOption(options : Village_Locator_Happening_Option) -> void:
	resourceLoc.edited_resource = options
	option = options

func _on_editor_resource_picker_resource_changed(resource: Resource) -> void:
	ConfigureOption(resource)
