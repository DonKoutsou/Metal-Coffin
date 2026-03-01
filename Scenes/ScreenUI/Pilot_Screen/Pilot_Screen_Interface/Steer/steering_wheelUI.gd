extends BasePilotScreenInterface
class_name SteeringWheelUI

# --- EXPORTED VARIABLES ---

@export var positionOnStart: bool = true

# --- STATE VARIABLES ---

var steeringDir: float = 0.0
var previousMouseAngle: float = 0.0
var distanceTraveled: float = 0.0
var moveTween: Tween = null
var currentSteerRot: float = 0.0
var forceTween: Tween = null
var syncing: bool = false

# --- TOGGLE VISIBILITY WITH ANIMATION ---

func Toggle(isOpen: bool) -> void:
	if (moveTween != null):
		moveTween.kill()
	if (!isOpen):
		moveTween = create_tween()
		moveTween.set_ease(Tween.EASE_IN)
		moveTween.set_trans(Tween.TRANS_BACK)
		moveTween.tween_property(self, "position", Vector2(-size.x, position.y), 0.5)
	else:
		moveTween = create_tween()
		moveTween.set_ease(Tween.EASE_OUT)
		moveTween.set_trans(Tween.TRANS_BACK)
		moveTween.tween_property(self, "position", Vector2(-size.x / 2, position.y), 0.5)

# --- INITIALIZATION AND SIGNALS ---

func _ready() -> void:
	super()
	uiEventHandler.SteerForced.connect(shipSteerForced)
	uiEventHandler.SteerSet.connect(shipSteerSet)
	set_physics_process(false)
	# Optionally set position on start here, if enabled

func _onControlledShipUpdated(newController: PlayerDrivenShip) -> void:
	super(newController)
	SyncSteer(controller.rotation + controller.StoredSteer)

# --- EVENT HANDLERS ---

func shipSteerSet(newValue: float) -> void:
	ForceSteer(newValue)

func shipSteerForced(newValue: float) -> void:
	ForceSteer(newValue)

# --- INPUT/STEERING LOGIC ---

func UpdateSteer(relativeRot: Vector2, eventPos: Vector2) -> void:
	var rel = clamp(relativeRot / 10, Vector2(-0.3, -0.3), Vector2(0.3, 0.3))
	set_physics_process(true)
	if eventPos.x < position.x:
		steeringDir += rel.x - rel.y
	else:
		steeringDir += rel.x + rel.y

func UpdateSteerFloat(dir: float) -> void:
	set_physics_process(true)
	steeringDir += dir * 10

func ForceSteer(val: float) -> void:
	if syncing:
		return
	currentSteerRot = val
	steeringDir = 0.0

func SyncSteer(val: float) -> void:
	currentSteerRot = val
	steeringDir = 0.0
	# Optionally add smooth tweening for UI feedback

func RotateTexture(newRot: float) -> void:
	var amount = newRot - $TextureRect.rotation
	SteerRotated(amount)
	currentSteerRot = newRot

func SteerRotated(amount: float) -> void:
	distanceTraveled += abs(amount)
	if distanceTraveled > 0.2:
		distanceTraveled = 0
		$AudioStreamPlayer.play()
		Input.vibrate_handheld(30)

func CopyShipSteer(ship: MapShip) -> void:
	$TextureRect.rotation = ship.rotation

# --- FRAME/PHYSICS LOGIC ---

func _process(delta: float) -> void:
	var newRot = lerp_angle($TextureRect.rotation, currentSteerRot * 10, delta * 4)
	var amount = newRot - $TextureRect.rotation
	$TextureRect.rotation = newRot
	SteerRotated(amount)

func _physics_process(_delta: float) -> void:
	steeringDir = lerp(steeringDir, 0.0, 0.2)
	steerOffseted(steeringDir)
	steeringDirectionChanged(steeringDir)
	if abs(steeringDir) < 0.001:
		set_physics_process(false)

# --- UI EVENT CALLBACKS TO APP LOGIC ---

func steeringDirectionChanged(value: float) -> void:
	uiEventHandler.OnSteeringDirectionChanged(value)

func steerOffseted(offset: float) -> void:
	uiEventHandler.OnSteerOffseted(offset)

# --- UI INPUT ---

func _on_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventScreenDrag:
		UpdateSteer(event.relative, event.position)
	elif event is InputEventMouseMotion and Input.is_action_pressed("Click"):
		UpdateSteer(event.relative, event.position)

func _on_texture_rect_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenDrag:
		UpdateSteer(event.relative, event.position)
	elif event is InputEventMouseMotion and Input.is_action_pressed("Click"):
		UpdateSteer(event.relative, event.position)

	var axis = Input.get_axis("ZoomIn", "ZoomOut")
	if axis != 0:
		UpdateSteerFloat(axis * 0.4)

# --- OPTIONAL INTERFACE/UTILITY ---

func _getInterfaceName() -> String:
	return "Steer"
