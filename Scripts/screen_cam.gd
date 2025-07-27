extends Camera2D

class_name ScreenCamera

#SCREEN SHAKE///////////////////////////////////
@export var GoingDownC : Curve
var GoDownValue = 1
var Shake = false
var GoingDown = false
var shakestr = 1.5

var ShakePos
func PauseShake(t : bool) -> void:
	if t and $Shake.playing:
		ShakePos = $Shake.get_playback_position()
		$Shake.stop() 
	else: if !t and !$Shake.playing:
		$Shake.play()
		$Shake.seek(ShakePos) 

func _ready() -> void:
	$Shake.play()
	PauseShake(true)

func EnableShake(amm : float):
	for g in get_tree().get_nodes_in_group("Shakable"):
		g.ApplyShake(amm)
	$LightPivot1.ApplyShake(amm)
	Shake = true
	GoingDown= false
	PauseShake(false)
	shakestr = max(amm, shakestr)
	GoDownValue = max(amm, GoDownValue)

func EnableStormShake(amm : float) -> void:
	for g in get_tree().get_nodes_in_group("Shakable"):
		g.ApplyShake(amm)
	$LightPivot1.ApplyShake(amm)
	Shake = true
	#if (!$AnimationPlayer.is_playing()):
		#$AnimationPlayer.stop()
		#$AnimationPlayer.play("Alarm")
	PauseShake(false)
	
	shakestr = max(amm, shakestr)
	GoDownValue = amm

	GoingDown = true

func EnableMissileShake() -> void:
	for g in get_tree().get_nodes_in_group("Shakable"):
		g.ApplyShake(2)
	$LightPivot1.ApplyShake(1)
	Shake = true
	if (!$AnimationPlayer.is_playing()):
		$AnimationPlayer.stop()
		$AnimationPlayer.play("Alarm")
	PauseShake(false)
	
	shakestr = max(1.5, shakestr)
	GoDownValue = 1

	GoingDown = true
	
func EnableDamageShake(amm : float) -> void:
	for g in get_tree().get_nodes_in_group("Shakable"):
		g.ApplyShake(min(2, amm))
	$LightPivot1.ApplyShake(min(2, amm))
	Shake = true
	$AnimationPlayer.stop()
	$AnimationPlayer.play("Damage")
	$Boom.play()
	PauseShake(false)
	shakestr = max(min(2, amm), shakestr)
	GoDownValue = max(min(2, amm), GoDownValue)
	GoingDown = true
func DissableShake() -> void:
	GoingDown = true
	#GoDownValue = 1
func _physics_process(delta: float) -> void:
	if (GoingDown):
		GoDownValue -= delta / 4
		shakestr = 1.5 * GoingDownC.sample(GoDownValue / 2)
	
	_breath_time += delta
	
	offset = RandomOffset2()
	
	if Shake:
		$Shake.volume_db =  min(5, 20 * GoingDownC.sample(GoDownValue / 2) - 10)
		if (shakestr <= 0):
			#$AnimationPlayer.stop()
			Shake = false
			GoingDown = false
			#shakestr = 1.5
			PauseShake(true)
		var of = RandomOffset()
		offset = prev + of

var prev : Vector2 = Vector2.ZERO

func RandomOffset2() -> Vector2:
	var x = clamp(randf_range(prev.x - 0.1, prev.x + 0.1), -1, 1)
	var y = get_breath_offset()

	prev = Vector2(x,y)
	return prev;

@export_group("Breath")
@export var breath_amplitude : float = 10.0 # How far up/down the camera moves
@export var breath_duration  : float = 2.0  # Time in seconds for a full cycle (in and out)
@export var curve_power     : float = 2.0  # Exponent for extra easing (try 2..4)

var _breath_time : float = 0.0

func get_breath_offset() -> float:
	var t = fmod(_breath_time, breath_duration) / breath_duration  # 0..1 over the cycle
	# Sine wave between 0..1 (not -1..1): sin( t * PI * 2 ) * 0.5 + 0.5
	var sin_val = sin(t * PI * 2) * 0.5 + 0.5
	# Exaggerate easing
	var eased = pow(sin_val, curve_power)
	# Remap from 0..1 to -1..1
	var y = (eased - 0.5) * 2.0
	return y * breath_amplitude

func RandomOffset()-> Vector2:
	return Vector2(randf_range(-shakestr, shakestr), randf_range(-shakestr, shakestr))
var stattween : Tween
func EnableFullScreenShake() -> void:
	for g in get_tree().get_nodes_in_group("Shakable"):
		g.ApplyShake(2)
	$LightPivot1.ApplyShake(1)
	Shake = true
	PauseShake(false)
	shakestr = max(1.5, shakestr)
	GoDownValue = 0.5
	GoingDown = true
