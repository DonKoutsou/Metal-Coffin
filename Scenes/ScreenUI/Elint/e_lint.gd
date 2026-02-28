extends BasePilotScreenInterface
class_name ElingUI

##    --- EXPORTS / INSPECTOR SETUP ---
@export_group("Files")
@export_file var directionMaskFiles: Array[String]
@export_file("*.png") var distanceMasks: Array[String]
@export_file("*.png") var onOffTextures: Array[String]

@export_group("Nodes")
@export var rangeIndicator: PointLight2D
@export var alertLight: PointLight2D
@export var dangerCloseLight: PointLight2D
@export var directionLight: PointLight2D
@export var elintText: TextureRect
@export var beepSound: AudioStreamPlayer2D

@export_group("Sounds")
@export var alarm: AudioStream
@export var beep: AudioStream

##    --- STATE VARIABLES ---

var lights: Array[Light2D] = []         # All Light2D children to be toggled.
var foundContact: bool = false          # Is a contact found currently?
var currentState: ElintState            # Current detection state

# Time accumulator for physics polling
var pollDelay: float = 0.4

# ELINT detection states
enum ElintState {
	NONE,
	CLOSE,
	MEDIUM,
	FAR,
}

##    --- SCENE LIFECYCLE ---

func _ready() -> void:
	super()
	# Gather Light2Ds under this node and hide
	for node in get_children():
		if node is Light2D:
			lights.append(node)
			node.visible = false

##    --- PUBLIC / SIGNAL API ---

func toggleElint(isOn: bool) -> void:
	# Toggle UI and process based on ELINT presence
	var texPath = onOffTextures[0] if isOn else onOffTextures[1]
	elintText.texture = ResourceLoader.load(texPath)
	set_physics_process(isOn)

func _onControlledShipUpdated(ship: MapShip) -> void:
	controller = ship
	var hasElint = fleetHasElint()
	toggleElint(hasElint)
	if not hasElint:
		for l in lights:
			l.visible = false

func _onDroneAdded(_dr : Drone, target : MapShip) -> void:
	if (target == controller):
		var hasElint = fleetHasElint()
		toggleElint(hasElint)
		if not hasElint:
			for l in lights:
				l.visible = false

func _onDroneRemoved(_dr : Drone, target : MapShip) -> void:
	if (target == controller):
		var hasElint = fleetHasElint()
		toggleElint(hasElint)
		if not hasElint:
			for l in lights:
				l.visible = false

func fleetHasElint() -> bool:
	# Check if the currently controlled ship or its docked drones have ELINT
	if controller.Cpt.GetStatFinalValue(STAT_CONST.STATS.ELINT) > 0:
		return true
	for c: Captain in controller.GetDroneDock().GetCaptains():
		if c.GetStatFinalValue(STAT_CONST.STATS.ELINT) > 0:
			return true
	return false

##    --- PHYSICS UPDATE (PERIODIC POLLING) ---

func _physics_process(delta: float) -> void:
	pollDelay -= delta
	if pollDelay > 0:
		return
	pollDelay = 0.4

	var elintLevel = controller.GetClosestElintLevel()

	if elintLevel < 0:
		currentState = ElintState.NONE
		foundContact = false
		for l in lights:
			l.visible = false
		return

	if not foundContact:
		RadioSpeaker.GetInstance().PlaySound(RadioSpeaker.RadioSound.ELINT_DETECTED)

	foundContact = true
	setDirection(rad_to_deg(controller.global_position.angle_to_point(controller.GetClosestElint())) + 180)
	setElintLevel(elintLevel)

	for l in lights:
		l.visible = not l.visible

	if currentState != ElintState.NONE:
		beepSound.play()

##    --- UI/LOGIC HELPERS ---

func setDirection(dir: float) -> void:
	# Selects correct direction texture for indicator according to angle
	for i in directionMaskFiles.size():
		if abs((i * 30) - dir) > 15:
			continue
		directionLight.texture = ResourceLoader.load(directionMaskFiles[roundi(i)])
		break

static func degreesToElintAngle(degrees: float) -> int:
	# Maps a degree to the nearest elint direction (0, 30, ..., 330)
	var dirs = [0, 30, 60, 90, 120, 150, 180, 210, 240, 270, 300, 330]
	for i in dirs.size():
		if abs(dirs[i] - degrees) > 15:
			continue
		return dirs[i]
	return 0

func setElintLevel(elintLevel: int) -> void:
	# Switches range indicator, alert light, and beep based on elint proximity
	match elintLevel:
		3:
			if currentState != ElintState.CLOSE:
				currentState = ElintState.CLOSE
				rangeIndicator.texture = ResourceLoader.load(distanceMasks[2])
				if not lights.has(dangerCloseLight):
					lights.append(dangerCloseLight)
				dangerCloseLight.visible = directionLight.visible
				beepSound.stream = alarm
				beepSound.pitch_scale = 4

		2:
			if currentState != ElintState.MEDIUM:
				currentState = ElintState.MEDIUM
				rangeIndicator.texture = ResourceLoader.load(distanceMasks[1])
				lights.erase(dangerCloseLight)
				dangerCloseLight.visible = false
				beepSound.stream = beep
				beepSound.pitch_scale = 1

		1:
			if currentState != ElintState.FAR:
				currentState = ElintState.FAR
				rangeIndicator.texture = ResourceLoader.load(distanceMasks[0])
				lights.erase(dangerCloseLight)
				dangerCloseLight.visible = false
				beepSound.stream = beep
				beepSound.pitch_scale = 1

func _getInterfaceName() -> String:
	return "ELint"

##    --- UNUSED / DEVELOPMENT ---

#func updateBasedOnMouse() -> void:
#    var mpos = get_global_mouse_position()
#    var pos = global_position + (size / 2)
#    var ang = (rad_to_deg(pos.angle_to_point(mpos))) + 180
#    setDirection(ang)
#    setDistance(pos.distance_squared_to(mpos))
