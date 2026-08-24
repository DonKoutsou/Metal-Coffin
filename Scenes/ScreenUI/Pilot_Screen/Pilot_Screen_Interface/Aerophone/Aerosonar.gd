extends BasePilotScreenInterface
class_name AeroSonar

# --- EXPORTED PROPERTIES ---
@export var offsetAmount: float = 1.0
@export var lineContainer: AeroSonarLine
@export var gainLabel: Label
@export var radioSpeaker: RadioSpeaker
@export var cap: Control
@export var BaseGrad : GradientTexture2D
@export var ModeButton : BaseButton
# --- STATE VARIABLES ---

var offset: float = 0.0
var currentOffset: float = 1.0
var working: bool = false
var enabled: bool = false
var volume: float = 1.0
var CurrentSonarRange : float = 0.0
const MAX_GAIN : int = 15

var currentMode : MODE = MODE.SOUND

enum MODE{
	SOUND,
	RADAR,
}

# --- INITIALIZATION / SIGNAL CONNECTIONS ---
#----------------------------------------
func _ready() -> void:
	super()
	lineContainer.Found.connect(_onSignalFound)
	lineContainer.Update(BaseGrad.get_image(), WeatherManage.StormValueInPosition(controller.global_position))
	#BaseGrad.changed.connect(GradientUpdated)
	#_updateContacts()
	
# --- FLEET AND DRONE DOCK MANAGEMENT ---
#----------------------------------------
func _onDroneAdded(_drone: PlayerDrivenShip, target: MapShip) -> void:
	if target == controller:
		CurrentSonarRange = GetFleetSonarRange()
		var hasSonar = CurrentSonarRange > 0
		cap.visible = !hasSonar
		toggleSonar(hasSonar)

#----------------------------------------
func _onDroneRemoved(_drone: PlayerDrivenShip, target: MapShip) -> void:
	if target == controller:
		CurrentSonarRange = GetFleetSonarRange()
		var hasSonar = CurrentSonarRange > 0
		cap.visible = !hasSonar
		toggleSonar(hasSonar)

#----------------------------------------
func _onControlledShipUpdated(newController: PlayerDrivenShip) -> void:
	if (controller == newController):
		return
	if controller != null:
		controller.ElintRangeChanged.disconnect(CheckIfWorking)
		controller.SonarRangeChanged.disconnect(CheckIfWorking)
	controller = newController
	
	controller.ElintRangeChanged.connect(CheckIfWorking)
	controller.SonarRangeChanged.connect(CheckIfWorking)
	CheckIfWorking()
	#if !hasSonar and enabled:
		#toggleSonar(false)

#----------------------------------------
func CheckIfWorking() -> void:
	CurrentSonarRange = GetFleetSonarRange()
	var hasSonar = CurrentSonarRange > 0
	var hasElint = fleetHasElint()
	toggleSonar(hasSonar or hasElint)
	var hasAny = hasSonar or hasElint
	cap.visible = !hasAny
	if (!hasAny):
		return
	if (!hasSonar and currentMode == MODE.SOUND):
		ModeButton.set_pressed(false)
	else: if (!hasElint and currentMode == MODE.RADAR):
		ModeButton.set_pressed(true)

#----------------------------------------
func fleetHasElint() -> bool:
	# Check if the currently controlled ship or its docked drones have ELINT
	if controller.Cpt.GetStatFinalValue(STAT_CONST.STATS.ELINT) > 0:
		return true
	for c: Captain in controller.GetDock().GetCaptains():
		if c.GetStatFinalValue(STAT_CONST.STATS.ELINT) > 0:
			return true
	return false

# --- SONAR AND FLEET UTILITY ---
#----------------------------------------
func fleetHasAeroSonar() -> bool:
	if controller.Cpt.GetStatFinalValue(STAT_CONST.STATS.AEROSONAR_RANGE) > 0:
		return true
	for c: Captain in controller.GetDock().GetCaptains():
		if c.GetStatFinalValue(STAT_CONST.STATS.AEROSONAR_RANGE) > 0:
			return true
	return false

#----------------------------------------
func GetFleetSonarRange() -> float:
	var SonarRange : float = controller.Cpt.GetStatFinalValue(STAT_CONST.STATS.AEROSONAR_RANGE)
	for c: Captain in controller.GetDock().GetCaptains():
		var dronerange = c.GetStatFinalValue(STAT_CONST.STATS.AEROSONAR_RANGE)
		if dronerange > SonarRange:
			SonarRange = dronerange
	return SonarRange

#----------------------------------------
func getCurrentFleetAeroSonarRange() -> float:
	var maxRange = controller.Cpt.GetStatFinalValue(STAT_CONST.STATS.AEROSONAR_RANGE)
	for c: Captain in controller.GetDock().GetCaptains():
		var testRange = c.GetStatFinalValue(STAT_CONST.STATS.AEROSONAR_RANGE)
		if testRange > maxRange:
			maxRange = testRange
	return maxRange

