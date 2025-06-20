extends Control

class_name FlightManual

@export var FlightManualEntries : Array[FlightManualEntry]
@export var EntryNameLabel : Label
@export var EntryLabel : RichTextLabel
@export var EntryButtonLocation : Control

func _ready() -> void:
	for g in FlightManualEntries:
		var b = Button.new()
		b.text = g.EntryName
		b.connect("pressed", EntryPressed.bind(g))
		EntryButtonLocation.add_child(b)
	
func EntryPressed(Entry : FlightManualEntry) -> void:
	EntryNameLabel.text = Entry.EntryName
	EntryLabel.text = Entry.EntryDesc


func _on_button_pressed() -> void:
	visible = false
