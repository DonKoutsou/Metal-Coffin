extends Camera2D

class_name ScreenCamera

#SCREEN SHAKE///////////////////////////////////
@export var GoingDownC : Curve
@export var Cabled : Array[TextureRect]
var GoDownValue = 1
var Shake = false
var GoingDown = false
var shakestr = 1.5

func _ready() -> void:
	$Shake.play()
	$Shake.stream_paused = true

func EnableShake(amm : float):
	for g in Cabled:
		g.ApplyShake(amm)
	Shake = true
	GoingDown= false
	#$AnimationPlayer.play("Damage")
	$Shake.stream_paused = false
	shakestr = max(amm, shakestr)
	GoDownValue = max(amm, GoDownValue)
func EnableMissileShake() -> void:
	for g in Cabled:
		g.ApplyShake(2)
	Shake = true
	if (!$AnimationPlayer.is_playing()):
		$AnimationPlayer.stop()
		$AnimationPlayer.play("Alarm")
	$Shake.stream_paused = false
	shakestr = max(1.5, shakestr)
	GoDownValue = 1
	GoingDown = true
func EnableDamageShake() -> void:
	for g in Cabled:
		g.ApplyShake(2)
	Shake = true
	$AnimationPlayer.stop()
	$AnimationPlayer.play("Damage")
	$Boom.play()
	$Shake.stream_paused = false
	shakestr = max(1.5, shakestr)
	GoDownValue = 2
	GoingDown = true
func DissableShake() -> void:
	GoingDown = true
	#GoDownValue = 1
func _physics_process(delta: float) -> void:
	if (GoingDown):
		GoDownValue -= delta / 4
		shakestr = 1.5 * GoingDownC.sample(GoDownValue / 2)
		
	if Shake:
		$Shake.volume_db =  min(10, 20 * GoingDownC.sample(GoDownValue / 2) - 10)
		if (shakestr <= 0):
			#$AnimationPlayer.stop()
			Shake = false
			GoingDown = false
			#shakestr = 1.5
			$Shake.stream_paused = true
		var of = RandomOffset()
		offset = of
func RandomOffset()-> Vector2:
	return Vector2(randf_range(-shakestr, shakestr), randf_range(-shakestr, shakestr))
var stattween : Tween