#----------------------------------------
func isPartOfFleet(target: Node2D) -> bool:
	return target == controller or target in controller.GetDock().GetDockedShips()

# --- SONAR PHYSICS AND DETECTION ---
#----------------------------------------
func Update(_delta: float) -> void:
	if (currentMode == MODE.SOUND):
		if (_contactUpdateThread == null):
			_contactUpdateThread = Thread.new()
			var ControllerInfo := SonarTargetInfo.new()
			ControllerInfo.Position = controller.global_position
			ControllerInfo.Altitude = controller.Altitude
			var ContactInfos = controller.GetSonarTargetInfo()
			_contactUpdateThread.start(_updateContacts.bind(ControllerInfo, ContactInfos))
	else:
		if (_contactUpdateThread == null):
			_contactUpdateThread = Thread.new()
			var ControllerInfo := ElintTargetInfo.new()
			ControllerInfo.Position = controller.global_position
			ControllerInfo.Altitude = controller.Altitude
			var ContactInfos = controller.GetElintTargetInfo()
			_contactUpdateThread.start(_updateElintContacts.bind(ControllerInfo, ContactInfos))
	#_updateContacts()
	radioSpeaker.PlaySound(RadioSpeaker.RadioSound.STATIC, volume - 15)

var _contactUpdateThread : Thread

#Update contacts of controller
#----------------------------------------
func _updateElintContacts(ControllerInfo : ElintTargetInfo ,ContactInfo : Array[ElintTargetInfo]) -> Image:
	var contactList: Dictionary[float, float] = {}
	#retrieve contacts and iterate over them
	for target in ContactInfo:
		#make sure we dont register ships from the controllers fleed
		
		#terain collision
		if not TopographyMap.WithinLineOfSight(ControllerInfo.Position, ControllerInfo.Altitude, target.Position, target.Altitude):
			continue
			
		#take the direction to the target
		var direction = ControllerInfo.Position.angle_to_point(target.Position)
		
		#get the sound signature of the target
		var ElintLvl: int = target.ElintLevel
		#do raycast and find storm collision
		
		var stormvalue = 1 - ease(WeatherManage.GetBiggestStormValue(ControllerInfo.Position, target.Position), 4)
		#figure out distance, at the end is normalised value. Bigger values means target is closer, means sound signature is stronger
		var dist = 1 -  ease((ControllerInfo.Position.distance_to(target.Position) / (CurrentSonarRange)), 4)
		#calculate final signature by applying the distance and storm to the SoundSignature
		var finalsignature = dist * ElintLvl * stormvalue
		if (finalsignature == 0):
			continue
		#if contact exists, add to it.
		if (contactList.has(direction)):
			var sounds : Array[float]
			sounds.append(finalsignature)
			sounds.append(contactList.has(direction))
			finalsignature = Helper.CombineNoiseAmplitude(sounds)

		contactList[direction] = finalsignature
	
	#bake the contact list into a gradient and send it to the UI
	var grad = ContactsToGradient(contactList)
	BaseGrad.gradient = grad
	#await BaseGrad.changed
	var Im = BaseGrad.get_image()
	call_deferred("ContactsUpdated")
	return Im

#Update contacts of controller
#----------------------------------------
func _updateContacts(ControllerInfo : SonarTargetInfo ,ContactInfo : Array[SonarTargetInfo]) -> Image:
	var contactList: Dictionary[float, float] = {}
	#retrieve contacts and iterate over them
	for target in ContactInfo:
		#make sure we dont register ships from the controllers fleed
		
		#terain collision
		if not TopographyMap.WithinLineOfSight(ControllerInfo.Position, ControllerInfo.Altitude, target.Position, target.Altitude):
			continue
			
		#take the direction to the target
		var direction = ControllerInfo.Position.angle_to_point(target.Position)
		
		#get the sound signature of the target
		var SounddB: float = target.Signature * 2
		
		#do raycast and find storm collision
		
		var stormvalue = 1 - ease(WeatherManage.GetBiggestStormValue(ControllerInfo.Position, target.Position), 4)
		#figure out distance, at the end is normalised value. Bigger values means target is closer, means sound signature is stronger
		var dist = 1 -  ease((ControllerInfo.Position.distance_to(target.Position) / (CurrentSonarRange)), 4)
		#calculate final signature by applying the distance and storm to the SoundSignature
		var finalsignature = dist * SounddB * stormvalue
		if (finalsignature == 0):
			continue
		#if contact exists, add to it.
		if (contactList.has(direction)):
			var sounds : Array[float]
			sounds.append(finalsignature)
			sounds.append(contactList.has(direction))
			finalsignature = Helper.CombineNoiseAmplitude(sounds)

		contactList[direction] = finalsignature
	
	#bake the contact list into a gradient and send it to the UI
	var grad = ContactsToGradient(contactList)
	BaseGrad.gradient = grad
	#await BaseGrad.changed
	var Im = BaseGrad.get_image()
	call_deferred("ContactsUpdated")
	return Im

