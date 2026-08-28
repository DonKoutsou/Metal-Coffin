extends Node
class_name UISoundMan
@export var ClickSound : AudioStream
@export var ClickSound2 : AudioStream
@export var ClickOutSound : AudioStream
@export var ClickOutSound2 : AudioStream
@export var DigitalClick : AudioStream
@export var HoverShound : AudioStream
@export var AnalogueSoundStr : float = 0
@export var DigitalSoundStr : float = 0
var Sounds : Array[AudioStreamPlayer] = []

static var Instance : UISoundMan
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var player1 : AudioStreamPlayer = AudioStreamPlayer.new()
	player1.volume_db = AnalogueSoundStr
	player1.stream = ClickSound
	player1.bus = "MapSounds"
	add_child(player1)
	Sounds.append(player1)
	
	var player2 : AudioStreamPlayer  = AudioStreamPlayer.new()
	player2.volume_db = AnalogueSoundStr
	player2.stream = ClickOutSound
	player2.bus = "MapSounds"
	add_child(player2)
	Sounds.append(player2)
	
	var player3 : AudioStreamPlayer  = AudioStreamPlayer.new()
	player3.volume_db = DigitalSoundStr
	player3.stream = DigitalClick
	player3.bus = "UI"
	add_child(player3)
	Sounds.append(player3)
	
	var player4 : AudioStreamPlayer  = AudioStreamPlayer.new()
	player4.volume_db = DigitalSoundStr
	#player4.volume_db = -5
	player4.stream = HoverShound
	player4.bus = "UI"
	add_child(player4)
	Sounds.append(player4)
	
	var player5 : AudioStreamPlayer = AudioStreamPlayer.new()
	player5.volume_db = AnalogueSoundStr
	player5.stream = ClickSound2
	player5.bus = "MapSounds"
	add_child(player5)
	Sounds.append(player5)
	
	var player6 : AudioStreamPlayer  = AudioStreamPlayer.new()
	player6.volume_db = AnalogueSoundStr
	player6.stream = ClickOutSound2
	player6.bus = "MapSounds"
	add_child(player6)
	Sounds.append(player6)
	
	Instance = self
	Refresh()

static func GetInstance() -> UISoundMan:
	return Instance

func AddSelf(But : Control) -> void:
	# ANALOGUE BUTTONS
	if (But.is_in_group("Buttons")):
		if (But.is_connected("button_down", PlayButton.bind(0))):
			return
		But.connect("button_down", PlayButton.bind(0))
		if (But is BaseButton and But.toggle_mode == true):
			return
		But.connect("button_up", PlayButton.bind(1))
	
	if (But.is_in_group("Buttons2")):
		if (But.is_connected("button_down", PlayButton.bind(4))):
			return
		But.connect("button_down", PlayButton.bind(4))
		if (But is BaseButton and But.toggle_mode == true):
			return
		But.connect("button_up", PlayButton.bind(5))
		
	# DIGITAL BUTTONS
	if (But.is_in_group("DigitalButtons")):
		if (But.is_connected("button_down", PlayButton.bind(2))):
			return
		But.pivot_offset = But.size/2
		But.connect("button_down", PlayButton.bind(2))
		But.mouse_entered.connect(PlayButton.bind(3))
		But.mouse_exited.connect(OnButtonHoverEnded)
	# DIGITAL BUTTONS WITH BOUNCE ON HOVER
	if (But.is_in_group("DigitalBouncingButton")):
		if (But.is_connected("button_down", PlayButton.bind(2))):
			return
		But.pivot_offset = But.size/2
		But.connect("button_down", PlayButton.bind(2))
		But.mouse_entered.connect(OnBouncingButtonHovered.bind(But))
		But.mouse_exited.connect(OnBouncingButtonHoverEnded.bind(But))

