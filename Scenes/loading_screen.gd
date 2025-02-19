extends CanvasLayer

class_name LoadingScreen


func _ready() -> void:
	$AnimationPlayer.play("Logo")

func UpdateProgress(Precent : float) -> void:
	var tw = create_tween()
	tw.tween_property($ProgressBar, "value", Precent, 1)
	#$ProgressBar.value = Precent

func StartDest():
	var t = Timer.new()
	t.wait_time = 1
	t.autostart = true
	add_child(t)
	await t.timeout
	queue_free()
