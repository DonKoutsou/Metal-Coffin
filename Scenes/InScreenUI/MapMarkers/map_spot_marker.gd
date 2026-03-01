extends Control

class_name SpotMarker

@export var C : Color = Color(1,1,1,0.3)

@export var SpotDropPosition : Control
@export var NofiticationScene : PackedScene
@export var Spacer : Control
@export var BeepSound : AudioStream
@export var DetailContainer : Control

@export var SpotNameLabel : Label
@export var FuelLabel : Label

@export var Anim : AnimationPlayer

signal TownTargetSelected(Marker : SpotMarker)

var TimeLastSeen : float
var CircleSize : float
var CurrentZoom : float

func _draw() -> void:
	draw_circle(Vector2.ZERO, CircleSize, C, false, 3 / CurrentZoom)

func SetMarkerDetails(Spot : MapSpot, PlayAnim : bool):
	if (PlayAnim):
		if (!Spot.Seen):
			Anim.play("SpotFound")
			PlaySound()
	SpotNameLabel.text = Spot.SpotName
	
	call_deferred("SetSize", Spot)
	
	if (Spot.PossibleDrops.size() == 0):
		print(Spot.GetSpotName() + " has no drops")
	for g in Spot.PossibleDrops:
		var text = TextureRect.new()
		text.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		text.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		text.custom_minimum_size = Vector2(18,18)
		text.texture = g.ItemIcon
		text.modulate.a = 0.3
		text.mouse_filter = Control.MOUSE_FILTER_IGNORE
		SpotNameLabel.modulate.a = 0.3
		#if (g is UsableItem):
			#text.self_modulate = g.ItecColor
		text.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		text.use_parent_material = true
		SpotDropPosition.add_child(text)
	
	UpdateFuelAmm(Spot.PlayerFuelReserves)
	
	Spot.SpotLanded.connect(OnVisited)
	Spot.FuelReservesChanged.connect(UpdateFuelAmm)
	
	if (!Spot.Visited):
		C.a = 0.3
		SpotNameLabel.modulate.a = 0.3
	else:
		C.a = 1
		SpotNameLabel.modulate.a = 1
	
func SetSize(Spot : MapSpot) -> void:
	var sizething = (Spot.Population / 150000.0) as float
	CircleSize = lerp(30, 250, sizething)
	DetailContainer.position.y = -DetailContainer.size.y - CircleSize
	FuelLabel.position.y = FuelLabel.size.y + CircleSize
	$Control.scale = Vector2(CircleSize, CircleSize) * 2
	#$AnalyzeButton.position = -$AnalyzeButton.size/2

func PlaySound():
	var sound = AudioStreamPlayer2D.new()
	sound.bus = "MapSounds"
	sound.volume_db = 10
	sound.stream = BeepSound
	add_child(sound)
	sound.play()

func UpdateFuelAmm(Amm : float) -> void:
	FuelLabel.text = "Fuel {0}".format([roundi(Amm)])
	FuelLabel.visible = Amm > 0
	FuelLabel.pivot_offset = Vector2(FuelLabel.size.x /2, 0)

func OnAlarmRaised(Notify : bool) -> void:
	SpotNameLabel.self_modulate = Color(1, 0.1, 0)
	if (Notify):
		var Notif = NofiticationScene.instantiate() as ShipMarkerNotif
		Notif.SetText("Alarm Raised")
		Notif.modulate = Color(1, 0.1, 0)
		add_child(Notif)

func OnVisited(_Type : MapSpot) -> void:
	C.a = 1
	SpotNameLabel.modulate.a = 1

func UpdateCameraZoom(NewZoom : float) -> void:
	queue_redraw()
	CurrentZoom = NewZoom
	DetailContainer.scale = clamp(Vector2(1,1) / NewZoom, Vector2(3,3), Vector2(10,10))
	FuelLabel.scale = clamp(Vector2(1,1) / NewZoom, Vector2(3,3), Vector2(10,10))
	#$AnalyzeButton.visible = NewZoom <= 1.5

func EnteredScreen() -> void:
	SpotDropPosition.add_to_group("UnmovableMapInfo")
	SpotNameLabel.add_to_group("UnmovableMapInfo")
	#SpotNameLabel.get_parent().add_to_group("UnmovableMapInfo")
	add_to_group("ZoomAffected")
	UpdateCameraZoom(Map.GetCameraZoom())

func ExitedScreen() -> void:
	SpotNameLabel.remove_from_group("UnmovableMapInfo")
	SpotDropPosition.remove_from_group("UnmovableMapInfo")
	#SpotNameLabel.get_parent().remove_from_group("UnmovableMapInfo")
	remove_from_group("ZoomAffected")


func _on_analyze_button_gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton):
		if (event.button_index == MOUSE_BUTTON_RIGHT and event.pressed):
			TownTargetSelected.emit(self)
