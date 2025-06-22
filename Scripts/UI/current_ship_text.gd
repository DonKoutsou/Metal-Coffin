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
	
	if (PanelLocation.get_child_count() != Commanders.size()):
		for g in PanelLocation.get_children():
			g.free()
		for g in Commanders.size():
			PanelLocation.add_child(CurrentShipPanelScene.instantiate())
	
	for Command in Commanders.size():
		var CurrentCommand = Commanders[Command]
		
		var FleetPanel = PanelLocation.get_child(Command) as CurrentShipPanel
		
		var Text : Array[String] = []
		var Selected = -1
		Text.append("-Fleet{0}-".format([Command + 1]))
		var hull = CurrentCommand.Cpt.GetStatCurrentValue(STAT_CONST.STATS.HULL) / CurrentCommand.Cpt.GetStatFinalValue(STAT_CONST.STATS.HULL) * 100
		Text.append("{0}\nHULL:{1}%".format([ CurrentCommand.Cpt.GetCaptainName().to_upper(), roundi(hull)]))
		if (CurrentCommand == currentShip):
			Selected = 1
		
		var DockedShips = CurrentCommand.GetDroneDock().DockedDrones
		
		for Docked in DockedShips.size():
			var D = DockedShips[Docked]
			var h = D.Cpt.GetStatCurrentValue(STAT_CONST.STATS.HULL) / D.Cpt.GetStatFinalValue(STAT_CONST.STATS.HULL) * 100
			Text.append("{0}\nHULL:{1}%".format([D.Cpt.GetCaptainName().to_upper(), roundi(h)]))
			if (D == currentShip):
				Selected = Docked + 2
		
		FleetPanel.SetText(Text)
		FleetPanel.SetSelected(Selected)
		
#roundi(hull)
