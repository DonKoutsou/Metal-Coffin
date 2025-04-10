extends Node
class_name UISoundMan
@export var ClickSound : AudioStream
@export var ClickOutSound : AudioStream
@export var DigitalClick : AudioStream
@export var HoverShound : AudioStream
@export var AnalogueSoundStr : float = 0
@export var DigitalSoundStr : float = 0
var Sounds : Array[AudioStreamPlayer] = []

static var Instance : UISoundMan
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var player1 = AudioStreamPlayer.new()
	player1.volume_db = AnalogueSoundStr
	player1.stream = ClickSound
	player1.bus = "MapSounds"
	add_child(player1)
	Sounds.append(player1)
	var player2 = AudioStreamPlayer.new()
	player2.volume_db = AnalogueSoundStr
	player2.stream = ClickOutSound
	player2.bus = "MapSounds"
	add_child(player2)
	Sounds.append(player2)
	var player3 = AudioStreamPlayer.new()
	player3.volume_db = DigitalSoundStr
	player3.stream = DigitalClick
	player3.bus = "UI"
	add_child(player3)
	Sounds.append(player3)
	var player4 = AudioStreamPlayer.new()
	player4.volume_db = DigitalSoundStr
	#player4.volume_db = -5
	player4.stream = HoverShound
	player4.bus = "UI"
	add_child(player4)
	Sounds.append(player4)
	Instance = self
	Refresh()

static func GetInstance() -> UISoundMan:
	return Instance

func AddSelf(But : Button) -> void:
	if (But.is_in_group("Buttons")):
		if (But.is_connected("button_down", OnButtonClicked)):
			return
		But.connect("button_down", OnButtonClicked)
		But.connect("button_up", OnButtonReleased)
		
	if (But.is_in_group("DigitalButtons")):
		if (But.is_connected("button_down", OnDigitalButtonClicked)):
			return
		But.connect("button_down", OnDigitalButtonClicked)
		But.connect("mouse_entered", OnButtonHovered)

func RemoveSelf(But : Button) -> void:
	if (But.is_in_group("Buttons")):
		if (!But.is_connected("button_down", OnButtonClicked)):
			return
		But.disconnect("button_down", OnButtonClicked)
		But.disconnect("button_up", OnButtonReleased)
		
	if (But.is_in_group("DigitalButtons")):
		if (!But.is_connected("button_down", OnDigitalButtonClicked)):
			return
		But.disconnect("button_down", OnDigitalButtonClicked)
		But.disconnect("mouse_entered", OnButtonHovered)

func Refresh():
	var buttons = get_tree().get_nodes_in_group("Buttons")
	for g in buttons.size():
		if (buttons[g].is_connected("button_down", OnButtonClicked)):
			continue
		
		buttons[g].connect("button_down", OnButtonClicked)
		buttons[g].connect("button_up", OnButtonReleased)
	var Digibuttons = get_tree().get_nodes_in_group("DigitalButtons")
	for g in Digibuttons.size():
		if (Digibuttons[g].is_connected("button_down", OnDigitalButtonClicked)):
			continue
		Digibuttons[g].connect("button_down", OnDigitalButtonClicked)
		Digibuttons[g].connect("mouse_entered", OnButtonHovered)
		#Digibuttons[g].connect("focus_entered", OnButtonHovered);

func OnButtonHovered():
	Sounds[3].playing = true
func OnButtonClicked():
	Sounds[0].playing = true
	var rand = randf_range(0.9, 1.0)
	Sounds[0].pitch_scale = rand
	Sounds[0].volume_db = randf_range(AnalogueSoundStr -1, AnalogueSoundStr + 1.0)
func OnButtonReleased():
	Sounds[1].playing = true
	var rand = randf_range(0.9, 1.0)
	Sounds[1].pitch_scale = rand
	Sounds[1].volume_db = randf_range(AnalogueSoundStr -1, AnalogueSoundStr + 1.0)
func OnDigitalButtonClicked():
	Sounds[2].playing = true
