extends Camera2D

class_name ScreenCamera

#SCREEN SHAKE///////////////////////////////////
@export var GoingDownC : Curve
@export var Cabled : Array[Node]
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
	for g in Cabled:
		g.ApplyShake(amm)
	$LightPivot1.ApplyShake(amm)
	Shake = true
	GoingDown= false
	PauseShake(false)
	shakestr = max(amm, shakestr)
	GoDownValue = max(amm, GoDownValue)
	#var Tw = create_tween()
	#Tw.set_ease(Tween.EASE_OUT)
	#Tw.set_trans(Tween.TRANS_QUAD)
	#Tw.tween_property(self, "shakestr", max(amm, shakestr), 1)
#
	#var Tw2 = create_tween()
	#Tw2.set_ease(Tween.EASE_OUT)
	#Tw2.set_trans(Tween.TRANS_QUAD)
	#Tw2.tween_property(self, "GoDownValue", max(amm, GoDownValue), 1)

func EnableMissileShake() -> void:
	for g in Cabled:
		g.ApplyShake(2)
	$LightPivot1.ApplyShake(1)
	Shake = true
	if (!$AnimationPlayer.is_playing()):
		$AnimationPlayer.stop()
		$AnimationPlayer.play("Alarm")
	PauseShake(false)
	
	shakestr = max(1.5, shakestr)
	GoDownValue = 1
	#var Tw = create_tween()
	#Tw.set_ease(Tween.EASE_OUT)
	#Tw.set_trans(Tween.TRANS_QUAD)
	#Tw.tween_property(self, "shakestr", max(1.5, shakestr),1)
#
	#var Tw2 = create_tween()
	#Tw2.set_ease(Tween.EASE_OUT)
	#Tw2.set_trans(Tween.TRANS_QUAD)
	#Tw2.tween_property(self, "GoDownValue", 1, 1)
	#
	#await Tw2.finished
	GoingDown = true
func EnableDamageShake(amm : float) -> void:
	for g in Cabled:
		g.ApplyShake(amm)
	$LightPivot1.ApplyShake(amm)
	Shake = true
	$AnimationPlayer.stop()
	$AnimationPlayer.play("Damage")
	$Boom.play()
	PauseShake(false)
	shakestr = max(amm, shakestr)
	GoDownValue = max(amm, GoDownValue)
	GoingDown = true
func DissableShake() -> void:
	GoingDown = true
	#GoDownValue = 1
func _physics_process(delta: float) -> void:
	if (GoingDown):
		GoDownValue -= delta / 4
		shakestr = 1.5 * GoingDownC.sample(GoDownValue / 2)
		
	if Shake:
		$Shake.volume_db =  min(5, 20 * GoingDownC.sample(GoDownValue / 2) - 10)
		if (shakestr <= 0):
			#$AnimationPlayer.stop()
			Shake = false
			GoingDown = false
			#shakestr = 1.5
			PauseShake(true)
		var of = RandomOffset()
		offset = of
func RandomOffset()-> Vector2:
	return Vector2(randf_range(-shakestr, shakestr), randf_range(-shakestr, shakestr))
var stattween : Tween
func EnableFullScreenShake() -> void:
	for g in Cabled:
		g.ApplyShake(2)
	$LightPivot1.ApplyShake(1)
	Shake = true
	PauseShake(false)
	shakestr = max(1.5, shakestr)
	GoDownValue = 0.5
	GoingDown = true
