extends Control

class_name FlightManual

@export var FlightManualEntries : Array[FlightManualEntry]

func _ready() -> void:
	for g in FlightManualEntries:
		var b = Button.new()
		b.text = g.EntryName
		b.connect("pressed", EntryPressed.bind(g))
		$HBoxContainer/VBoxContainer/PanelContainer2/ScrollContainer/VBoxContainer.add_child(b)
	
func EntryPressed(Entry : FlightManualEntry) -> void:
	$HBoxContainer/PanelContainer/ScrollContainer/VBoxContainer/Label.text = Entry.EntryName
	$HBoxContainer/PanelContainer/ScrollContainer/VBoxContainer/RichTextLabel.text = Entry.EntryDesc


func _on_button_pressed() -> void:
	visible = false


func _on_scroll_container_gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseMotion and Input.is_action_pressed("Click")):
		$HBoxContainer/PanelContainer/ScrollContainer.scroll_vertical -= event.relative.y


func _on_scroll2_container_gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseMotion and Input.is_action_pressed("Click")):
		$HBoxContainer/VBoxContainer/PanelContainer2/ScrollContainer.scroll_vertical -= event.relative.y
