extends BasePilotScreenInterface
class_name ControlledShipUI

# --- EXPORTED NODE REFERENCES ---
@export var captainLabel: Label
@export var captainHullLabel: Label
@export var captainFuelLabel: Label
@export var droneLabel: Label

# --- STATE VARIABLES ---
var currentShip: PlayerDrivenShip = null
var working: bool = true
var pollDelay: float = 0.2    # Physics tick accumulator

# --- POLLING/CACHE REFRESH ---

func _physics_process(delta: float) -> void:
	pollDelay -= delta
	if pollDelay > 0:
		return
	pollDelay = 0.2
	_updateUI()

# --- UI UPDATE & STATE SYNC ---

func _updateUI() -> void:
	if currentShip == null:
		return

	var fuelStats = currentShip.GetFuelStats()
	var percentFuel = fuelStats["CurrentFuel"] / fuelStats["MaxFuel"] * 100
	var percentHull = currentShip.Cpt.GetStatCurrentValue(STAT_CONST.STATS.HULL) \
		/ currentShip.Cpt.GetStatFinalValue(STAT_CONST.STATS.HULL) * 100

	captainFuelLabel.text = "F:%d%%" % roundi(percentFuel)
	captainHullLabel.text = "H:%d%%" % roundi(percentHull)

	var droneText := ""
	for droneCap: Captain in currentShip.GetDroneDock().GetCaptains():
		var droneHull = droneCap.GetStatCurrentValue(STAT_CONST.STATS.HULL) \
			/ droneCap.GetStatFinalValue(STAT_CONST.STATS.HULL) * 100
		var droneFuel = droneCap.GetStatCurrentValue(STAT_CONST.STATS.FUEL_TANK) \
			/ droneCap.GetStatFinalValue(STAT_CONST.STATS.FUEL_TANK) * 100
		droneText += "%s\nH:%d%% | F:%d%%\n-----------------\n" % \
			[droneCap.GetCaptainName(), roundi(droneHull), roundi(droneFuel)]
	droneLabel.text = droneText

func _onControlledShipUpdated(newShip: PlayerDrivenShip) -> void:
	currentShip = newShip
	if currentShip != null:
		captainLabel.text = currentShip.Cpt.CaptainName
	_updateUI()

# --- EVENT HOOKS (CALLBACKS) ---

func _onDroneAdded(_dr: Drone, target: MapShip) -> void:
	if target == controller:
		_onControlledShipUpdated(controller)

func _onDroneRemoved(_dr: Drone, target: MapShip) -> void:
	if target == controller:
		_onControlledShipUpdated(controller)

func selected(ship: PlayerDrivenShip) -> void:
	controllerEventHandler.ShipChanged(ship)

# --- FLEET/COMMAND LIST MANAGEMENT ---

func getCommanders() -> Array[MapShip]:
	var commanders: Array[MapShip] = []
	for ship: PlayerDrivenShip in get_tree().get_nodes_in_group("PlayerShips"):
		if not ship.Docked:
			commanders.append(ship)
	return commanders

# --- UI NAVIGATION COMMANDS ---

func _on_drone_gas_range_snaped_chaned(dir: bool) -> void:
	var ships = getCommanders()
	var currentIndex = ships.find(currentShip)
	if dir:
		currentIndex = wrap(currentIndex + 1, 0, ships.size())
	else:
		currentIndex = wrap(currentIndex - 1, 0, ships.size())
	_onControlledShipUpdated(ships[currentIndex])
	selected(currentShip)

func _on_button_pressed() -> void:
	ShipCamera.GetInstance().FrameCamToShip(currentShip, 1, false)

func _on_before_captain_pressed() -> void:
	var ships = getCommanders()
	var currentIndex = ships.find(currentShip)
	currentIndex = wrap(currentIndex - 1, 0, ships.size())
	_onControlledShipUpdated(ships[currentIndex])
	selected(currentShip)

func _on_after_captain_pressed() -> void:
	var ships = getCommanders()
	var currentIndex = ships.find(currentShip)
	currentIndex = wrap(currentIndex + 1, 0, ships.size())
	_onControlledShipUpdated(ships[currentIndex])
	selected(currentShip)

func _getInterfaceName() -> String:
	return "Ship Controll Selector"
