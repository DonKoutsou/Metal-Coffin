@tool
extends EditorPlugin

class_name CaptainCreator

var Dock : Node
var Dock2 : Node

func _enter_tree():
	# Initialization of the plugin goes here.
	# Add the new type with a name, a parent type, a script and an icon.
	#add_custom_type("MyButton", "Button", preload("res://CaptainCreator/CaptainCreatorUI.gd"), preload("res://Assets/CaptainPortraits/Captain11.png"))
	Dock = preload("res://addons/cptcreator/CaptainCreatorUI.tscn").instantiate()
	Dock2 = preload("res://addons/cptcreator/ship_part_editor.tscn").instantiate()
	#add_dock(Dock)
	
	#add_inspector_plugin(EDITOR_INSPECTOR_PLUGIN.new())

	#_registry_editor = REGISTRY_EDITOR_SCENE.instantiate()
	
	EditorInterface.get_editor_main_screen().add_child(Dock)
	Dock.visible = false
	
	add_dock(Dock2)

func _exit_tree():
	#remove_dock(Dock)
	remove_dock(Dock2)
	# Erase the control from the memory.
	Dock.free()
	Dock2.free()

func _has_main_screen():
	return true


func _make_visible(visible):
	if Dock:
		Dock.visible = visible


func _get_plugin_name():
	return "Captain Creator"


func _get_plugin_icon():
	return EditorInterface.get_editor_theme().get_icon("Node", "EditorIcons")
