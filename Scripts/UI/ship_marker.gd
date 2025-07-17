extends Node2D

class_name ShipMarker

@export_group("Nodes")
@export var Direction : Label
@export var ShipCallsign : Label
@export var ShipDetailLabel : Label
@export var DetailPanel : Control
@export var ShipIcon : TextureRect
@export var VisualContactCountdown : ProgressBar
@export_group("Resources")
@export var ResuplyNotificationScene : PackedScene
@export var NotificationScene : PackedScene
@export var Icons : Dictionary

var ShipNameText : String = ""
var ShipSpeedText : String = ""
var TimeSeenText : String = ""
var FuelText : String = ""
var HullText : String = ""

var TimeLastSeen : float
var Showspeed : bool = false

var ElintNotif : ShipMarkerNotif
var LandingNotif : ShipMarkerNotif
var ResuplyNotif : ResuplyNotification

var CurrentZoom : float

var TargetLocations : Array[Vector2]

signal ShipSelected
signal RemoveSelf

func _ready() -> void:
	DetailPanel.visible = false
	$Line2D.visible = false

	VisualContactCountdown.visible = false
	#set_physics_process(false)
	UpdateCameraZoom(Map.GetCameraZoom())

func _draw() -> void:
	#TODO fix zoom affecting distance text
	for g in TargetLocations.size():
		var origin = Vector2.ZERO
		var topos = to_local(TargetLocations[g])
		if (g > 0):
			origin = to_local(TargetLocations[g - 1])

		draw_dashed_line(origin, topos, Color(1,1,1), 1 / CurrentZoom, 10 / CurrentZoom)
		
		var pos = origin + origin.direction_to(topos) * (origin.distance_to(topos) / 2)
		var string = "{0} km".format([roundi(origin.distance_to(topos))])
		var fontsize = roundi(10 / CurrentZoom)
		#pos.x -= string.length() / 2 * fontsize
		
		draw_string(ThemeDB.fallback_font, pos, string, HORIZONTAL_ALIGNMENT_FILL, -1, fontsize)

func Update(ship : Node2D, IsControlled : bool, CamPos : Vector2) -> void:
	queue_redraw()
	
	if (ship is HostileShip):
		
		ToggleShipDetails(!ship.Docked)
		ToggleVisualContactProgress(ship.VisualContactCountdown < 10)
		if (ship.VisualContactCountdown < 10):
			UpdateVisualContactProgress(ship.VisualContactCountdown)
		#if (EnemyDebug):
			#global_position = ship.GetShipParalaxPosition(CamPos, Zoom)
			#UpdateSpeed(ship.GetShipSpeed())
			#
			#Marker.ClearTime()
			#var fuelstats
			#if (ship.Docked):
				#fuelstats = ship.Command.GetFuelStats()
			#else:
				#fuelstats = ship.GetFuelStats()
			#Marker.UpdateDroneFuel(roundi(fuelstats["CurrentFuel"]), fuelstats["MaxFuel"])
			#Marker.UpdateTrajectory(ship.global_rotation)
		#else:
		ClearFuel()
		modulate.a = 1
		if (ship.Destroyed):
			SetMarkerDetails("Ship Debris", "" ,0)
		else: if (ship.VisibleBy.size() > 0):
			
			global_position = ship.GetShipParalaxPosition(CamPos, CurrentZoom)
			UpdateSpeed(ship.GetShipSpeed())
			ClearTime()
			SetTime()
			UpdateTrajectory(ship.global_rotation)
		else :
			modulate.a = 0.5
			var timepast = Clock.GetInstance().GetHoursSince(TimeLastSeen)
			if (timepast > 24):
				RemoveSelf.emit
			else:
				UpdateTime(timepast)
	else:
		if (ship is PlayerDrivenShip):
			TargetLocations = ship.TargetLocations
			global_position = ship.GetShipParalaxPosition(CamPos, CurrentZoom)
			ToggleShipDetails(IsControlled)
		
			UpdateTrajectory(ship.global_rotation)
			UpdateSpeed(ship.GetShipSpeed())
			
			if (ship.Landing or ship.TakingOff or ship.MatchingAltitude):
				#TODO find proper fix
				if (LandingNotif == null):
					OnLandingStarted()
				UpdateAltitude(ship.Altitude)
			
			if (!IsControlled):
				return
			var fuelstats
			if (ship.Docked):
				fuelstats = ship.Command.GetFuelStats()
			else:
				fuelstats = ship.GetFuelStats()
			UpdateDroneFuel(roundi(fuelstats["CurrentFuel"]), fuelstats["MaxFuel"])

		else : if (ship is Missile):
			if (ship.FiredBy is PlayerDrivenShip or ship.VisibleBy.size() > 0):
				global_position = ship.global_position
				visible = true
				ClearTime()
				UpdateTrajectory(ship.global_rotation)
			else :
				visible = false
	UpdateTexts()

