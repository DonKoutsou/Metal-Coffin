extends BasePilotScreenInterface
class_name AeroSonar

# --- EXPORTED PROPERTIES ---
@export var offsetAmount: float = 1.0

@export var lineContainer: AeroSonarLine
@export var sonarVisual: TextureRect
@export var gainLabel: Label
@export var radioSpeaker: RadioSpeaker
@export var cap: Panel
@export var toggleButton: Button

# --- STATE VARIABLES ---

var offset: float = 0.0
var currentAngle: float = 0.0
var currentOffset: float = 1.0
var working: bool = false
var enabled: bool = false
var volume: float = 1.0

# --- INITIALIZATION / SIGNAL CONNECTIONS ---

func _ready() -> void:
	super()
	lineContainer.Found.connect(_onSignalFound)
	
	set_physics_process(false)
	lineContainer.visible = false
	gainLabel.visible = false

# --- FLEET AND DRONE DOCK MANAGEMENT ---

func _onDroneAdded(_drone: Drone, target: MapShip) -> void:
	if target == controller:
		var hasSonar = fleetHasAeroSonar()
		cap.visible = !hasSonar
		if !hasSonar and enabled:
			toggleSonar(false)

func _onDroneRemoved(_drone: Drone, target: MapShip) -> void:
	if target == controller:
		var hasSonar = fleetHasAeroSonar()
		cap.visible = !hasSonar
		if !hasSonar and enabled:
			toggleSonar(false)

func _onControlledShipUpdated(newController: PlayerDrivenShip) -> void:
	if controller != null:
		controller.ToggleSonarVisual(false)
	controller = newController
	var hasSonar = fleetHasAeroSonar()
	cap.visible = !hasSonar
	if !hasSonar and enabled:
		toggleSonar(false)

# --- SONAR AND FLEET UTILITY ---

func fleetHasAeroSonar() -> bool:
	if controller.Cpt.GetStatFinalValue(STAT_CONST.STATS.AEROSONAR_RANGE) > 0:
		return true
	for cap: Captain in controller.GetDroneDock().GetCaptains():
		if cap.GetStatFinalValue(STAT_CONST.STATS.AEROSONAR_RANGE) > 0:
			return true
	return false

func getCurrentFleetAeroSonarRange() -> float:
	var maxRange = controller.Cpt.GetStatFinalValue(STAT_CONST.STATS.AEROSONAR_RANGE)
	for cap: Captain in controller.GetDroneDock().GetCaptains():
		var testRange = cap.GetStatFinalValue(STAT_CONST.STATS.AEROSONAR_RANGE)
		if testRange > maxRange:
			maxRange = testRange
	return maxRange

func isPartOfFleet(target: Node2D) -> bool:
	return target == controller or target in controller.GetDroneDock().GetDockedShips()

# --- SONAR PHYSICS AND DETECTION ---

func _physics_process(delta: float) -> void:
	controller.SetSonarDirection(currentAngle)
	offset = wrap(offset + (delta * 10), 0, 2)
	_updateContacts()
	radioSpeaker.PlaySound(RadioSpeaker.RadioSound.STATIC, volume - 15)

func _updateContacts() -> void:
	var contactList: Dictionary[int, float] = {}
	for target in controller.GetSonarTargets():
		if (target is PlayerDrivenShip and isPartOfFleet(target)):
			continue
		if not TopographyMap.WithinLineOfSight(controller.global_position, controller.Altitude, target.global_position, target.Altitude):
			continue
		var direction = controller.global_position.direction_to(target.global_position).angle()
		var diff = Helper.angle_difference_radians(direction, currentAngle)
		if abs(diff) > PI / 4:
			continue

		var thrustValue: float = 0.0
		if target is MapShip:
			thrustValue = target.GetShipThrust() / 30
		elif target is Missile:
			thrustValue = target.Speed / 500

		var dist = controller.global_position.distance_squared_to(target.global_position) / 1_000_000.0
		var roundedAngle = roundi(rad_to_deg(diff) + 25)
		contactList[roundedAngle] = contactList.get(roundedAngle, 0) + (1 - dist) * thrustValue

	lineContainer.Update(contactList, Vector2.RIGHT.rotated((-PI / 2) + currentAngle).angle() + PI)

func _onSignalFound(signalStrength: float) -> void:
	radioSpeaker.PlaySound(RadioSpeaker.RadioSound.BEEP, signalStrength - 35)

# --- SONAR CONTROLS AND TOGGLING ---

func sonarRotationChanged(newVal: float) -> void:
	currentAngle = wrap(currentAngle + (newVal / 20), -PI, PI)
	controller.SetSonarDirection(currentAngle)

func toggle(on: bool) -> void:
	if not on:
		_onClosePressed()
	else:
		_onRadioClicked()

func _onClosePressed() -> void:
	if not fleetHasAeroSonar():
		PopUpManager.GetInstance().DoFadeNotif("Ship missing sonar")
		return
	toggleSonar(!working)

func _onCloseToggled(toggledOn: bool) -> void:
	toggleSonar(toggledOn)

func toggleSonar(enable: bool) -> void:
	lineContainer.visible = enable
	gainLabel.visible = enable
	set_physics_process(enable)
	enabled = enable
	if enable:
		working = fleetHasAeroSonar()
		controller.ToggleSonarVisual(working)
		lineContainer.OffsetAmmount = currentOffset
		toggleButton.set_pressed_no_signal(true)
	else:
		toggleButton.set_pressed_no_signal(false)
		controller.ToggleSonarVisual(false)

func _onRadioClicked() -> void:
	pass  # Future implementation, see commented legacy code

# --- GAIN/NOISE HANDLER ---

func _on_gein_control_range_changed(newVal: float) -> void:
	var newOffsetVal = clamp(currentOffset + (-newVal / 2), 1, 25)
	volume = newOffsetVal
	currentOffset = newOffsetVal
	gainLabel.text = "Gain:{0}".format([snapped(newOffsetVal, 0.1)]).replace(".0", "")
	if not working:
		return
	lineContainer.OffsetAmmount = newOffsetVal

func _getInterfaceName() -> String:
	return "AeroSonar"
