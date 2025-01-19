extends Control

class_name SpotMarker

@export var SpotNameLabel : Label
@export var SpotDropPosition : Control
@export var NofiticationScene : PackedScene

var TimeLastSeen : float

func SetMarkerDetails(Spot : MapSpot, PlayAnim : bool):
	if (PlayAnim):
		if (Spot.SpotType.GetEnumString() == "SUB_STATION"):
			Ingame_UIManager.GetInstance().PlayDiag(["Operator, we are aproaching a sub-station.","I'd recomend visiting it to look for supplies or any clues regarding the collapse."])
		if (!Spot.Seen):
			$AnimationPlayer.play("SpotFound")
			PlaySound()
	SpotNameLabel.text = Spot.SpotInfo.SpotName
	for g in Spot.SpotInfo.PossibleDrops:
		var text = TextureRect.new()
		text.texture = g.ItemIconSmol
		if (g is UsableItem):
			text.self_modulate = g.ItecColor
		text.use_parent_material = true
		SpotDropPosition.add_child(text)
	SpotDropPosition.pivot_offset.y = SpotDropPosition.size.y

func PlaySound():
	var sound = AudioStreamPlayer2D.new()
	sound.bus = "MapSounds"
	sound.volume_db = 10
	sound.stream = load("res://Assets/Sounds/radar-beeping-sound-effect-192404.mp3")
	add_child(sound)
	sound.play()


func UpdateCameraZoom(NewZoom : float) -> void:
	SpotDropPosition.scale = Vector2(1,1) / NewZoom

func _on_visible_on_screen_notifier_2d_screen_entered() -> void:
	$AnalyzeButton.add_to_group("UnmovableMapInfo")
	SpotNameLabel.add_to_group("UnmovableMapInfo")
	

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	$AnalyzeButton.remove_from_group("UnmovableMapInfo")
	SpotNameLabel.remove_from_group("UnmovableMapInfo")