func UpdateTexts() -> void:
	var T = ""
	T += ShipNameText + "\n"
	T += ShipSpeedText + "\n"
	if (TimeSeenText != ""):
		T += TimeSeenText + "\n"
	if (FuelText != ""):
		T += FuelText + "\n"
	if (HullText != ""):
		T += HullText + "\n"
	ShipDetailLabel.text = T
	
func PlayHostileShipNotif(text : String) -> void:
	var notif = NotificationScene.instantiate() as ShipMarkerNotif
	notif.SetText(text)
	RadioSpeaker.GetInstance().PlaySound(RadioSpeaker.RadioSound.RADAR_DETECTED)
	add_child(notif)
	
func OnShipDeparted() -> void:
	if (ResuplyNotif != null):
		ResuplyNotif.OnShipDeparted()
	ToggleShowRefuel("Refueling", false, 0)
	ToggleShowRefuel("Repairing", false, 0)
	ToggleShowRefuel("Upgrading", false, 0)

func UpdateTrajectory(Dir : float) -> void:
	Direction.rotation = Dir

func DroneReturning() -> void:
	var notif = NotificationScene.instantiate() as ShipMarkerNotif
	notif.SetText("Regrouping with fleet")
	add_child(notif)

func SetType(T : String) -> void:
	ShipIcon.texture = Icons[T]
	
func ToggleShowRefuel(Stats : String, t : bool, timel : float = 0):
	if (ResuplyNotif != null):
		ResuplyNotif.ToggleStat(Stats, t, timel)
		return
	if (t):
		ResuplyNotif = ResuplyNotificationScene.instantiate() as ResuplyNotification
		ResuplyNotif.ToggleStat(Stats, t, timel)
		connect("ShipDeparted", ResuplyNotif.OnShipDeparted)
		add_child(ResuplyNotif)

func ToggleShowElint( t : bool, ElingLevel : int, ElintDirection : String):
	if ElintNotif != null:
		if (t):
			ElintNotif.SetText("ELINT : Lvl {0} \nDiretion : {1}".format([var_to_str(ElingLevel), ElintDirection]))
			return
		else :
			ElintNotif.queue_free()
			ElintNotif = null
			return
	if (t):
		ElintNotif = NotificationScene.instantiate() as ShipMarkerNotif
		ElintNotif.SetText("ELINT : {0} \nDiretion : {1}".format([var_to_str(ElingLevel), ElintDirection]))
		ElintNotif.Blink = true
		ElintNotif.Fast = true
		#connect("ShipDeparted", notif.OnShipDeparted)
		add_child(ElintNotif)

func OnCaptainNameChanged(NewName : String) -> void:
	ShipNameText = NewName

func OnLandingStarted():
	if (is_instance_valid(LandingNotif)):
		return
	LandingNotif = NotificationScene.instantiate() as ShipMarkerNotif
	#LandingNotif.SetText("ELINT : " + var_to_str(ElingLevel))
	LandingNotif.Blink = false
	#connect("ShipDeparted", notif.OnShipDeparted)
	add_child(LandingNotif)
	
func OnLandingEnded(_Ship : MapShip):
	LandingNotif.queue_free()
	LandingNotif = null

func ToggleShipDetails(T : bool):
	DetailPanel.visible = T
	$Line2D.visible = T
	#Direction.visible = T
	#set_physics_process(T)

func OnStatLow(StatName : String) -> void:
	var notif = NotificationScene.instantiate() as ShipMarkerNotif
	notif.SetText(StatName + " bellow 20%")
	#notif.SetStatData(StatName)
	#notif.rotation = -rotation
	#notif.EntityToFollow = self
	add_child(notif)
	
