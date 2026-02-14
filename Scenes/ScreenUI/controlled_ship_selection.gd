extends Control

class_name ControlledShipUI

@export var ShipControllerEventH : ShipControllerEventHandler
@export var CurrentCaptainLabel : Label
@export var CurrentCaptainHullLabel : Label
@export var CurrentCaptainFuelLabel : Label
@export var DroneLabel : Label

var currentShip : PlayerDrivenShip
var Working : bool = true

func _ready() -> void:
	ShipChanged(ShipControllerEventH.CurrentControlled)
	ShipControllerEventH.connect("OnControlledShipChanged", ShipChanged)

var d : float = 0.2
func _physics_process(delta: float) -> void:
	d -= delta
	if (d > 0):
		return
	d = 0.2
	
	var FuelStats = currentShip.GetFuelStats()

	var f = (FuelStats["CurrentFuel"] / FuelStats["MaxFuel"]) * 100
	var h = currentShip.Cpt.GetStatCurrentValue(STAT_CONST.STATS.HULL) / currentShip.Cpt.GetStatFinalValue(STAT_CONST.STATS.HULL) * 100
	
	CurrentCaptainFuelLabel.text = "F:{0}%".format([roundi(f)])
	CurrentCaptainHullLabel.text = "H:{0}%".format([roundi(h)])
	
	var DroneText : String = ""
	for g : Captain in currentShip.GetDroneDock().GetCaptains():
		
		var Droneh = g.GetStatCurrentValue(STAT_CONST.STATS.HULL) / g.GetStatFinalValue(STAT_CONST.STATS.HULL) * 100
		var Dronef = g.GetStatCurrentValue(STAT_CONST.STATS.FUEL_TANK) / g.GetStatFinalValue(STAT_CONST.STATS.FUEL_TANK) * 100
		DroneText += "{0}\nH:{1}% | F:{2}%\n-----------------\n".format([g.GetCaptainName(), roundi(Droneh), roundi(Dronef)])
	DroneLabel.text = DroneText
	
func ShipChanged(NewShip : PlayerDrivenShip) -> void:
	currentShip = NewShip
	
	CurrentCaptainLabel.text = currentShip.Cpt.CaptainName
	var FuelStats = currentShip.GetFuelStats()

	var f = (FuelStats["CurrentFuel"] / FuelStats["MaxFuel"]) * 100
	
	var h = currentShip.Cpt.GetStatCurrentValue(STAT_CONST.STATS.HULL) / currentShip.Cpt.GetStatFinalValue(STAT_CONST.STATS.HULL) * 100
	
	CurrentCaptainFuelLabel.text = "FUEL:{0}%".format([roundi(f)])
	CurrentCaptainHullLabel.text = "HULL:{0}%".format([roundi(h)])

	var DroneText : String = ""
	for g : Captain in currentShip.GetDroneDock().GetCaptains():
		
		var Droneh = g.GetStatCurrentValue(STAT_CONST.STATS.HULL) / g.GetStatFinalValue(STAT_CONST.STATS.HULL) * 100
		DroneText += "{0}\n{1}%\n-----------\n".format([g.GetCaptainName(), roundi(Droneh)])
	DroneLabel.text = DroneText

func Selected(Ship : PlayerDrivenShip) -> void:
	ShipControllerEventH.ShipChanged(Ship)

func GetCommanders() -> Array[MapShip]:
	var Commanders : Array[MapShip]
	
	for g : PlayerDrivenShip in get_tree().get_nodes_in_group("PlayerShips"):
		if (!g.Docked):
			Commanders.append(g)
	
	return Commanders
	
func _on_drone_gas_range_snaped_chaned(Dir: bool) -> void:
	var Ships = GetCommanders()
	var currentindex = Ships.find(currentShip)
	if (Dir):
		currentindex = wrap(currentindex + 1, 0, Ships.size())
	else:
		currentindex = wrap(currentindex - 1, 0, Ships.size())
	ShipChanged(Ships[currentindex])
	Selected(currentShip)


func _on_button_pressed() -> void:
	ShipCamera.GetInstance().FrameCamToShip(currentShip)


func _on_before_captain_pressed() -> void:
	var Ships = GetCommanders()
	var currentindex = Ships.find(currentShip)

	currentindex = wrap(currentindex - 1, 0, Ships.size())
	
	ShipChanged(Ships[currentindex])
	Selected(currentShip)

func _on_after_captain_pressed() -> void:
	var Ships = GetCommanders()
	var currentindex = Ships.find(currentShip)

	currentindex = wrap(currentindex + 1, 0, Ships.size())

	ShipChanged(Ships[currentindex])
	Selected(currentShip)
