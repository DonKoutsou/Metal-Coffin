extends Control

class_name  Clock

@export var StartingDay : int = 10
@export var StartingMonth : int = 4
@export var StartingYear : int = 6129
@export var StartingHour : int = 13
@export var StartingMin : float = 0

static var CurrentDay : int = 10
static var CurrentMonth : int = 4
static var CurrentYear : int = 6129
static var currentHour : int = 13
static var currentMin : float = 0

#var SimulationSpeed : float = 1
var SimulationPaused : bool = false

static var Instance : Clock

func TimePassedInMinutes() -> int:
	var DaysPassed = CurrentDay - StartingDay
	var MonthsPassed = CurrentMonth - StartingMonth
	var YearsPassed = CurrentYear - StartingYear
	var HoursPassed = currentHour - StartingHour
	var MinPassed = currentMin - StartingMin
	while YearsPassed > 0:
		MonthsPassed += 12
		YearsPassed -= 1
	while MonthsPassed > 0:
		DaysPassed += GetDaysInMonth(wrap(StartingMonth + MonthsPassed, 1, 12))
		MonthsPassed -= 1
	while DaysPassed > 0:
		HoursPassed += 24
		DaysPassed -= 1
	while HoursPassed > 0:
		MinPassed += 60
		HoursPassed -= 1
	
	return MinPassed

static func GetDateTimeString() -> String:
	return "{0}/{1}/{2} {3}:{4}".format([CurrentDay, CurrentMonth, CurrentYear, currentHour, roundi(currentMin)])

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	CurrentDay = StartingDay
	CurrentMonth = StartingMonth
	CurrentYear = StartingYear
	currentHour = StartingHour
	currentMin = StartingMin
	
	Instance = self
	#var rot = (360.0/12.0)*currentHour
	#$Hour.rotation = deg_to_rad(rot)
	#SimulationSpeed = SimulationManager.SimSpeed()
	var HourString = CheckNumber(var_to_str(currentHour)) + " : " + CheckNumber(var_to_str(roundi(currentMin)))
	var DayString = CheckNumber(var_to_str(CurrentDay)) + " / " + CheckNumber(var_to_str(CurrentMonth)) + " / " + var_to_str(CurrentYear)
	$HBoxContainer/Label.text = HourString
	$HBoxContainer/Label2.text = DayString
static func GetInstance() -> Clock:
	return Instance
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if (SimulationPaused):
		return
	currentMin += (delta * 10) * SimulationManager.SimSpeed()
	if (currentMin >= 60):
		currentHour += 1
		if (currentHour >= 24):
			currentHour = 0
			CurrentDay += 1
			
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
	#$Label2.text = CheckNumber(var_to_str(CurrentDay)) + " / " + CheckNumber(var_to_str(CurrentMonth)) + " / " + var_to_str(CurrentYear)
	var HourString = CheckNumber(var_to_str(currentHour)) + " : " + CheckNumber(var_to_str(roundi(currentMin)))
	var DayString = CheckNumber(var_to_str(CurrentDay)) + " / " + CheckNumber(var_to_str(CurrentMonth)) + " / " + var_to_str(CurrentYear)
	$HBoxContainer/Label.text = HourString
	$HBoxContainer/Label2.text = DayString

func CheckNumber(NumString : String) -> String:
	if (NumString.length() == 1):
		return "0" + NumString
	return NumString
func ToggleSimulation(t : bool) -> void:
	SimulationPaused = t
#func SimulationSpeedChanged(i : float) -> void:
	#SimulationSpeed = i
static func GetTimeInHours() -> float:
	return (CurrentDay * 24) + currentHour + (currentMin / 60)

static func GetHours() -> float:
	return currentHour + (currentMin / 60.0)
static func GetHoursSince(time : float) -> float:
	return GetTimeInHours() - time

static func GetDaysInMonth(Month : int) -> int:
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

func GetSaveData() -> SaveData:
	var SaveD = SaveData.new()
	SaveD.DataName = "Clock"
	
	var Data = SD_Clock.new()
	Data.CurrentDay = CurrentDay
	Data.CurrentMonth = CurrentMonth
	Data.CurrentYear = CurrentYear
	Data.currentHour = currentHour
	Data.currentMin = currentMin
	SaveD.Datas.append(Data)
	return SaveD

func LoadData(Data : SaveData) -> void:
	var ClockData = Data.Datas[0] as SD_Clock
	CurrentDay = ClockData.CurrentDay
	CurrentMonth = ClockData.CurrentMonth
	CurrentYear = ClockData.CurrentYear
	currentHour = ClockData.currentHour
	currentMin = ClockData.currentMin
