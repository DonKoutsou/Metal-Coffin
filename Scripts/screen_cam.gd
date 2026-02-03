extends Camera2D

class_name ScreenCamera

@export var EventHandler : UIEventHandler
@export var GoingDownC : Curve
@export_group("Nodes")
@export var Anim : AnimationPlayer
@export var LightPivot1 : Node2D
@export var ShakeSound : AudioStreamPlayer
@export var BoomSound : AudioStreamPlayer


#Starting Position of camera
var OriginalPos : Vector2
#Position shake sound currently at
var ShakePos : float


var GoDownValue = 1
var Shake = false
var GoingDown = false
var shakestr = 1.5

static var ShakeEffects : bool = true

func _ready() -> void:
	EventHandler.Shake.connect(EnableShake)
	EventHandler.DissableShake.connect(DissableShake)
	EventHandler.DamageShake.connect(EnableDamageShake)
	EventHandler.Storm.connect(EnableStormShake)
	EventHandler.MissileShake.connect(EnableMissileShake)
	ShakeSound.play()
	PauseShake(true)
	OriginalPos = position
	

func PauseShake(t : bool) -> void:
	if t:
		if (ShakeSound.playing):
			ShakePos = ShakeSound.get_playback_position()
			ShakeSound.stop() 
	else:
		if (!ShakeSound.playing):
			ShakeSound.play()
			ShakeSound.seek(ShakePos) 


func EnableShake(amm : float):
	if (!ShakeEffects):
		return
	for g in get_tree().get_nodes_in_group("Shakable"):
		g.ApplyShake(amm)
	LightPivot1.ApplyShake(amm)
	Shake = true
	GoingDown= false
	PauseShake(false)
	shakestr = max(amm, shakestr)
	GoDownValue = max(amm, GoDownValue)


func EnableStormShake(amm : float) -> void:
	if (!ShakeEffects):
		return
	for g in get_tree().get_nodes_in_group("Shakable"):
		g.ApplyShake(amm)
#	Anim.play("Damage")
	LightPivot1.ApplyShake(amm)
	Shake = true
	
	PauseShake(false)
	
	shakestr = max(amm, shakestr)
	GoDownValue = amm

	GoingDown = true


func EnableMissileShake() -> void:
	if (!ShakeEffects):
		return
	for g in get_tree().get_nodes_in_group("Shakable"):
		g.ApplyShake(2)
	LightPivot1.ApplyShake(1)
	Shake = true
	if (!Anim.is_playing()):
		Anim.stop()
		Anim.play("Alarm")
	PauseShake(false)
	
	shakestr = max(1.5, shakestr)
	GoDownValue = 1

	GoingDown = true
	
	
func EnableDamageShake(amm : float) -> void:
	if (!ShakeEffects):
		return
	for g in get_tree().get_nodes_in_group("Shakable"):
		g.ApplyShake(min(2, amm))
	LightPivot1.ApplyShake(min(2, amm))
	Shake = true
	Anim.stop()
	Anim.play("Damage")
	BoomSound.play()
	PauseShake(false)
	shakestr = max(min(2, amm), shakestr)
	GoDownValue = max(min(2, amm), GoDownValue)
	GoingDown = true


func EnableFullScreenShake() -> void:
	if (!ShakeEffects):
		return
	for g in get_tree().get_nodes_in_group("Shakable"):
		g.ApplyShake(2)
	LightPivot1.ApplyShake(1)
	Shake = true
	PauseShake(false)
	shakestr = max(1.5, shakestr)
	GoDownValue = 0.5
	GoingDown = true
	
	
func DissableShake() -> void:
	GoingDown = true
	#GoDownValue = 1
	
	
func _physics_process(delta: float) -> void:
	if (GoingDown):
		GoDownValue -= delta / 4
		shakestr = 1.5 * GoingDownC.sample(GoDownValue / 2)
	
	_breath_time += delta
	
	offset = RandomOffset2(offset)
	
	if Shake:
		ShakeSound.volume_db =  min(5, 20 * GoingDownC.sample(GoDownValue / 2) - 10)
		if (shakestr <= 0):
			#$AnimationPlayer.stop()
			Shake = false
			GoingDown = false
			#shakestr = 1.5
			PauseShake(true)
		var of = RandomOffset()
		offset += of


func RandomOffset2(Last : Vector2) -> Vector2:
	var x = clamp(randf_range(Last.x - 0.1, Last.x + 0.1), -1, 1)
	var y = get_breath_offset()

	return Vector2(x,y);


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
