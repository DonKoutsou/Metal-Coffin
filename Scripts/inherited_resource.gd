##Taken from https://codeberg.org/MajorMcDoom/cozy-cube-godot-addons/
@tool
extends Resource

class_name InheritedResource

const NON_OVERRIDABLE_PROPERTY_NAMES: Array[StringName] = [
		&"_property_overrides",
		&"base_resource",
		&"clear_property_overrides_button",
		&"resource_local_to_scene",
		&"resource_path",
		&"resource_name",
		&"script"]

@export var _property_overrides: Dictionary[StringName, bool]
@export var base_resource: Resource:
	get: return base_resource
	set(value):
		if base_resource == value:
			return
		if value and value.get_class() != get_class():
			return
		if base_resource:
			base_resource.changed.disconnect(_resolve_property_overrides)
		base_resource = value
		_base_properties.clear()
		if base_resource:
			for prop in base_resource.get_property_list():
				if prop.name not in NON_OVERRIDABLE_PROPERTY_NAMES and\
						prop.usage & PROPERTY_USAGE_DEFAULT != 0:
					_base_properties[prop.name] = true
			base_resource.changed.connect(_resolve_property_overrides)
		emit_changed()
		notify_property_list_changed()
@export_tool_button("Clear Property Overrides", "Clear") var clear_property_overrides_button := _clear_property_overrides

var _base_properties: Dictionary[StringName, bool]
var _is_resolving_base_properties: bool


func _reset_state() -> void:

	_base_properties.clear()
	_is_resolving_base_properties = false


func _get_property_list() -> Array[Dictionary]:

	_resolve_property_overrides()
	return []


func _validate_property(property: Dictionary) -> void:

	match property.name:
		"_property_overrides":
			property.usage = PROPERTY_USAGE_STORAGE
		"base_resource":
			property.hint = PROPERTY_HINT_RESOURCE_TYPE
			property.hint_string = get_class()
		"clear_property_overrides_button":
			if not base_resource:
				property.usage = PROPERTY_USAGE_NONE


func _set(prop_name: StringName, value: Variant) -> bool:

	if not _is_resolving_base_properties and _base_properties.has(prop_name):
		var base_value = base_resource.get(prop_name)
		if value == base_value:
			if _property_overrides.has(prop_name):
				_property_overrides.erase(prop_name)
		else:
			_property_overrides[prop_name] = true
		emit_changed()
	return false


func _property_can_revert(prop_name: StringName) -> bool:

	return _base_properties.has(prop_name)


func _property_get_revert(prop_name: StringName) -> Variant:

	return base_resource.get(prop_name)


func _clear_property_overrides() -> void:

	var ur = Engine.get_singleton(&"EditorInterface").get_editor_undo_redo()
	ur.create_action("Clear Property Overrides")

	for prop_name in _property_overrides.keys():
		ur.add_do_property(self, prop_name, base_resource.get(prop_name))
		ur.add_undo_property(self, prop_name, get(prop_name))
	_property_overrides.clear()

	ur.commit_action()


func _resolve_property_overrides() -> void:

	if _is_resolving_base_properties:
		return
	_is_resolving_base_properties = true

	var did_change: bool
	for prop_name in _base_properties.keys():
		var value = get(prop_name)
		var base_value = base_resource.get(prop_name)
		if value != base_value:
			if not _property_overrides.has(prop_name):
				set(prop_name, base_value)
				did_change = true
	if did_change:
		emit_changed()

	_is_resolving_base_properties = false
