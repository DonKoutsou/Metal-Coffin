extends PanelContainer

class_name FleetSeparation

@export var CurrentFleetRangeText : Label
@export var CurrentFleetFuelBar : ProgressBar
@export var CurrentFleetCommanderPlecemenet :VBoxContainer
@export var CurrentFleetShipPlecement : VBoxContainer
@export var NewFleetRangeText : Label
@export var NewFleetFuelBar : ProgressBar
@export var NewFleetShipPlecement : VBoxContainer
@export var NewFleetCommanderPlecemenet :VBoxContainer

@export var ShipContainer : PackedScene

signal SeperationFinished

var CurrentFleet : Array[PlayerDrivenShip]
var NewFleet : Array[PlayerDrivenShip]

func _ready() -> void:
	for Ship in CurrentFleet.size():
		var ShipCont = ShipContainer.instantiate() as CaptainButton
		if (Ship == 0):
			CurrentFleetCommanderPlecemenet.add_child(ShipCont)
		else:
			CurrentFleetShipPlecement.add_child(ShipCont)
		ShipCont.SetShip(CurrentFleet[Ship])
		ShipCont.connect("OnShipSelected", OnShipContainerSelecter.bind(ShipCont))
	UISoundMan.GetInstance().AddSelf($VBoxContainer/Button)
	
func OnShipContainerSelecter(Cont : CaptainButton) -> void:
	var Ship = Cont.ContainedShip
	if (CurrentFleet.has(Ship)):
		#If trying to remove commander of current fleet return
		if (CurrentFleet.size() == 1 or CurrentFleet[0] == Ship):
			print("Cant remove commander of current fleet")
			return
		
		#Take the container out of the current fleet list and remove ship from CurrentFleetArray
		CurrentFleetShipPlecement.remove_child(Cont)
		CurrentFleet.erase(Ship)
		
		#If Newfleet is empty it means that selected ship will be our new commander
		if (NewFleet.size() == 0):
			#add container to commander possition
			NewFleetCommanderPlecemenet.add_child(Cont)
			#Find the old commander and remove this ship from the dock
			var OldCommander = CurrentFleet[0]
			var Dock = OldCommander.GetDroneDock()
			Dock.UndockDrone(Ship)
			Ship.EnableDrone()
		#if not then find the new commander and replace his
		else:
			NewFleetShipPlecement.add_child(Cont)
			var OldCommander = CurrentFleet[0]
			var Dock = OldCommander.GetDroneDock()
			Dock.UndockDrone(Ship)
			
			var NewCommander = NewFleet[0]
			var NewDock = NewCommander.GetDroneDock()
			NewDock.DockDrone(Ship)
			#Ship.DissableDrone()
		#Add ship to new fleet array
		NewFleet.append(Ship)
		#Update stats
		UpdateCurrentFleetStats()
		UpdateNewFleetStats()
	else : if (NewFleet.has(Ship)):
		
		if (NewFleet[0] == Ship):
			#If trying to remove commander of new fleet and new fleet still has members return
			if (NewFleet.size() > 1):
				print("Cant remove commander of new fleet while the fleet has members, empty fleet first")
				return 
			
			NewFleetCommanderPlecemenet.remove_child(Cont)
		
		else:
			NewFleetShipPlecement.remove_child(Cont)

			var OldCommander = NewFleet[0]
			var Dock = OldCommander.GetDroneDock()
			Dock.UndockDrone(Ship)
			
		var NewCommander = CurrentFleet[0]
		var NewDock = NewCommander.GetDroneDock()
		NewDock.DockDrone(Ship)
		#Ship.DissableDrone()
		
		CurrentFleetShipPlecement.add_child(Cont)
		NewFleet.erase(Ship)
		CurrentFleet.append(Ship)
		UpdateCurrentFleetStats()
		UpdateNewFleetStats()
func UpdateCurrentFleetStats() -> void:
	var Cap = CurrentFleet[0]
	var FuelStats = Cap.GetFuelStats()
	CurrentFleetRangeText.text = "Range : " + var_to_str(roundi(FuelStats["FleetRange"])) + " km"
	CurrentFleetFuelBar.max_value = FuelStats["MaxFuel"]
	CurrentFleetFuelBar.value = FuelStats["CurrentFuel"]

