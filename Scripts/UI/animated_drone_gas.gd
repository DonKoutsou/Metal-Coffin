extends AnimatedSprite2D
class_name Dial

@export var Sound: AudioStreamPlayer2D

signal RangeChanged(newValue: float)
signal RangeSnappedChanged(direction: bool)

var frameCount: int = 0

var accumulatedRel: float = 0
var customAccumulated: float = 0

var distanceTraveled: float = 0
var customDistanceTraveled: float = 0

func _ready() -> void:
	frameCount = sprite_frames.get_frame_count("default")
	set_physics_process(false)
	Sound.pitch_scale = randf_range(0.8, 1.2)

func get_global_rect() -> Rect2:
	var rect: Rect2 = $Control.get_global_rect()
	if rotation != 0:
		var size = rect.size
		rect.size.x = size.y
		rect.size.y = size.x
	return rect

func _physics_process(_delta: float) -> void:
	# Always smooth down both values
	var wasActive := false

	if abs(accumulatedRel) > 0.0001:
		_processAccumulation()
		wasActive = true
	else:
		accumulatedRel = 0

	if abs(customAccumulated) > 0.0001:
		_processCustomAccumulation()
		wasActive = true
	else:
		customAccumulated = 0

	# Only stop processing when both are at rest
	if not wasActive:
		set_physics_process(false)

func _processAccumulation() -> void:
	distanceTraveled += abs(accumulatedRel)
	accumulatedRel = lerp(accumulatedRel, 0.0, 0.2)
	RangeChanged.emit(accumulatedRel * 2)

	if distanceTraveled > 1:
		distanceTraveled = 0
		Sound.play()
		Input.vibrate_handheld(10)
		var direction = accumulatedRel > 0
		RangeSnappedChanged.emit(direction)
		if direction:
			frame = (frame + 1) % frameCount
		else:
			frame = (frame - 1 + frameCount) % frameCount

func _processCustomAccumulation() -> void:
	customDistanceTraveled += abs(customAccumulated)
	customAccumulated = lerp(customAccumulated, 0.0, 0.2)

	if customDistanceTraveled > 1:
		customDistanceTraveled = 0
		Sound.play()
		Input.vibrate_handheld(10)
		var direction = customAccumulated > 0
		# For custom movement, you may not want to emit RangeSnappedChanged, 
		# but add it if needed
		if direction:
			frame = (frame + 1) % frameCount
		else:
			frame = (frame - 1 + frameCount) % frameCount

func addCustomMovement(value: float) -> void:
	customAccumulated += value
	set_physics_process(true)

func _on_Control_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.is_action_pressed("Click"):
		_handleMouseMotion(event)
	elif event is InputEventScreenDrag:
		_handleScreenDrag(event)
	elif event.is_action_pressed("ZoomOut"):
		accumulatedRel += 0.2
		set_physics_process(true)
	elif event.is_action_pressed("ZoomIn"):
		accumulatedRel -= 0.2
		set_physics_process(true)

func _handleMouseMotion(event: InputEventMouseMotion) -> void:
	var rel = clamp(event.relative / 100, Vector2(-0.3, -0.3), Vector2(0.3, 0.3))
	accumulatedRel += rel.x
	set_physics_process(true)

func _handleScreenDrag(event: InputEventScreenDrag) -> void:
	var rel = clamp(event.relative / 100, Vector2(-0.3, -0.3), Vector2(0.3, 0.3))
	accumulatedRel += rel.x
	set_physics_process(true)
