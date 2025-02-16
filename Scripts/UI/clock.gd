extends Control

class_name  Clock

var CurrentDay : int = 10
var CurrentMonth : int = 4
var CurrentYear : int = 3874
var currentHour : int = 13
var currentMin : float = 0

var SimulationSpeed : int = 1
var SimulationPaused : bool = false

static var Instance : Clock

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Instance = self
	#var rot = (360.0/12.0)*currentHour
	#$Hour.rotation = deg_to_rad(rot)
	$Label.text = CheckNumber(var_to_str(currentHour)) + " : " + CheckNumber(var_to_str(roundi(currentMin)))
	$Label2.text = CheckNumber(var_to_str(CurrentDay)) + " / " + CheckNumber(var_to_str(CurrentMonth)) + " / " + var_to_str(CurrentYear)
static func GetInstance() -> Clock:
	return Instance
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if (SimulationPaused):
		return
	currentMin += (delta * 10) * SimulationSpeed
	if (currentMin >= 60):
		currentHour += 1
		if (currentHour >= 24):
			currentHour = 0
			CurrentDay += 1
			$Label2.text = CheckNumber(var_to_str(CurrentDay)) + " / " + CheckNumber(var_to_str(CurrentMonth)) + " / " + var_to_str(CurrentYear)
			if (CurrentDay > GetDaysInMonth(CurrentMonth)):
				CurrentDay = 1
				CurrentMonth += 1
				if (CurrentMonth > 12):
					CurrentMonth = 1
					CurrentYear += 1
		currentMin = 0
		
	#var rot = (360.0/60.0)*currentMin
	#$Min.rotation = deg_to_rad(rot)
	#var Hrot = (360.0/12.0)* currentHour
	#$Hour.rotation = deg_to_rad(Hrot + (rot / 12))
	$Label.text = CheckNumber(var_to_str(currentHour)) + " : " + CheckNumber(var_to_str(roundi(currentMin)))

func CheckNumber(NumString : String) -> String:
	if (NumString.length() == 1):
		return "0" + NumString
	return NumString
func ToggleSimulation(t : bool) -> void:
	SimulationPaused = t
func SimulationSpeedChanged(i : int) -> void:
	SimulationSpeed = i
func GetTimeInHours() -> float:
	var t = (CurrentDay * 24) + currentHour + (currentMin / 60)
	return t
func GetHoursSince(time : float) -> float:
	return GetTimeInHours() - time

func GetDaysInMonth(Month : int) -> int:
	if (Month == 1):
		return 31
	if (Month == 2):
		return 28
	if (Month == 3):
		return 31
	if (Month == 4):
		return 30
	if (Month == 5):
		return 31
	if (Month == 6):
		return 30
	if (Month == 7):
		return 31
	if (Month == 8):
		return 30
	if (Month == 9):
		return 31
	if (Month == 10):
		return 30
	if (Month == 11):
		return 31
	if (Month == 12):
		return 30
	return 0
