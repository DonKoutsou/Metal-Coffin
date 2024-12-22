extends Node2D

class_name MapShip

@export var LowStatsToNotifyAbout : Array[String]


#@export var Missile : PackedScene

var ShipType : BaseShip

var Travelling = false
#var ChangingCourse = false
var Paused = false
var SimulationSpeed : int = 1
var CurrentPort : MapSpot
var CanRefuel = false
var CanRepair = false
var CanUpgrade = false
var IsRefueling = false
var RadarWorking = true
var FuelVis = true
var Altitude = 10000

signal ScreenEnter()
signal ScreenExit()
signal ShipStopped
signal ShipAccelerating
signal ShipForceStopped
signal ShipDeparted()
signal ShipDockActions(Stats : String, t : bool, timel : float)
signal StatLow(StatName : String)

var Landing : bool = false
signal LandingStarted
signal LandingCanceled(Ship : MapShip)
signal LandingEnded(Ship : MapShip)
var TakingOff : bool = false
signal TakeoffStarted
signal TakeoffEnded(Ship : MapShip)

signal Elint(T : bool, Lvl : int)
var ElintContacts : Dictionary

var Detectable = true

func _ready() -> void:
	$Elint.connect("area_entered", _on_elint_area_entered)
	$Elint.connect("area_exited", _on_elint_area_exited)
	MapPointerManager.GetInstance().AddShip(self, true)
	
func TogglePause(t : bool):
	Paused = t
	$AudioStreamPlayer2D.stream_paused = t
	#$Radar/Radar_Range.material.set_shader_parameter("Paused", t)
	#$Analyzer/Analyzer_Range.material.set_shader_parameter("Paused", t)
func ChangeSimulationSpeed(i : int):
	SimulationSpeed = i
func ToggleRadar():
	Detectable = !Detectable
	RadarWorking = !RadarWorking
	$Radar/CollisionShape2D.disabled = !$Radar/CollisionShape2D.disabled
	#$Radar/Radar_Range.visible = !$Radar/Radar_Range.visible
	
	#$Analyzer.monitorable = !$Analyzer.monitorable
	#$Analyzer/Analyzer_Range.visible = !$Analyzer/Analyzer_Range.visible
	var tw = create_tween()
	if ($PointLight2D.energy < 0.25):
		tw.tween_property($PointLight2D, "energy", 0.25, 0.5)
	else :
		tw.tween_property($PointLight2D, "energy", 0, 0.5)
	#$PointLight2D.visible = !$PointLight2D.visible

func ToggleElint():
	$Elint/CollisionShape2D.disabled = !$Elint/CollisionShape2D.disabled



func StartLanding() -> void:
	LandingStarted.emit()
	Landing = true

func Landed() -> bool:
	return Altitude == 0

var d = 0.4
func _physics_process(delta: float) -> void:
	if (Landing):
		Altitude -= 50
		if (Altitude <= 0):
			Altitude = 0
			LandingEnded.emit(self)
			Landing = false
	if (TakingOff):
		Altitude += 50
		if (Altitude >= 10000):
			Altitude = 10000
			TakeoffEnded.emit(self)
			TakingOff = false
	d -= delta
	if (d > 0):
		return
	d = 0.4
	var BiggestLevel = 0
	for g in ElintContacts.size():
		var ship = ElintContacts.keys()[g]
		var lvl = ElintContacts.values()[g]
		var Newlvl = GetElintLevel(global_position.distance_to(ship.global_position))
		if (Newlvl != lvl):
			if (Newlvl > BiggestLevel):
				Elint.emit(true, Newlvl)
				BiggestLevel = Newlvl
			ElintContacts[ship] = Newlvl
			

func GetElintLevel(Dist : float) -> int:
	var Lvl = 1
	if (Dist < 300):
		Lvl = 3
	else : if(Dist < 600):
		Lvl = 2
	else :
		Lvl = 1
	return Lvl

func GetClosestElint() -> Vector2:
	var closest : Vector2 = Vector2.ZERO
	var closestdist : float = 999999999999
	for g in ElintContacts.size():
		var ship = ElintContacts.keys()[g]
		var dist = global_position.distance_to(ship.global_position)
		if (closestdist > dist):
			closest = ship.global_position
			closestdist = dist
	
	return closest

func SetCurrentPort(Port : MapSpot):
	CurrentPort = Port
	CanRefuel = Port.HasFuel()
	CanRepair = Port.HasRepair()
	CanUpgrade = Port.HasUpgrade()

func RemovePort():
	ShipDeparted.emit()
	CurrentPort = null
	Inventory.GetInstance().CancelUpgrades()
	
func UpdateFuelRange(fuel : float, fuel_ef : float):
	var FuelRangeIndicator = $Fuel_Range
	#var FuelRangeIndicatorDescriptor = $Fuel_Range/Label
	var FuelMat = FuelRangeIndicator.material as ShaderMaterial
	#calculate the range taking fuel efficiency in mind
	var distall = (fuel * 10 * fuel_ef) * 2
	#scalling of collor rect
	var tw = create_tween()

	tw.tween_method(SetFuelShaderRange, FuelMat.get_shader_parameter("scale_factor"), (distall/2) / 10000, 0.5)

func ToggleFuelRangeVisibility(t : bool) -> void:
	$Fuel_Range.visible = t

func SetFuelShaderRange(val : float):
	var FuelMat = $Fuel_Range.material as ShaderMaterial
	FuelMat.set_shader_parameter("scale_factor", val)
	
