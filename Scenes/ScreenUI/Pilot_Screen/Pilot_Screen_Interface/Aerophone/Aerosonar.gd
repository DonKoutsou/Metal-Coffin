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
@export var BaseGrad : GradientTexture2D

# --- STATE VARIABLES ---

var offset: float = 0.0
var currentAngle: float = 0.0
var currentOffset: float = 1.0
var working: bool = false
var enabled: bool = false
var volume: float = 1.0
var CurrentSonarRange : float = 0.0
const MAX_GAIN : int = 15

# --- INITIALIZATION / SIGNAL CONNECTIONS ---

func _ready() -> void:
	super()
	lineContainer.Found.connect(_onSignalFound)
	_updateContacts()
# --- FLEET AND DRONE DOCK MANAGEMENT ---

func _onDroneAdded(_drone: Drone, target: MapShip) -> void:
	if target == controller:
		CurrentSonarRange = GetFleetSonarRange()
		var hasSonar = CurrentSonarRange > 0
		cap.visible = !hasSonar
		toggleSonar(hasSonar)

func _onDroneRemoved(_drone: Drone, target: MapShip) -> void:
	if target == controller:
		CurrentSonarRange = GetFleetSonarRange()
		var hasSonar = CurrentSonarRange > 0
		cap.visible = !hasSonar
		toggleSonar(hasSonar)

func _onControlledShipUpdated(newController: PlayerDrivenShip) -> void:
	if controller != null:
		controller.AerosonarRangeChanged.disconnect(CheckIfWorking)
	controller = newController
	controller.AerosonarRangeChanged.connect(CheckIfWorking)
	CheckIfWorking()
	#if !hasSonar and enabled:
		#toggleSonar(false)

func CheckIfWorking() -> void:
	CurrentSonarRange = GetFleetSonarRange()
	var hasSonar = CurrentSonarRange > 0
	toggleSonar(hasSonar)
	cap.visible = !hasSonar

# --- SONAR AND FLEET UTILITY ---

func fleetHasAeroSonar() -> bool:
	if controller.Cpt.GetStatFinalValue(STAT_CONST.STATS.AEROSONAR_RANGE) > 0:
		return true
	for c: Captain in controller.GetDroneDock().GetCaptains():
		if c.GetStatFinalValue(STAT_CONST.STATS.AEROSONAR_RANGE) > 0:
			return true
	return false

func GetFleetSonarRange() -> float:
	var range : float = controller.Cpt.GetStatFinalValue(STAT_CONST.STATS.AEROSONAR_RANGE)
	for c: Captain in controller.GetDroneDock().GetCaptains():
		var dronerange = c.GetStatFinalValue(STAT_CONST.STATS.AEROSONAR_RANGE)
		if dronerange > range:
			range = dronerange
	return range

func getCurrentFleetAeroSonarRange() -> float:
	var maxRange = controller.Cpt.GetStatFinalValue(STAT_CONST.STATS.AEROSONAR_RANGE)
	for c: Captain in controller.GetDroneDock().GetCaptains():
		var testRange = c.GetStatFinalValue(STAT_CONST.STATS.AEROSONAR_RANGE)
		if testRange > maxRange:
			maxRange = testRange
	return maxRange

func isPartOfFleet(target: Node2D) -> bool:
	return target == controller or target in controller.GetDroneDock().GetDockedShips()

# --- SONAR PHYSICS AND DETECTION ---

func _physics_process(delta: float) -> void:
	_updateContacts()
	radioSpeaker.PlaySound(RadioSpeaker.RadioSound.STATIC, volume - 15)

func _updateContacts() -> void:
	var contactList: Dictionary[float, float] = {}
	for target in controller.GetSonarTargets():
		if (isPartOfFleet(target)):
			continue
		if not TopographyMap.WithinLineOfSight(controller.global_position, controller.Altitude, target.global_position, target.Altitude):
			continue
		var direction = snapped(controller.global_position.angle_to_point(target.global_position), 0.1)
		#var diff = Helper.angle_difference_radians(direction, PI/2)
		#var diff = 0
		#if abs(diff) > PI / 4:
			#continue

		var thrustValue: float = 0.0
		if target is MapShip:
			thrustValue = target.GetShipThrust() / 30
			if (target.Landed()):
				thrustValue = 0
		elif target is Missile:
			thrustValue = target.Speed / 500

		var dist = 1 - (controller.global_position.distance_to(target.global_position) / CurrentSonarRange)
		#var roundedAngle = snapped(direction, 0.1)
		contactList[direction] = contactList.get(direction, 0) + (dist * thrustValue)
	
	var Im = ContactsToGradient(contactList)
	lineContainer.Update(Im)

func ContactsToGradient(Contacts : Dictionary[float, float]) -> Image:
	var g : GradientTexture2D = BaseGrad.duplicate()
	g.gradient = Gradient.new()
	g.gradient.remove_point(1)
	
	for Index in Contacts.keys().size():
		var Angle = Contacts.keys()[Index]
		var NormalisedAngle = snapped(Helper.normalize_value(wrap(Angle, -PI, PI), -PI, PI), 0.01 )
		var BeforPoint = wrap(NormalisedAngle - 0.05, 0, 1)
		var AferPoint = wrap(NormalisedAngle + 0.05, 0, 1)
		var BeforValue = g.gradient.sample(BeforPoint)
		var AfterValue = g.gradient.sample(AferPoint)
		g.gradient.add_point(BeforPoint, BeforValue)
		g.gradient.add_point(NormalisedAngle, Color(1,1,1) * Contacts[Angle])
		g.gradient.add_point(AferPoint, AfterValue)
	
	if (g.gradient.get_point_count() > 1):
		g.gradient.remove_point(0)
		
	return g.get_image()

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
		#controller.ToggleSonarVisual(working)
		lineContainer.OffsetAmmount = currentOffset
		toggleButton.set_pressed_no_signal(true)
	else:
		toggleButton.set_pressed_no_signal(false)
		#controller.ToggleSonarVisual(false)

func _onRadioClicked() -> void:
	pass  # Future implementation, see commented legacy code

# --- GAIN/NOISE HANDLER ---

func _on_gein_control_range_changed(newVal: float) -> void:
	var newOffsetVal = clamp(currentOffset + (-newVal / 2), 1, MAX_GAIN)
	volume = newOffsetVal
	currentOffset = newOffsetVal
	gainLabel.text = "Gain:{0}".format([snapped(newOffsetVal, 0.1)]).replace(".0", "")
	if not working:
		return
	lineContainer.OffsetAmmount = newOffsetVal

func _on_gein_control_range_snapped_changed(direction: bool) -> void:
	var newOffsetVal = currentOffset
	if (!direction):
		newOffsetVal = clamp(currentOffset + 1, 1, MAX_GAIN)
	else:
		newOffsetVal = clamp(currentOffset - 1, 1, MAX_GAIN)
	volume = newOffsetVal
	currentOffset = newOffsetVal
	gainLabel.text = "Gain:{0}".format([snapped(newOffsetVal, 0.1)]).replace(".0", "")
	if not working:
		return
	lineContainer.OffsetAmmount = newOffsetVal

func _getInterfaceName() -> String:
	return "AeroSonar"
