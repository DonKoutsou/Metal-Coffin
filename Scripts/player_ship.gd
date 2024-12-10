extends Node2D

class_name PlayerShip

@export var LowStatsToNotifyAbout : Array[String]
@export var CaptainIcon : Texture
@export var LowleftNotif : PackedScene
#@export var Missile : PackedScene

var ShipType : BaseShip

var Travelling = false
#var ChangingCourse = false
var Paused = false
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

static var Instance : PlayerShip

var Detectable = true

func _ready() -> void:
	MapPointerManager.GetInstance().AddShip(self, true)
	Instance = self

func GetDroneDock() -> DroneDock:
	return $DroneDock
static func GetInstance() -> PlayerShip:
	return Instance
	
#func FireMissile():
	#var m = Missile.instantiate()
	#get_parent().add_child(m)
	#m.global_rotation = global_rotation
	#m.global_position = global_position
	
func TogglePause(t : bool):
	Paused = t
	$AudioStreamPlayer2D.stream_paused = t
	$Radar/Radar_Range.material.set_shader_parameter("Paused", t)
	$Analyzer/Analyzer_Range.material.set_shader_parameter("Paused", t)
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
	#tw.tween_property(FuelRangeIndicator, "size", Vector2(distall, distall) * 2, 0.5)
	tw.tween_method(SetFuelShaderRange, FuelMat.get_shader_parameter("scale_factor"), (distall/2) / 10000, 0.5)
	#centering of color rect
	#var tw2 = create_tween()
	#tw2.tween_property(FuelRangeIndicatorDescriptor, "position", Vector2(9900 + (distall/2), 10000), 0.5)
	#DISSABLE DESCRIPTOR WHEN INDICATOR GETS TO SMALL
	#FuelRangeIndicatorDescriptor.visible = distall > 100
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
	#scalling of collor rect
	#RadarRangeIndicator.size = Vector2(rang, rang) * 2
	#centering of color rect
	#RadarRangeIndicator.position = Vector2(-(rang), -(rang))
	
	#dissable descriptor when indicator gets to small
	#RadarRangeIndicatorDescriptor.position.x = 9900 + rang
	#RadarRangeIndicatorDescriptor.visible = rang > 100
func SetRadarShaderRange(val : float):
	var RadarMat = $Radar/Radar_Range.material as ShaderMaterial
	RadarMat.set_shader_parameter("scale_factor", val)
func UpdateAnalyzerRange(rang : float):
	var AnalyzerRangeIndicator = $Analyzer/Analyzer_Range
	var AnalyzerRangeCollisionShape = $Analyzer/CollisionShape2D
	#var AnalyzerRangeIndicatorDescriptor = $Analyzer/Analyzer_Range/Label2
	var AnalyzerMat = AnalyzerRangeIndicator.material as ShaderMaterial
	#CHANGING SIZE OF RADAR
	AnalyzerMat.set_shader_parameter("scale_factor", rang/10000)
	#SCALLING COLLISION
	(AnalyzerRangeCollisionShape.shape as CircleShape2D).radius = rang
	
	#AnalyzerRangeIndicatorDescriptor.position.x = 9900 + rang
	#DISSABLE DESCRIPTOR WHEN INDICATOR GETS TO SMALL
	#AnalyzerRangeIndicatorDescriptor.visible = rang > 100
func SetAnalyzerShaderRange(val : float):
	var AnalyzerMat = $Analyzer/Analyzer_Range.material as ShaderMaterial
	AnalyzerMat.set_shader_parameter("scale_factor", val)
func ShowingNotif() -> bool:
	return $Notifications.get_child_count() > 0

func OnStatLow(StatName : String) -> void:
	if (!LowStatsToNotifyAbout.has(StatName)):
		return
	var notif = (load("res://Scenes/LowStatNotif.tscn") as PackedScene).instantiate() as LowStatNotif
	notif.SetStatData(StatName)
	notif.rotation = -rotation
	notif.EntityToFollow = self
	#notif.camera = $"../../Camera2D"
	$Notifications.add_child(notif)
	
	#Ingame_UIManager.GetInstance().AddUI(notif)
func ToggleShowRefuel(Stats : String, t : bool, timel : float = 0):
	var notif : LowLeftNotif
	for g in $Notifications.get_children():
		if g is LowLeftNotif:
			g.ToggleStat(Stats, t, timel)
			return
	if (t):
		notif = LowleftNotif.instantiate() as LowLeftNotif
		notif.ToggleStat(Stats, t, timel)
		connect("ShipDeparted", notif.OnShipDeparted)
		$Notifications.add_child(notif)

func _physics_process(_delta: float) -> void:
	if (Paused):
		return
	if ($Node2D.position.x == 0):
		if (CurrentPort != null):
			CurrentPort.OnSpotVisited()
			if (CanRefuel):
				if (!ShipData.GetInstance().IsResourceFull("FUEL")):
					var timeleft = (ShipData.GetInstance().GetStat("FUEL").GetStat() - ShipData.GetInstance().GetStat("FUEL").GetCurrentValue()) / 0.05 / 60
					ToggleShowRefuel("Refueling", true, roundi(timeleft))
					ShipData.GetInstance().RefilResource("FUEL", 0.05)
				else:
					ToggleShowRefuel("Refueling", false)
			if (CanRepair):
				if (!ShipData.GetInstance().IsResourceFull("HULL")):
					var timeleft = (ShipData.GetInstance().GetStat("HULL").GetStat() - ShipData.GetInstance().GetStat("HULL").GetCurrentValue()) / 0.05 / 60
					ToggleShowRefuel("Repairing", true, roundi(timeleft))
					ShipData.GetInstance().RefilResource("HULL", 0.05)
				else:
					ToggleShowRefuel("Repairing", false)
			if (CanUpgrade):
				var inv = Inventory.GetInstance()
				if (inv.UpgradedItem != null):
					ToggleShowRefuel("Upgrading", true, roundi(inv.GetUpgradeTimeLeft()))
				else:
					ToggleShowRefuel("Upgrading", false)
		return
	var fuel = $Node2D.position.x / 10 / ShipData.GetInstance().GetStat("FUEL_EFFICIENCY").GetStat()
	var Dat = ShipData.GetInstance()
	if (Dat.GetStat("FUEL").GetCurrentValue() < fuel):
		HaltShip()
		PopUpManager.GetInstance().DoPopUp("You have run out of fuel.")
		#set_physics_process(false)
		return
	#if (Dat.GetStat("CRYO").GetStat() == 0):
		#var oxy = $Node2D.position.x / 100
		#if (Dat.GetStat("OXYGEN").GetCurrentValue() < oxy):
			#HaltShip()
			#PopUpManager.GetInstance().DoPopUp("You have run out of oxygen.")
			##set_physics_process(false)
			#return
		#Dat.RefilResource("OXYGEN", -oxy)
	global_position = $Node2D.global_position
	Dat.ConsumeResource("FUEL", fuel)
	

func GetShipSpeed() -> float:
	return $Node2D.position.x
func GetShipSpeedVec() -> Vector2:
	return $Node2D.global_position - global_position

func HaltShip():
	Travelling = false
	#set_physics_process(false)
	
	$Node2D.position.x = 0
	#$AudioStreamPlayer2D.stop()
	AccelerationChanged(0)
	#ChangingCourse = false
	ShipForceStopped.emit()
	
func SteerChanged(value: float) -> void:
	Steer(deg_to_rad(value))

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
	postween.tween_property($Node2D, "position", Vector2(max(0,value / 3), 0), 2)
	
func AccelerationEnded(_value_changed: bool) -> void:
	pass
	#ChangingCourse = false
	
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
