extends BasePilotScreenInterface
class_name ThrustSlider

# --- EXPORTED VARIABLES ---
@export var handle: TextureRect
@export var stepCount: int = 10
@export var controlType: ThrustControl
enum ThrustControl {
	ELEVATION,
	SPEED
}

# --- STATE VARIABLES ---
var maxVelocityLoc: float = 0
var minVelocityLoc: float = 0
var step: float = 0
var accumulatedRelative: float = 0.0
var forceTween: Tween = null

# --- INITIALIZATION ---

func _ready() -> void:
	minVelocityLoc = size.y - (handle.size.y / 2)
	zeroAcceleration()
	maxVelocityLoc = 0.0
	step = (minVelocityLoc - maxVelocityLoc) / stepCount
	super()
	
	match controlType:
		ThrustControl.ELEVATION:
			uiEventHandler.ElevationForced.connect(forceValue)
			# uiEventHandler.ElevationSet.connect(shipElevationSet)
		ThrustControl.SPEED:
			uiEventHandler.SpeedForced.connect(forceValue)
			uiEventHandler.SpeedSet.connect(updateHandle)

# --- STATE/SHIP HANDLING ---

func _onControlledShipUpdated(newController: PlayerDrivenShip) -> void:
	super(newController)
	match controlType:
		ThrustControl.ELEVATION:
			forceValue(controller.TargetAltitude / 10000)  # Assume altitude scaling
		ThrustControl.SPEED:
			forceValue((controller.GetCurrentAcceleration() * 360) / controller.GetShipMaxSpeed())

func zeroAcceleration() -> void:
	handle.position.y = minVelocityLoc

# --- HANDLE ANIMATED TWEENS ---

func forceValue(val: float) -> void:
	var forcedValue = clamp(val, 0.0, 1.0)
	var newPosY = forcedValue * (maxVelocityLoc - minVelocityLoc) + minVelocityLoc
	if forceTween:
		forceTween.kill()
	forceTween = create_tween()
	forceTween.set_ease(Tween.EASE_OUT)
	forceTween.set_trans(Tween.TRANS_QUINT)
	var newPosition = Vector2(handle.position.x, newPosY)
	# Tween method instead of direct set for smooth animation
	forceTween.tween_method(updateHandlePosition, handle.position, newPosition, newPosition.distance_squared_to(handle.position) / 100000.0)

func updateHandle(val: float) -> void:
	var forcedValue = clamp(val, 0.0, 1.0)
	var newPosY = forcedValue * (maxVelocityLoc - minVelocityLoc) + minVelocityLoc
	handle.position = Vector2(handle.position.x, newPosY)

func updateHandlePosition(newPos: Vector2) -> void:
	if not $AudioStreamPlayer.playing:
		$AudioStreamPlayer.play()
		Input.vibrate_handheld(30)
	handle.position = newPos

func getThrustPosition() -> Vector2:
	return handle.global_position

# --- PHYSICS PROCESS: TICKING WHILE DRAGGING ---

func _physics_process(_delta: float) -> void:
	if abs(accumulatedRelative) < step:
		thrustChangeEnded(0)
		set_physics_process(false)
		return
	var newPosY: float
	if accumulatedRelative > 0:
		newPosY = clamp(handle.position.y + step, maxVelocityLoc, minVelocityLoc)
		accumulatedRelative -= step
	else:
		newPosY = clamp(handle.position.y - step, maxVelocityLoc, minVelocityLoc)
		accumulatedRelative += step

	$AudioStreamPlayer.play()
	Input.vibrate_handheld(30)
	var newVal = snapped((newPosY - minVelocityLoc) / (maxVelocityLoc - minVelocityLoc), 0.01)
	thrustChanged(newVal)

# --- INPUT: MOUSE OR DRAG ---

func handleInput(event: InputEvent) -> void:
	if (event is InputEventMouseMotion and Input.is_action_pressed("Click")) or event is InputEventScreenDrag:
		accumulatedRelative += event.relative.y
		if abs(accumulatedRelative) > step:
			set_physics_process(true)

	if event.is_action_released("Click"):
		thrustChangeEnded(0)

# --- EMIT EVENTS TO GAME UI ---

func thrustChangeEnded(valueChanged: float) -> void:
	match controlType:
		ThrustControl.ELEVATION:
			uiEventHandler.OnElevationEnded(valueChanged)
		ThrustControl.SPEED:
			uiEventHandler.OnAccelerationEnded(valueChanged)

func thrustChanged(value: float) -> void:
	match controlType:
		ThrustControl.ELEVATION:
			uiEventHandler.OnElevationChanged(value)
			updateHandle(value)
		ThrustControl.SPEED:
			uiEventHandler.OnAccelerationChanged(value)

# --- UTILITY / INTERFACE ---

func _getInterfaceName() -> String:
	match controlType:
		ThrustControl.ELEVATION: 
			return "Elevation Lever"
		ThrustControl.SPEED: 
			return "Speed Lever"
		_: 
			return ""
