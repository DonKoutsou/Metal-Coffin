extends Control

class_name SpotMarker

@export var SpotNameLabel : Label
@export var SpotDropPosition : Control
@export var NofiticationScene : PackedScene

@export var BeepSound : AudioStream


var TimeLastSeen : float

func SetMarkerDetails(Spot : MapSpot, PlayAnim : bool):
	if (PlayAnim):
		if (!Spot.Seen):
			$AnimationPlayer.play("SpotFound")
			PlaySound()
	SpotNameLabel.text = Spot.SpotInfo.SpotName
	
	call_deferred("SetSize", Spot)
	
	if (Spot.SpotInfo.PossibleDrops.size() == 0):
		print(Spot.GetSpotName() + " has no drops")
	for g in Spot.SpotInfo.PossibleDrops:
		var text = TextureRect.new()
		text.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		text.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		text.custom_minimum_size = Vector2(18,18)
		text.texture = g.ItemIcon
		if (g is UsableItem):
			text.self_modulate = g.ItecColor
		text.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		text.use_parent_material = true
		SpotDropPosition.add_child(text)
	$HBoxContainer.pivot_offset.y = $HBoxContainer.size.y
	$HBoxContainer.pivot_offset.x = $HBoxContainer.size.x/2
	
	UpdateFuelAmm(Spot.PlayerFuelReserves)
	
	Spot.SpotLanded.connect(OnVisited)
	Spot.FuelReservesChanged.connect(UpdateFuelAmm)
	
	if (!Spot.Visited):
		$AnalyzeButton.modulate = Color(1,1,1, 0.3)
	else:
		$AnalyzeButton.modulate = Color(1,1,1, 1)
	
func SetSize(Spot : MapSpot) -> void:
	var sizething = (Spot.Population / 150000.0) as float
	$AnalyzeButton.size = lerp(Vector2(30,30), Vector2(250,250), sizething)
	$AnalyzeButton.position = -$AnalyzeButton.size/2

func PlaySound():
	var sound = AudioStreamPlayer2D.new()
	sound.bus = "MapSounds"
	sound.volume_db = 10
	sound.stream = BeepSound
	add_child(sound)
	sound.play()

func UpdateFuelAmm(Amm : float) -> void:
	$Label.text = "Fuel {0}".format([roundi(Amm)])
	$Label.visible = Amm > 0
	$Label.pivot_offset = Vector2($Label.size.x /2, 0)

func OnAlarmRaised(Notify : bool) -> void:
	SpotNameLabel.self_modulate = Color(1, 0.1, 0)
	if (Notify):
		var Notif = NofiticationScene.instantiate() as ShipMarkerNotif
		Notif.SetText("Alarm Raised")
		Notif.modulate = Color(1, 0.1, 0)
		add_child(Notif)

func OnVisited(Type : MapSpot) -> void:
	$AnalyzeButton.modulate = Color(1,1,1, 1)

func UpdateCameraZoom(NewZoom : float) -> void:
	$HBoxContainer.scale = Vector2(1,1) / NewZoom
	$Label.scale = Vector2(1,1) / NewZoom
	$AnalyzeButton.visible = NewZoom <= 0.8

func EnteredScreen() -> void:
	$AnalyzeButton.add_to_group("UnmovableMapInfo")
	SpotNameLabel.get_parent().add_to_group("UnmovableMapInfo")
	add_to_group("ZoomAffected")
	UpdateCameraZoom(Map.GetCameraZoom())

func ExitedScreen() -> void:
	$AnalyzeButton.remove_from_group("UnmovableMapInfo")
	SpotNameLabel.get_parent().remove_from_group("UnmovableMapInfo")
	remove_from_group("ZoomAffected")
