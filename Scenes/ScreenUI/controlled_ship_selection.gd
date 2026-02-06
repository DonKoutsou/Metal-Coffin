extends Control

class_name ControlledShipUI

@export var ShipControllerEventH : ShipControllerEventHandler
@export var CurrentCaptainLabel : Label

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
	
	var h = currentShip.Cpt.GetStatCurrentValue(STAT_CONST.STATS.HULL) / currentShip.Cpt.GetStatFinalValue(STAT_CONST.STATS.HULL) * 100
	CurrentCaptainLabel.text = currentShip.Cpt.CaptainName + "\n{0}%".format([h])

func ShipChanged(NewShip : PlayerDrivenShip) -> void:
	currentShip = NewShip
	var h = currentShip.Cpt.GetStatCurrentValue(STAT_CONST.STATS.HULL) / currentShip.Cpt.GetStatFinalValue(STAT_CONST.STATS.HULL) * 100
	
	CurrentCaptainLabel.text = currentShip.Cpt.CaptainName + "\n{0}%".format([h])

func Selected(Ship : PlayerDrivenShip) -> void:
	ShipControllerEventH.ShipChanged(Ship)


func _on_drone_gas_range_snaped_chaned(Dir: bool) -> void:
	var Ships = get_tree().get_nodes_in_group("PlayerShips")
	var currentindex = Ships.find(currentShip)
	if (Dir):
		currentindex = wrap(currentindex + 1, 0, Ships.size() - 1)
	else:
		currentindex = wrap(currentindex - 1, 0, Ships.size() - 1)
	ShipChanged(Ships[currentindex])
	Selected(currentShip)


func _on_button_pressed() -> void:
	ShipCamera.GetInstance().FrameCamToShip(currentShip)
