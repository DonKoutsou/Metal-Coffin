@tool
extends EditorPlugin

class_name CaptainCreator

var Dock
var Dock2

func _enter_tree():
	# Initialization of the plugin goes here.
	# Add the new type with a name, a parent type, a script and an icon.
	#add_custom_type("MyButton", "Button", preload("res://CaptainCreator/CaptainCreatorUI.gd"), preload("res://Assets/CaptainPortraits/Captain11.png"))
	Dock = preload("res://addons/cptcreator/CaptainCreatorUI.tscn").instantiate()
	Dock2 = preload("res://addons/cptcreator/ship_part_editor.tscn").instantiate()
	add_dock(Dock)
	add_dock(Dock2)

func _exit_tree():
	remove_dock(Dock)
	remove_dock(Dock2)
	# Erase the control from the memory.
	Dock.free()
	Dock2.free()
