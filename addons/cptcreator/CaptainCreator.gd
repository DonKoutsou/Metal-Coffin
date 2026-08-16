@tool
extends EditorPlugin

class_name CaptainCreator

var Dock

func _enter_tree():
	# Initialization of the plugin goes here.
	# Add the new type with a name, a parent type, a script and an icon.
	#add_custom_type("MyButton", "Button", preload("res://CaptainCreator/CaptainCreatorUI.gd"), preload("res://Assets/CaptainPortraits/Captain11.png"))
	Dock = preload("res://addons/cptcreator/CaptainCreatorUI.tscn").instantiate()
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, Dock)

func _exit_tree():
	
	remove_control_from_docks(Dock)
	# Erase the control from the memory.
	Dock.free()
