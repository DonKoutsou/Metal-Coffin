extends Node2D

class_name PlayerShip

@export var LowStatsToNotifyAbout : Array[String]

var Travelling = false
var ChangingCourse = false

signal ScreenEnter()
signal ScreenExit()

signal ShipStopped
signal ShipAccelerating
signal ShipForceStopped

func _ready() -> void:
	#set_physics_process(false)
	pass
func UpdateFuelRange(fuel : float, fuel_ef : float):
	var distall = fuel * 10 * fuel_ef
	$Fuel/Fuel_Range.size = Vector2(distall, distall) * 2
	$Fuel/Fuel_Range/Label.visible = distall > 100
	$Fuel/Fuel_Range.position = Vector2(-(distall), -(distall))
	#($Fuel/Fuel_Range.material as ShaderMaterial).set_shader_parameter("line_width", distall * 0.000017)
func UpdateVizRange(rang : float):
	($Radar/CollisionShape2D.shape as CircleShape2D).radius = rang
	$Radar/Radar_Range.size = Vector2(rang, rang) * 2
	$Radar/Radar_Range/Label2.visible = rang > 100
	$Radar/Radar_Range.position = Vector2(-(rang), -(rang))
	#($Radar/Radar_Range.material as ShaderMaterial).set_shader_parameter("line_width", rang * 0.000017)
func UpdateAnalyzerRange(rang : float):
	($Analyzer/CollisionShape2D.shape as CircleShape2D).radius = rang
	$Analyzer/Analyzer_Range.size = Vector2(rang, rang) * 2
	$Analyzer/Analyzer_Range/Label2.visible = rang > 100
	$Analyzer/Analyzer_Range.position = Vector2(-(rang), -(rang))
	#($Analyzer/Analyzer_Range.material as ShaderMaterial).set_shader_parameter("line_width", rang * 0.000017)
func ShowingNotif() -> bool:
	return $Notifications.get_child_count() > 0
func OnStatLow(StatName : String) -> void:
	if (!LowStatsToNotifyAbout.has(StatName)):
		return
	var notif = (load("res://Scenes/LowStatNotif.tscn") as PackedScene).instantiate() as LowStatNotif
	notif.SetStatData(StatName)
	notif.rotation = -rotation
	$Notifications.add_child(notif)
func UpdateShipIcon(Tex : Texture) -> void:
	$PlayerShipSpr.texture = Tex
func _on_player_viz_notifier_screen_entered() -> void:
	ScreenEnter.emit()

func _on_player_viz_notifier_screen_exited() -> void:
	ScreenExit.emit()

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
		var oxy = global_position.distance_to($Node2D.global_position) / 100
		if (Dat.GetStat("OXYGEN").GetCurrentValue() < oxy):
			HaltShip()
			PopUpManager.GetInstance().DoPopUp("You have run out of oxygen.")
			#set_physics_process(false)
			return
		Dat.RefilResource("OXYGEN", -oxy)
	global_position = $Node2D.global_position
	Dat.ConsumeResource("FUEL", fuel)
	UpdateFuelRange(Dat.GetStat("FUEL").GetCurrentValue(), Dat.GetStat("FUEL_EFFICIENCY").GetStat())

func HaltShip():
	Travelling = false
	set_physics_process(false)
	ChangingCourse = false
	$Node2D.position.x = 0
	$AudioStreamPlayer2D.stop()
	ShipForceStopped.emit()
	
func SteerChanged(value: float) -> void:
	Steer(deg_to_rad(value))

func AccelerationChanged(value: float) -> void:
	if (!$AudioStreamPlayer2D.playing):
		$AudioStreamPlayer2D.play()
	var Audioween = create_tween()
	Audioween.tween_property($AudioStreamPlayer2D, "pitch_scale", max(0.1,value / 50), 2)
	ChangingCourse = true

	if (value <= 0):
		Travelling = false
		#set_physics_process(false)
		$AudioStreamPlayer2D.stop()
		$GPUParticles2D.emitting = false
		ShipStopped.emit()
		#return
	else:
		$GPUParticles2D.emitting = true
		Travelling = true
		set_physics_process(true)
		ShipAccelerating.emit()
	var postween = create_tween()
	postween.tween_property($Node2D, "position", Vector2(max(0,value / 100), 0), 2)
	
func AccelerationEnded(_value_changed: bool) -> void:
	ChangingCourse = false	
	
signal OnLookAtEnded()
func LookAtEnded():
	OnLookAtEnded.emit()
	
func PlayerLookAt(LookPos : Vector2) -> void:
	var tw = create_tween()
	tw.tween_property(self, "rotation", position.angle_to_point(LookPos), 1)
	tw.connect("finished", LookAtEnded)
	
func Steer(Rotation : float) -> void:
	var tw = create_tween()
	tw.tween_property(self, "rotation", Rotation, 1)
