extends Node
class_name UISoundMan
@export var ClickSound : AudioStream
@export var HoverShound : AudioStream

var Sounds : Array[AudioStreamPlayer] = []

static var Instance : UISoundMan
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var player1 = AudioStreamPlayer.new()
	player1.stream = ClickSound
	player1.bus = "UI"
	add_child(player1)
	Sounds.append(player1)
	var player2 = AudioStreamPlayer.new()
	player2.volume_db = -5
	player2.stream = HoverShound
	player2.bus = "UI"
	add_child(player2)
	Sounds.append(player2)
	Instance = self
	Refresh()

static func GetInstance() -> UISoundMan:
	return Instance

func Refresh():
	var buttons = get_tree().get_nodes_in_group("Buttons")
	for g in buttons.size():
		if (buttons[g].is_connected("mouse_entered", OnButtonHovered)):
			continue
		buttons[g].connect("mouse_entered", OnButtonHovered);
		buttons[g].connect("focus_entered", OnButtonHovered);
		buttons[g].connect("button_down", OnButtonClicked);
func OnButtonHovered():
	Sounds[1].playing = true
func OnButtonClicked():
	Sounds[0].playing = true
