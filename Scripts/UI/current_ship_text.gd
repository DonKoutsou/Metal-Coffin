extends Label

@export var ShipControllerEventH : ShipControllerEventHandler

var currentShip : MapShip

func _ready() -> void:
	currentShip = ShipControllerEventH.CurrentControlled
	ShipControllerEventH.connect("OnControlledShipChanged", ShipChanged)

func ShipChanged(NewShip : MapShip) -> void:
	currentShip = NewShip

func _physics_process(delta: float) -> void:
	if (currentShip == null):
		return
	var hull = currentShip.Cpt.GetStatCurrentValue(STAT_CONST.STATS.HULL) / currentShip.Cpt.GetStatFinalValue(STAT_CONST.STATS.HULL) * 100
	text = "{0}\nHULL : {1}%".format([currentShip.Cpt.CaptainName.to_upper(), roundi(hull)])
#roundi(hull)
