@tool
extends BaseDialogueNode

class_name VillageLocatorOptionDialogueNode

@export var resourceLoc : EditorResourcePicker
@export var spinB : SpinBox

var option : Village_Locator_Happening_Option

func ConfigureOption(options : Village_Locator_Happening_Option) -> void:
	resourceLoc.edited_resource = options
	option = options
	spinB.set_value_no_signal(options.locatorRange)

func _on_editor_resource_picker_resource_changed(resource: Resource) -> void:
	ConfigureOption(resource)


func _on_spin_box_value_changed(value: float) -> void:
	option.locatorRange = value


func _on_editor_resource_picker_resource_selected(resource: Resource, inspect: bool) -> void:
	EditorInterface.edit_resource(resource)
