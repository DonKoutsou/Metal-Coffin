@tool
extends OptionDialogueNode

class_name DroneOptionDialogueNode

@export var DronePicker : EditorResourcePicker

func ConfigureOption(options : Happening_Option) -> void:
	super(options)
	var op : Drone_Happening_Option = options
	DronePicker.edited_resource = op.Cpt


func _on_dron_picker_resource_changed(resource: Resource) -> void:
	var op : Drone_Happening_Option = option
	op.Cpt = resource
	Changed.emit()


func _on_dron_picker_resource_selected(resource: Resource, inspect: bool) -> void:
	EditorInterface.edit_resource(resource)
