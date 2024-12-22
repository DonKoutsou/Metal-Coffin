extends PanelContainer
class_name CaptainUI

@export var DroneDockEvH : DroneDockEventHandler
@export var CaptainStatpScene : PackedScene
@export var EmptySlotScene : PackedScene

var Drones : Array[Drone]

static var Instance : CaptainUI

func _ready() -> void:
	DroneDockEvH.connect("DroneAdded", AddCaptain)
	Instance = self
static func GetInstance() -> CaptainUI:
	return Instance
func AddCaptain(Dr : Drone):
	var Position : Control
	for g in $GridContainer.get_children():
		if (g is CaptainPanel):
			continue
		Position = g
		Position.get_child(0).free()
		break
	Drones.append(Dr)
	var cptscene = CaptainStatpScene.instantiate() as CaptainPanel
	cptscene.connect("OnCaptainDischarged", OnCaptainDischarged)
	Position.replace_by(cptscene)
	Position.free()
	cptscene.SetCap(Dr.Cpt)

func ToggleUI(t : bool) -> void:
	$"../../../../../../..".OnScreenUiToggled(t)
func _on_captain_button_pressed() -> void:
	
	if (!visible):
		$"../../../../../../..".OnScreenUiToggled(false)
		InventoryUI.GetInstance().visible = false
	else:
		$"../../../../../../..".OnScreenUiToggled(true)
	visible = !visible

func OnCaptainDischarged(C : Captain):
	for g in $GridContainer.get_children():
		if (g is CaptainPanel):
			if (g.Capt == C):
				g.queue_free()
				break
	for g in Drones:
		if (g.Cpt == C):
			DroneDockEvH.OnDroneDischarged(g)
			$GridContainer.add_child(EmptySlotScene.instantiate())
			return