func SetMarkerDetails(ShipName : String, ShipCasllSign : String, ShipSpeed : float):
	ShipNameText = ShipName
	UpdateSpeed(ShipSpeed)
	ShipCallsign.text = ShipCasllSign
	
func UpdateCameraZoom(NewZoom : float) -> void:
	DetailPanel.scale = Vector2(1,1) / NewZoom
	ShipIcon.scale = (Vector2(0.7,0.7) / NewZoom)
	#$ShipSymbol.scale = Vector2(1,1) / camera.zoom
	UpdateLine(NewZoom)
	$Line2D.width =  1.5 / NewZoom
	CurrentZoom = NewZoom

func UpdateLine(Zoom : float)-> void:
	var locp = get_closest_point_on_rect($Control/PanelContainer/ShipName.get_global_rect(), DetailPanel.global_position)
	$Line2D.set_point_position(1, locp - $Line2D.global_position)
	$Line2D.set_point_position(0, global_position.direction_to(locp) * 30 / (Zoom))
	
func UpdateAltitude(Alt : float):
	LandingNotif.SetText("ALT : " + var_to_str(roundi(Alt)))

func EnteredScreen() -> void:
	$Control/PanelContainer/ShipName.add_to_group("MapInfo")
	ShipIcon.add_to_group("UnmovableMapInfo")
	add_to_group("ZoomAffected")
	UpdateCameraZoom(Map.GetCameraZoom())

func ExitedScreen() -> void:
	$Control/PanelContainer/ShipName.remove_from_group("MapInfo")
	ShipIcon.remove_from_group("UnmovableMapInfo")
	remove_from_group("ZoomAffected")
	
func UpdateSignRotation() -> void:
	DetailPanel.rotation += 0.01
	$Control/PanelContainer/ShipName.pivot_offset = $Control/PanelContainer/ShipName.size / 2
	$Control/PanelContainer.rotation -= 0.01
	var locp = get_closest_point_on_rect($Control/PanelContainer/ShipName.get_global_rect(), DetailPanel.global_position)
	$Line2D.set_point_position(1, locp - $Line2D.global_position)
	$Line2D.set_point_position(0, global_position.direction_to(locp) * 30 / (CurrentZoom))

func OnHostileShipDestroyed() -> void:
	modulate = Color(1,1,1)
	ShipCallsign.text = ""
	UpdateSpeed(0)
	SetType("Wreck")

func get_closest_point_on_rect(rect: Rect2, point: Vector2) -> Vector2:
	var closest_x = clamp(point.x, rect.position.x, rect.position.x + rect.size.x)
	var closest_y = clamp(point.y, rect.position.y, rect.position.y + rect.size.y)
	return Vector2(closest_x, closest_y)

func UpdateVisualContactProgress(val : float) -> void:
	VisualContactCountdown.value = val

func ToggleVisualContactProgress(t : bool) -> void:
	VisualContactCountdown.visible = t

func ClearTime() -> void:
	TimeSeenText = ""

func SetTime() -> void:
	TimeLastSeen = Clock.GetInstance().GetTimeInHours() 

func UpdateTime(timepast : float):
	TimeSeenText = var_to_str(snappedf((timepast) , 0.01)) + "h ago"

func ClearFuel() -> void:
	FuelText = ""

func UpdateDroneFuel(amm : float, maxamm : float):
	FuelText = "FUEL {0}%".format([roundi(amm / maxamm * 100)])
	#roundi(amm / maxamm * 100)

func ClearSpeed() -> void:
	ShipSpeedText = ""

func UpdateSpeed(Spd : float):
	Direction.visible = Spd > 0
	var spd = roundi(Map.SpeedToKmH(Spd))
	ShipSpeedText = "SPEED " + var_to_str(spd).replace(".0", "")

func GetSaveData() -> SD_ShipMarker:
	var Data = SD_ShipMarker.new()
	Data.ShipName = ShipNameText
	Data.TimeLastSeen = TimeLastSeen
	Data.Pos = global_position
	Data.Trajectory = Direction.rotation
	
	return Data


func _on_icon_gui_input(event: InputEvent) -> void:
	if (event.is_action_pressed("Click")):
		ShipSelected.emit()