#----------------------------------------
func ContactsUpdated() -> void:
	var ContactGradient : Image = _contactUpdateThread.wait_to_finish()
	#print(ContactGradient.get_size())
	#BaseGrad.gradient = ContactGradient
	#var Im = BaseGrad.get_image()
	_contactUpdateThread = null
	lineContainer.Update(ContactGradient, WeatherManage.StormValueInPosition(controller.global_position))

#func GradientUpdated() -> void:
	#var Im = BaseGrad.get_image()
	#lineContainer.Update(Im, WeatherManage.StormValueInPosition(controller.global_position))

#----------------------------------------
func ContactsToGradient(Contacts : Dictionary[float, float]) -> Gradient:
	#var g : GradientTexture2D = BaseGrad.duplicate()
	var gradient = Gradient.new()
	
	gradient.remove_point(1)
	
	for Index in Contacts.keys().size():
		var Angle = Contacts.keys()[Index]
		var SignalStr = Contacts[Angle]
		var ClosePointOffset = max(0.02 * SignalStr, 0.02)
		var NormalisedAngle = Helper.normalize_value(wrap(Angle, -PI, PI), -PI, PI)
		var BeforPoint = wrap(NormalisedAngle - ClosePointOffset, 0, 1)
		var AferPoint = wrap(NormalisedAngle + ClosePointOffset, 0, 1)
		var BeforValue = gradient.sample(BeforPoint)
		var AfterValue = gradient.sample(AferPoint)
		gradient.add_point(BeforPoint, BeforValue)
		gradient.add_point(NormalisedAngle, Color(1,1,1) * Contacts[Angle])
		gradient.add_point(AferPoint, AfterValue)
	
	if (gradient.get_point_count() > 1):
		gradient.remove_point(0)
		
	return gradient

#----------------------------------------
func _onSignalFound(_signalStrength: float) -> void:
	pass
	#radioSpeaker.PlaySound(RadioSpeaker.RadioSound.BEEP, signalStrength - 35)

# --- SONAR CONTROLS AND TOGGLING ---
#----------------------------------------
func toggle(on: bool) -> void:
	if not on:
		_onClosePressed()
	else:
		_onRadioClicked()

#----------------------------------------
func _onClosePressed() -> void:
	if not fleetHasAeroSonar():
		PopUpManager.GetInstance().DoFadeNotif("Ship missing sonar")
		return
	toggleSonar(!working)

#----------------------------------------
func _onCloseToggled(toggledOn: bool) -> void:
	toggleSonar(toggledOn)

#----------------------------------------
func toggleSonar(enable: bool) -> void:
	lineContainer.visible = enable
	gainLabel.visible = enable
	set_physics_process(enable)
	enabled = enable
	if enable:
		ActionTracker.OnActionCompleted(ActionTracker.Action.AEROSONAR)
		#working = fleetHasAeroSonar()
		#controller.ToggleSonarVisual(working)
		lineContainer.OffsetAmmount = currentOffset
		#controller.ToggleSonarVisual(false)

#----------------------------------------
func _onRadioClicked() -> void:
	pass  # Future implementation, see commented legacy code

# --- GAIN/NOISE HANDLER ---
#----------------------------------------
func _on_gein_control_range_changed(newVal: float) -> void:
	var newOffsetVal = clamp(currentOffset + (-newVal / 2), 1, MAX_GAIN)
	volume = newOffsetVal
	currentOffset = newOffsetVal
	gainLabel.text = "Gain:{0}".format([snapped(newOffsetVal, 0.1)]).replace(".0", "")
	#if not working:
		#return
	lineContainer.OffsetAmmount = newOffsetVal

#----------------------------------------
func _on_gein_control_range_snapped_changed(direction: bool) -> void:
	var newOffsetVal = currentOffset
	if (!direction):
		newOffsetVal = clamp(currentOffset + 1, 1, MAX_GAIN)
	else:
		newOffsetVal = clamp(currentOffset - 1, 1, MAX_GAIN)
	volume = newOffsetVal
	currentOffset = newOffsetVal
	gainLabel.text = "Gain:{0}".format([snapped(newOffsetVal, 0.1)]).replace(".0", "")
	#if not working:
		#return
	lineContainer.OffsetAmmount = newOffsetVal

#----------------------------------------
func _getInterfaceName() -> String:
	return "Passive Detectors"

#----------------------------------------
func _on_mode_toggled(toggled_on: bool) -> void:
	if (toggled_on):
		if (GetFleetSonarRange() == 0):
			ModeButton.set_pressed_no_signal(!toggled_on)
			PopUpManager.GetInstance().DoFadeNotif("Ship missing sonar")
			return
		currentMode = MODE.SOUND
		lineContainer.modulate = Color(1,0,0)
	else:
		if (!fleetHasElint()):
			ModeButton.set_pressed_no_signal(!toggled_on)
			PopUpManager.GetInstance().DoFadeNotif("Ship missing ELint")
			return
		currentMode = MODE.RADAR
		lineContainer.modulate = Color(0.802, 0.416, 0.074, 1.0)
	Update(0)