func UpdateVizRange(rang : float):
	#var RadarRangeIndicator = $Radar/Radar_Range
	var RadarRangeCollisionShape = $Radar/CollisionShape2D
	#var RadarRangeIndicatorDescriptor = $Radar/Radar_Range/Label2
	#var RadarMat = RadarRangeIndicator.material as ShaderMaterial
	#RadarMat.set_shader_parameter("scale_factor", rang/10000)
	#scalling collision
	(RadarRangeCollisionShape.shape as CircleShape2D).radius = rang
	
	var l = get_node_or_null("PointLight2D")
	if (l != null):
		l.texture_scale = rang / 800
#
#func UpdateAnalyzerRange(rang : float):
	#var AnalyzerRangeIndicator = $Analyzer/Analyzer_Range
	#var AnalyzerRangeCollisionShape = $Analyzer/CollisionShape2D
	##var AnalyzerRangeIndicatorDescriptor = $Analyzer/Analyzer_Range/Label2
	#var AnalyzerMat = AnalyzerRangeIndicator.material as ShaderMaterial
	##CHANGING SIZE OF RADAR
	#AnalyzerMat.set_shader_parameter("scale_factor", rang/10000)
	##SCALLING COLLISION
	#(AnalyzerRangeCollisionShape.shape as CircleShape2D).radius = rang

func ShowingNotif() -> bool:
	return $Notifications.get_child_count() > 0

func OnStatLow(StatName : String) -> void:
	if (!LowStatsToNotifyAbout.has(StatName)):
		return
	StatLow.emit(StatName)


	

func GetShipSpeed() -> float:
	return $Aceleration.position.x
func GetShipSpeedVec() -> Vector2:
	return $Aceleration.global_position - global_position

func HaltShip():
	Travelling = false
	#set_physics_process(false)
	
	$Aceleration.position.x = 0
	#$AudioStreamPlayer2D.stop()
	AccelerationChanged(0)
	#ChangingCourse = false
	ShipForceStopped.emit()
	


func AccelerationChanged(value: float) -> void:
	if (value <= 0):
		Travelling = false
		#set_physics_process(false)
		#$AudioStreamPlayer2D.stop()
		$GPUParticles2D.emitting = false
		ShipStopped.emit()
		#return
	else:
		if (Landing):
			LandingCanceled.emit(self)
			Landing = false
			Altitude = 10000
		if (Altitude == 0):
			TakeoffStarted.emit()
			TakingOff = true
		#if (Paused):
			#return
		var Dat = ShipData.GetInstance()
		if (Dat.GetStat("FUEL").GetCurrentValue() <= 0):
			HaltShip()
			PopUpManager.GetInstance().DoPopUp("You have run out of fuel.")
			return
			#set_physics_process(false)
			
		$GPUParticles2D.emitting = true
		Travelling = true
		#set_physics_process(true)
		ShipAccelerating.emit()
	
	
	var Audioween = create_tween()
	#Audioween.set_trans(Tween.TRANS_EXPO)
	#var ef = AudioServer.get_bus_effect(4, 0)
	Audioween.tween_property($AudioStreamPlayer2D, "pitch_scale", max(0.1,value / 2), 2)
	#ChangingCourse = true
	if (!$AudioStreamPlayer2D.playing):
		$AudioStreamPlayer2D.play()
	
	var postween = create_tween()
	postween.set_trans(Tween.TRANS_EXPO)
	postween.tween_property($Aceleration, "position", Vector2(max(0,value * GetShipMaxSpeed()), 0), 2)

func AccelerationEnded(_value_changed: bool) -> void:
	pass
	#ChangingCourse = false

func GetShipMaxSpeed() -> float:
	return 0.3

signal OnLookAtEnded()
func LookAtEnded():
	OnLookAtEnded.emit()
func PlayerLookAt(LookPos : Vector2) -> void:
	var tw = create_tween()
	tw.tween_property(self, "rotation", position.angle_to_point(LookPos), 1)
	#tw.set_trans(Tween.TRANS_EXPO)
	tw.connect("finished", LookAtEnded)
	
func Steer(Rotation : float) -> void:
	var tw = create_tween()
	#tw.set_trans(Tween.TRANS_EXPO)
	tw.tween_property(self, "rotation", Rotation, 1)

func GetSteer() -> float:
	return rotation

func ToggleUI(t : bool):
	$ShipBody.monitorable = t
	#$Analyzer.monitorable = t
	$Radar.monitorable = t
	#$Radar/Radar_Range.visible = t
	$Fuel_Range.visible = t
	#$Analyzer/Analyzer_Range.visible = t

func SetShipType(Ship : BaseShip):
	ShipType = Ship
	_UpdateShipIcon(Ship.TopIcon)
	
func GetBattleStats() -> BattleShipStats:
	var stats = BattleShipStats.new()
	return stats

func _UpdateShipIcon(Tex : Texture) -> void:
	$PlayerShipSpr.texture = Tex	

func _on_player_viz_notifier_screen_entered() -> void:
	ScreenEnter.emit()
	
func _on_player_viz_notifier_screen_exited() -> void:
	ScreenExit.emit()

func _on_elint_area_entered(area: Area2D) -> void:
	ElintContacts[area.get_parent()] = 0
	#Elint.emit(true, 1)
func _on_elint_area_exited(area: Area2D) -> void:
	ElintContacts.erase(area.get_parent())
	Elint.emit(false, 0)
func GetShipBodyArea() -> Area2D:
	return $ShipBody
func GetShipRadarArea() -> Area2D:
	return $Radar
#func GetShipAnalayzerArea() -> Area2D:
	#return $Analyzer
func GetShipAcelerationNode() -> Node2D:
	return $Aceleration
func GetShipIcon() -> Node2D:
	return $PlayerShipSpr
func GetFuelReserves() -> float:
	return 0
