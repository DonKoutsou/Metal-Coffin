extends Node2D

class_name MapShip

@export var LowStatsToNotifyAbout : Array[String]
@export var CaptainIcon : Texture

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

signal ScreenEnter()
signal ScreenExit()
signal ShipStopped
signal ShipAccelerating
signal ShipForceStopped
signal ShipDeparted()
signal ShipDockActions(Stats : String, t : bool, timel : float)
signal StatLow(StatName : String)

var Detectable = true

func _ready() -> void:
	MapPointerManager.GetInstance().AddShip(self, true)
	
func TogglePause(t : bool):
	Paused = t
	$AudioStreamPlayer2D.stream_paused = t
	$Radar/Radar_Range.material.set_shader_parameter("Paused", t)
	$Analyzer/Analyzer_Range.material.set_shader_parameter("Paused", t)
func ChangeSimulationSpeed(i : int):
	SimulationSpeed = i
func ToggleRadar():
	Detectable = !Detectable
	$Radar/CollisionShape2D.disabled = !$Radar/CollisionShape2D.disabled
	$Radar/Radar_Range.visible = !$Radar/Radar_Range.visible
	
	$Analyzer.monitorable = !$Analyzer.monitorable
	$Analyzer/Analyzer_Range.visible = !$Analyzer/Analyzer_Range.visible
	var tw = create_tween()
	if ($PointLight2D.energy < 0.25):
		tw.tween_property($PointLight2D, "energy", 0.25, 0.5)
	else :
		tw.tween_property($PointLight2D, "energy", 0, 0.5)
	#$PointLight2D.visible = !$PointLight2D.visible
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
	var RadarRangeIndicator = $Radar/Radar_Range
	var RadarRangeCollisionShape = $Radar/CollisionShape2D
	#var RadarRangeIndicatorDescriptor = $Radar/Radar_Range/Label2
	var RadarMat = RadarRangeIndicator.material as ShaderMaterial
	RadarMat.set_shader_parameter("scale_factor", rang/10000)
	#scalling collision
	(RadarRangeCollisionShape.shape as CircleShape2D).radius = rang
	
	$PointLight2D.texture_scale = rang / 600

func UpdateAnalyzerRange(rang : float):
	var AnalyzerRangeIndicator = $Analyzer/Analyzer_Range
	var AnalyzerRangeCollisionShape = $Analyzer/CollisionShape2D
	#var AnalyzerRangeIndicatorDescriptor = $Analyzer/Analyzer_Range/Label2
	var AnalyzerMat = AnalyzerRangeIndicator.material as ShaderMaterial
	#CHANGING SIZE OF RADAR
	AnalyzerMat.set_shader_parameter("scale_factor", rang/10000)
	#SCALLING COLLISION
	(AnalyzerRangeCollisionShape.shape as CircleShape2D).radius = rang

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
		if (Paused):
			return
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
	var ef = AudioServer.get_bus_effect(4, 0)
	Audioween.tween_property(ef, "pitch_scale", max(0.1,value / 2), 2)
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
	$Analyzer.monitorable = t
	$Radar.monitorable = t
	$Radar/Radar_Range.visible = t
	$Fuel_Range.visible = t
	$Analyzer/Analyzer_Range.visible = t

func SetShipType(Ship : BaseShip):
	ShipType = Ship
	_UpdateShipIcon(Ship.TopIcon)

func GetBattleStats() -> BattleShipStats:
	var stats = BattleShipStats.new()
	stats.Hull = ShipType.GetStat("HULL").StatBuff
	stats.FirePower = 1
	stats.ShipIcon = ShipType.TopIcon
	stats.CaptainIcon = CaptainIcon
	stats.Name = "Player"
	return stats

func _UpdateShipIcon(Tex : Texture) -> void:
	$PlayerShipSpr.texture = Tex	

func _on_player_viz_notifier_screen_entered() -> void:
	ScreenEnter.emit()
func _on_player_viz_notifier_screen_exited() -> void:
	ScreenExit.emit()