func RemoveSelf(But : Control) -> void:
	# ANALOGUE BUTTONS
	if (But.is_in_group("Buttons")):
		if (!But.is_connected("button_down", PlayButton.bind(0))):
			return
		But.disconnect("button_down", PlayButton.bind(0))
		if (But is BaseButton and But.toggle_mode == true):
			return
		But.disconnect("button_up", PlayButton.bind(1))
	
	if (But.is_in_group("Buttons2")):
		if (!But.is_connected("button_down", PlayButton.bind(4))):
			return
		But.disconnect("button_down", PlayButton.bind(4))
		if (But is BaseButton and But.toggle_mode == true):
			return
		But.disconnect("button_up", PlayButton.bind(5))
	
	# DIGITAL BUTTONS
	if (But.is_in_group("DigitalButtons")):
		if (!But.is_connected("button_down", PlayButton.bind(2))):
			return
		But.disconnect("button_down", PlayButton.bind(2))
		But.mouse_entered.disconnect(PlayButton.bind(2))
		But.mouse_exited.disconnect(OnButtonHoverEnded)
	
	# DIGITAL BUTTONS WITH BOUNCE ON HOVER
	if (But.is_in_group("DigitalBouncingButton")):
		if (!But.is_connected("button_down", PlayButton.bind(2))):
			return
		But.disconnect("button_down", PlayButton.bind(2))
		But.mouse_entered.disconnect(OnBouncingButtonHovered)
		But.mouse_exited.disconnect(OnBouncingButtonHoverEnded)

func Refresh() -> void:
	var buttons : Array[Node] = get_tree().get_nodes_in_group("Buttons")
	
	for g in buttons.size():
		var But = buttons[g]
		if (But.is_connected("button_down", PlayButton.bind(0))):
			continue
		
		But.connect("button_down", PlayButton.bind(0))
		if (But is BaseButton and But.toggle_mode == true):
			continue
		But.connect("button_up", PlayButton.bind(1))
	
	var buttons2 : Array[Node] = get_tree().get_nodes_in_group("Buttons2")
	
	for g in buttons2.size():
		var But = buttons2[g]
		if (But.is_connected("button_down", PlayButton.bind(4))):
			continue
		
		But.connect("button_down", PlayButton.bind(4))
		if (But is BaseButton and But.toggle_mode == true):
			continue
		But.connect("button_up", PlayButton.bind(5))
		
	var Digibuttons : Array[Node] = get_tree().get_nodes_in_group("DigitalButtons")
	
	for g  in Digibuttons.size():
		var DigitalButton : Control = Digibuttons[g]
		if (DigitalButton.is_connected("button_down", PlayButton.bind(2))):
			continue
			
		DigitalButton.connect("button_down", PlayButton.bind(2))
		
		DigitalButton.mouse_entered.connect(PlayButton.bind(2))
		DigitalButton.mouse_exited.connect(OnButtonHoverEnded)
		#Digibuttons[g].connect("focus_entered", OnButtonHovered);
	
	var DigiBouncingbuttons : Array[Node] = get_tree().get_nodes_in_group("DigitalBouncingButton")
	
	for g  in DigiBouncingbuttons.size():
		var DigitalButton : Control = DigiBouncingbuttons[g]
		if (DigitalButton.is_connected("button_down", PlayButton.bind(2))):
			continue
			
		DigitalButton.connect("button_down", PlayButton.bind(2))
		
		DigitalButton.mouse_entered.connect(OnBouncingButtonHovered.bind(DigitalButton))
		DigitalButton.mouse_exited.connect(OnBouncingButtonHoverEnded.bind(DigitalButton))
		#Digibuttons[g].connect("focus_entered", OnButtonHovered);

func OnBouncingButtonHovered(But : Control) -> void:
	Sounds[3].playing = true
	But.pivot_offset = But.size / 2
	var tw : Tween = create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_BACK)
	tw.tween_property(But, "scale", Vector2(1.02,1.1), 0.25)
	#But.scale = Vector2(1.1, 1.1)
	But.z_index = 1

func OnBouncingButtonHoverEnded(But : Control) -> void:
	var tw :Tween = create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_BACK)
	tw.tween_property(But, "scale", Vector2(1,1), 0.25)
	#But.scale = Vector2(1, 1)
	But.z_index = 0
	
func OnButtonHoverEnded() -> void:
	pass

func PlayButton(buttonIndex : int) -> void:
	Sounds[buttonIndex].playing = true
