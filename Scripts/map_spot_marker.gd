extends Control

class_name SpotMarker

@export var NofiticationScene : PackedScene

var camera : Camera2D
var TimeLastSeen : float

func _ready() -> void:
	camera = ShipCamera.GetInstance()
	#$VBoxContainer.visible = false
	#set_physics_process(false)

#func ToggleShipDetails(T : bool):
	#$Control.visible = T
	#set_physics_process(T)

func SetMarkerDetails(Spot : MapSpot, PlayAnim : bool):
	if (PlayAnim):
		if (Spot.SpotType.GetEnumString() == "SUB_STATION"):
			Ingame_UIManager.GetInstance().PlayDiag(["Operator, we are aproaching a sub-station.","I'd recomend visiting it to look for supplies or any clues regarding the collapse."])
		if (!Spot.Seen):
			$AnimationPlayer.play("SpotFound")
			PlaySound()
	#$VBoxContainer/TextureRect.texture = Spot.SpotType.MapIcon
	$VBoxContainer/PanelContainer/TextureRect2.text = Spot.SpotName
	for g in Spot.SpotType.PossibleDrops:
		var text = TextureRect.new()
		text.texture = g.ItemIconSmol
		if (g is UsableItem):
			text.self_modulate = g.ItecColor
		text.use_parent_material = true
		$VBoxContainer/HBoxContainer.add_child(text)
	$VBoxContainer.pivot_offset.y = $VBoxContainer.size.y
	
#func OnSpotAnalyzed(PlayAnim : bool = true) ->void:
	#if (PlayAnim):
		#var notif = NofiticationScene.instantiate() as ShipMarkerNotif
		#notif.SetText("Location Analyzed")
		#add_child(notif)
		##notif.EntityToFollow = self
		#$AnimationPlayer.play("SpotAnalyzed")
		#PlaySound()
	#$VBoxContainer.visible = true
	#$VBoxContainer.pivot_offset.y = $VBoxContainer.size.y
	
func PlaySound():
	var sound = AudioStreamPlayer2D.new()
	sound.bus = "MapSounds"
	sound.volume_db = 10
	sound.stream = load("res://Assets/Sounds/radar-beeping-sound-effect-192404.mp3")
	add_child(sound)
	sound.play()
	
func _physics_process(_delta: float) -> void:
	$VBoxContainer.scale = Vector2(1,1) / camera.zoom

func _on_visible_on_screen_notifier_2d_screen_entered() -> void:
	$AnalyzeButton.add_to_group("UnmovableMapInfo")
	$VBoxContainer/PanelContainer/TextureRect2.add_to_group("UnmovableMapInfo")
	

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	$AnalyzeButton.remove_from_group("UnmovableMapInfo")
	$VBoxContainer/PanelContainer/TextureRect2.remove_from_group("UnmovableMapInfo")
