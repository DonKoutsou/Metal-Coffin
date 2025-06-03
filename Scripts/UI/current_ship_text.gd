extends Label

@export var ShipControllerEventH : ShipControllerEventHandler

var currentShip : PlayerDrivenShip

func _ready() -> void:
	currentShip = ShipControllerEventH.CurrentControlled
	ShipControllerEventH.connect("OnControlledShipChanged", ShipChanged)

func ShipChanged(NewShip : PlayerDrivenShip) -> void:
	currentShip = NewShip

var d = 0.4
func _physics_process(delta: float) -> void:
	d -= delta
	if d > 0:
		return
	d = 0.4
	
	if (currentShip == null):
		return
	var commander
	if (currentShip.Command != null):
		commander = currentShip.Command
	else:
		commander = currentShip
		
	var hull = commander.Cpt.GetStatCurrentValue(STAT_CONST.STATS.HULL) / commander.Cpt.GetStatFinalValue(STAT_CONST.STATS.HULL) * 100
	var Ships = "-FLEET-\n--------\n{0}\nHULL:{1}%\n--------".format([commander.Cpt.CaptainName.to_upper(), roundi(hull)])
	for g in commander.GetDroneDock().DockedDrones:
		var h = g.Cpt.GetStatCurrentValue(STAT_CONST.STATS.HULL) / g.Cpt.GetStatFinalValue(STAT_CONST.STATS.HULL) * 100
		Ships += "\n{0}\nHULL:{1}%\n--------".format([g.Cpt.CaptainName.to_upper(), roundi(h)])
	text = Ships
#roundi(hull)
