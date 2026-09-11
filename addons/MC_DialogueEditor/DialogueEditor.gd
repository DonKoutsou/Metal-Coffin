@tool
extends EditorPlugin

class_name DialogueEditorPlugin

var Dock : Node

func _enter_tree():
	# Initialization of the plugin goes here.
	# Add the new type with a name, a parent type, a script and an icon.
	#add_custom_type("MyButton", "Button", preload("res://CaptainCreator/CaptainCreatorUI.gd"), preload("res://Assets/CaptainPortraits/Captain11.png"))
	Dock = preload("res://addons/MC_DialogueEditor/DialogueEditor.tscn").instantiate()
	
	EditorInterface.get_editor_main_screen().add_child(Dock)
	Dock.visible = false

func _get_plugin_name():
	return "Dialogue Editor"

func _get_plugin_icon():
	return EditorInterface.get_editor_theme().get_icon("Node", "EditorIcons")

func _exit_tree():
	# Erase the control from the memory.
	Dock.free()

func _has_main_screen():
	return true


func _make_visible(visible):
	if Dock:
		Dock.visible = visible
