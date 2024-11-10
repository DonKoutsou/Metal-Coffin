extends AnimatedSprite2D

signal RangeChanged(NewVal : float)

var framecount : int
var accumulatedrel : float
func _ready() -> void:
	framecount = sprite_frames.get_frame_count("default")

func _on_control_gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseMotion and Input.is_action_pressed("Click")):
		var rel = event.relative
		accumulatedrel += rel.x
		if (abs(accumulatedrel) < 40):
			return
		if (accumulatedrel > 0):
			RangeChanged.emit(1)
			$AudioStreamPlayer.play()
			Input.vibrate_handheld(30)
			if (frame + 1 == framecount):
				frame = 0
			else:
				frame += 1
		else: if (accumulatedrel < 0):
			$AudioStreamPlayer.play()
			Input.vibrate_handheld(30)
			RangeChanged.emit(-1)
			if (frame == 0):
				frame = framecount - 1
			else:
				frame -= 1
		
		accumulatedrel = 0
	if (event is InputEventScreenDrag):
		var rel = event.relative
		accumulatedrel += rel.x
		if (abs(accumulatedrel) < 40):
			return
		if (accumulatedrel > 0):
			RangeChanged.emit(1)
			$AudioStreamPlayer.play()
			Input.vibrate_handheld(30)
			if (frame + 1 == framecount):
				frame = 0
			else:
				frame += 1
		else: if (accumulatedrel < 0):
			$AudioStreamPlayer.play()
			Input.vibrate_handheld(30)
			RangeChanged.emit(-1)
			if (frame == 0):
				frame = framecount - 1
			else:
				frame -= 1
		
		accumulatedrel = 0
