extends Control

@export var ShipControllerEventH : ShipControllerEventHandler
@export var CurrentShipPanelScene : PackedScene
@export var PanelLocation : Control

var currentShip : PlayerDrivenShip

func _ready() -> void:
	currentShip = ShipControllerEventH.CurrentControlled
	ShipControllerEventH.connect("OnControlledShipChanged", ShipChanged)

func ShipChanged(NewShip : PlayerDrivenShip) -> void:
	currentShip = NewShip
	d = 0

var d = 0.4
func _physics_process(delta: float) -> void:
	d -= delta
	if d > 0:
		return
	d = 0.4

	var Ships = get_tree().get_nodes_in_group("PlayerShips")
	var Commanders : Array[PlayerDrivenShip]
	
	for Ship : PlayerDrivenShip in Ships:
		if (Ship.Command != null):
			continue
		Commanders.append(Ship)
	
	if (PanelLocation.get_child_count() != Ships.size() + Commanders.size()):
		for g in PanelLocation.get_children():
			g.free()
		for g in Ships.size() + Commanders.size():
			var Pan = CurrentShipPanelScene.instantiate() as CurrentShipPanel
			PanelLocation.add_child(Pan)
			Pan.Selected.connect(Selected)
	var Index = 0
	
	for Command in Commanders.size():
		var CurrentCommand = Commanders[Command]
		
		var FleetPanel = PanelLocation.get_child(Index) as CurrentShipPanel
		FleetPanel.SetText("", false)
		Index += 1
		
		var hull = CurrentCommand.Cpt.GetStatCurrentValue(STAT_CONST.STATS.HULL) / CurrentCommand.Cpt.GetStatFinalValue(STAT_CONST.STATS.HULL) * 100
		var CommanderPanel = PanelLocation.get_child(Index) as CurrentShipPanel
		CommanderPanel.SetText("{0}\nHull:{1}%".format([ CurrentCommand.Cpt.GetCaptainName(), roundi(hull)]), false)
		CommanderPanel.SetSelected(CurrentCommand == currentShip)
		CommanderPanel.ConnectedShip = CurrentCommand
		Index += 1
		
		var DockedShips = CurrentCommand.GetDroneDock().DockedDrones
		
		for Docked in DockedShips:
			var DockedPanel = PanelLocation.get_child(Index) as CurrentShipPanel
			
			var h = Docked.Cpt.GetStatCurrentValue(STAT_CONST.STATS.HULL) / Docked.Cpt.GetStatFinalValue(STAT_CONST.STATS.HULL) * 100
			DockedPanel.SetText("{0}\nHull:{1}%".format([Docked.Cpt.GetCaptainName(), roundi(h)]), false)
			DockedPanel.SetSelected(Docked == currentShip)
			DockedPanel.ConnectedShip = Docked
			Index += 1
		
#roundi(hull)

func Selected(Ship : PlayerDrivenShip) -> void:
	ShipControllerEventH.ShipChanged(Ship)
