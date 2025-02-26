extends Control

class_name SpotMarker

@export var SpotNameLabel : Label
@export var SpotDropPosition : Control
@export var NofiticationScene : PackedScene

var TimeLastSeen : float

func SetMarkerDetails(Spot : MapSpot, PlayAnim : bool):
	if (PlayAnim):
		if (!Spot.Seen):
			$AnimationPlayer.play("SpotFound")
			PlaySound()
	SpotNameLabel.text = Spot.SpotInfo.SpotName
	for g in Spot.SpotInfo.PossibleDrops:
		var text = TextureRect.new()
		text.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		text.custom_minimum_size = Vector2(17,17)
		text.texture = g.ItemIcon
		#if (g is UsableItem):
			#text.self_modulate = g.ItecColor
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

func OnAlarmRaised(Notify : bool) -> void:
	SpotNameLabel.self_modulate = Color(1, 0.1, 0)
	if (Notify):
		var Notif = NofiticationScene.instantiate() as ShipMarkerNotif
		Notif.SetText("Alarm Raised")
		Notif.modulate = Color(1, 0.1, 0)
		add_child(Notif)

func UpdateCameraZoom(NewZoom : float) -> void:
	SpotDropPosition.scale = Vector2(1,1) / NewZoom
	$AnalyzeButton.visible = NewZoom <= 0.25

func _on_visible_on_screen_notifier_2d_screen_entered() -> void:
	$AnalyzeButton.add_to_group("UnmovableMapInfo")
	SpotNameLabel.get_parent().add_to_group("UnmovableMapInfo")
	add_to_group("ZoomAffected")
	UpdateCameraZoom(ShipCamera.GetInstance().zoom.x)

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	$AnalyzeButton.remove_from_group("UnmovableMapInfo")
	SpotNameLabel.get_parent().remove_from_group("UnmovableMapInfo")
	remove_from_group("ZoomAffected")
