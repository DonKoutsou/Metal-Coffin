extends PanelContainer

class_name Text_Spin_Box

@export var options : PackedStringArray
@export var label : Label

signal OptionPicked(index : int)

var currentlySelected : int = 0

func _ready() -> void:
	if (!options.is_empty()):
		UpdateLabel()

func SetSelected(index : int) -> void:
	currentlySelected = index
	UpdateLabel()

func AddOption(option : String) -> void:
	options.append(option)

func UpdateLabel() -> void:
	label.text = options[currentlySelected]

func _on_next_pressed() -> void:
	currentlySelected = wrap(currentlySelected + 1, 0, options.size())
	OptionPicked.emit(currentlySelected)
	UpdateLabel()

func _on_previous_pressed() -> void:
	currentlySelected = wrap(currentlySelected - 1, 0, options.size())
	OptionPicked.emit(currentlySelected)
	UpdateLabel()
