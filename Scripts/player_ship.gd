extends Node2D

class_name PlayerShip

@export var Notif : PackedScene
@export var LowStatsToNotifyAbout : Array[String]


var Travelling = false
var ChangingCourse = false

signal ScreenEnter()
signal ScreenExit()
signal ShipStopped
signal ShipAccelerating
signal ShipForceStopped

static var Instance : PlayerShip

func _ready() -> void:
	Instance = self

func GetDroneDock() -> DroneDock:
	return $DroneDock
static func GetInstance() -> PlayerShip:
	return Instance
func UpdateFuelRange(fuel : float, fuel_ef : float):
	var FuelRangeIndicator = $Fuel/Fuel_Range
	var FuelRangeIndicatorDescriptor = $Fuel/Fuel_Range/Label
	#calculate the range taking fuel efficiency in mind
	var distall = fuel * 10 * fuel_ef
	#scalling of collor rect
	var tw = create_tween()
	tw.tween_property(FuelRangeIndicator, "size", Vector2(distall, distall) * 2, 0.5)
	#centering of color rect
	var tw2 = create_tween()
	tw2.tween_property(FuelRangeIndicator, "position", Vector2(-(distall), -(distall)), 0.5)
	#dissable descriptor when indicator gets to small
	FuelRangeIndicatorDescriptor.visible = distall > 100
func UpdateVizRange(rang : float):
	var RadarRangeIndicator = $Radar/Radar_Range
	var RadarRangeCollisionShape = $Radar/CollisionShape2D
	var RadarRangeIndicatorDescriptor = $Radar/Radar_Range/Label2
	#scalling collision
	(RadarRangeCollisionShape.shape as CircleShape2D).radius = rang
	#scalling of collor rect
	RadarRangeIndicator.size = Vector2(rang, rang) * 2
	#centering of color rect
	RadarRangeIndicator.position = Vector2(-(rang), -(rang))
	#dissable descriptor when indicator gets to small
	RadarRangeIndicatorDescriptor.visible = rang > 100
func UpdateAnalyzerRange(rang : float):
	var AnalyzerRangeIndicator = $Analyzer/Analyzer_Range
	var AnalyzerRangeCollisionShape = $Analyzer/CollisionShape2D
	var AnalyzerRangeIndicatorDescriptor = $Analyzer/Analyzer_Range/Label2
	#scalling collision
	(AnalyzerRangeCollisionShape.shape as CircleShape2D).radius = rang
	#scalling of collor rect
	AnalyzerRangeIndicator.size = Vector2(rang, rang) * 2
	#centering of color rect
	AnalyzerRangeIndicator.position = Vector2(-(rang), -(rang))
	#dissable descriptor when indicator gets to small
	AnalyzerRangeIndicatorDescriptor.visible = rang > 100
	
func ShowingNotif() -> bool:
	return $Notifications.get_child_count() > 0
func OnStatLow(StatName : String) -> void:
	if (!LowStatsToNotifyAbout.has(StatName)):
		return
	var notif = (load("res://Scenes/LowStatNotif.tscn") as PackedScene).instantiate() as LowStatNotif
	notif.SetStatData(StatName)
	notif.rotation = -rotation
	$Notifications.add_child(notif)


func _physics_process(_delta: float) -> void:
	if ($Node2D.position.x == 0):
		return
	var fuel = $Node2D.position.x / 10 / ShipData.GetInstance().GetStat("FUEL_EFFICIENCY").GetStat()
	var Dat = ShipData.GetInstance()
	if (Dat.GetStat("FUEL").GetCurrentValue() < fuel):
		HaltShip()
		PopUpManager.GetInstance().DoPopUp("You have run out of fuel.")
		#set_physics_process(false)
		return
	if (Dat.GetStat("CRYO").GetStat() == 0):
		var oxy = $Node2D.position.x / 100
		if (Dat.GetStat("OXYGEN").GetCurrentValue() < oxy):
			HaltShip()
			PopUpManager.GetInstance().DoPopUp("You have run out of oxygen.")
			#set_physics_process(false)
			return
		Dat.RefilResource("OXYGEN", -oxy)
	global_position = $Node2D.global_position
	Dat.ConsumeResource("FUEL", fuel)
	UpdateFuelRange(Dat.GetStat("FUEL").GetCurrentValue(), Dat.GetStat("FUEL_EFFICIENCY").GetStat())

func GetShipSpeed() -> float:
	return $Node2D.position.x
func GetShipSpeedVec() -> Vector2:
	return $Node2D.global_position - global_position

func HaltShip():
	Travelling = false
	set_physics_process(false)
	
	$Node2D.position.x = 0
	#$AudioStreamPlayer2D.stop()
	AccelerationChanged(0)
	ChangingCourse = false
	ShipForceStopped.emit()
	
func SteerChanged(value: float) -> void:
	Steer(deg_to_rad(value))

func AccelerationChanged(value: float) -> void:
	var Audioween = create_tween()
	Audioween.set_trans(Tween.TRANS_EXPO)
	Audioween.tween_property($AudioStreamPlayer2D, "pitch_scale", max(0.1,value / 100), 2)
	ChangingCourse = true
	if (!$AudioStreamPlayer2D.playing):
		$AudioStreamPlayer2D.play()
	if (value <= 0):
		Travelling = false
		#set_physics_process(false)
		#$AudioStreamPlayer2D.stop()
		$GPUParticles2D.emitting = false
		ShipStopped.emit()
		#return
	else:
		$GPUParticles2D.emitting = true
		Travelling = true
		set_physics_process(true)
		ShipAccelerating.emit()
	var postween = create_tween()
	postween.set_trans(Tween.TRANS_EXPO)
	postween.tween_property($Node2D, "position", Vector2(max(0,value / 300), 0), 2)
	
func AccelerationEnded(_value_changed: bool) -> void:
	ChangingCourse = false
	
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
	$Fuel.monitorable = t
	$Analyzer.monitorable = t
	$Radar.monitorable = t
	$Radar/Radar_Range.visible = t
	$Fuel/Fuel_Range.visible = t
	$Analyzer/Analyzer_Range.visible = t

func UpdateShipIcon(Tex : Texture) -> void:
	$PlayerShipSpr.texture = Tex	

func _on_player_viz_notifier_screen_entered() -> void:
	ScreenEnter.emit()
func _on_player_viz_notifier_screen_exited() -> void:
	ScreenExit.emit()