func UpdateNewFleetStats() -> void:
	if (NewFleet.size() > 0):
		var Cap = NewFleet[0]
		var FuelStats = Cap.GetFuelStats()
		NewFleetRangeText.text = "Range : " + var_to_str(roundi(FuelStats["FleetRange"])) + " km"
		NewFleetFuelBar.max_value = FuelStats["MaxFuel"]
		NewFleetFuelBar.value = FuelStats["CurrentFuel"]
	else:
		NewFleetRangeText.text = "Range : 0"
		NewFleetFuelBar.max_value = 0
		NewFleetFuelBar.value = 0

#TODO make sure fleet has fuel to loose DONE
func CurrentFleetBarInput(event: InputEvent) -> void:
	if (event is InputEventMouseMotion and Input.is_action_pressed("Click") or event is InputEventScreenDrag):
		var rel = event.relative
		var AddedFuel = roundi(((rel.x / 3) * (CurrentFleetFuelBar.max_value / 100)))
		if (AddedFuel > NewFleetFuelBar.value):
			return
		if (CurrentFleetFuelBar.value + AddedFuel > CurrentFleetFuelBar.max_value):
			AddedFuel = CurrentFleetFuelBar.max_value - CurrentFleetFuelBar.value
		if (AddedFuel > 0):
			#CurrentFleetFuelBar.value += AddedFuel
			AddFuelToFleet(CurrentFleet, AddedFuel)
			#NewFleetFuelBar.value -= AddedFuel
			RemoveFuelFromFleet(NewFleet, AddedFuel)
			UpdateCurrentFleetStats()
			UpdateNewFleetStats()
func NewFleetBarInput(event: InputEvent) -> void:
	if (event is InputEventMouseMotion and Input.is_action_pressed("Click") or event is InputEventScreenDrag):
		var rel = event.relative
		var AddedFuel = roundi(((rel.x / 3) * (NewFleetFuelBar.max_value / 100)))
		if (AddedFuel > CurrentFleetFuelBar.value):
			return
		if (NewFleetFuelBar.value + AddedFuel > NewFleetFuelBar.max_value):
			AddedFuel = NewFleetFuelBar.max_value - NewFleetFuelBar.value
		if (AddedFuel > 0):
			#NewFleetFuelBar.value += AddedFuel
			AddFuelToFleet(NewFleet, AddedFuel)
			#CurrentFleetFuelBar.value -= AddedFuel
			RemoveFuelFromFleet(CurrentFleet, AddedFuel)
			UpdateCurrentFleetStats()
			UpdateNewFleetStats()
func AddFuelToFleet(Fleet : Array[PlayerDrivenShip], Fuel : float):
	var RemainingFuel = Fuel
	for Ship in Fleet:
		var Dif = Ship.Cpt.GetStatFinalValue(STAT_CONST.STATS.FUEL_TANK) - Ship.Cpt.GetStatCurrentValue(STAT_CONST.STATS.FUEL_TANK)
		var FuelToGive = min(Dif, RemainingFuel)
		Ship.Cpt.RefillResource(STAT_CONST.STATS.FUEL_TANK, FuelToGive)
		RemainingFuel -= FuelToGive
		if (RemainingFuel == 0):
			break
	
func RemoveFuelFromFleet(Fleet : Array[PlayerDrivenShip], Fuel : float):
	var FuelLeftToRemove = Fuel
	for Ship in Fleet:
		var CurrentFuel = Ship.Cpt.GetStatCurrentValue(STAT_CONST.STATS.FUEL_TANK)
		var FuelToTake = min(CurrentFuel, FuelLeftToRemove)
		Ship.Cpt.ConsumeResource(STAT_CONST.STATS.FUEL_TANK, FuelToTake)
		FuelLeftToRemove -= FuelToTake
		if (FuelLeftToRemove == 0):
			return


func _on_button_pressed() -> void:
	SeperationFinished.emit()
