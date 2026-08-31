extends PanelContainer

class_name CaptainStatContainer

@export var ShipStats : InventoryShipStats
@export var ShipDeck : ShipDeckViz
@export var ShipInventory : CharacterInventoryInterface
@export var DispositionScreen : CaptainDispositionUI
@export var CaptainIcon : TextureRect

var currentStats : Control

var CurrentlyShownCaptain : Captain

signal InventoryBoxSelected(box : Inventory_Box_Res, inv : CharacterInventory)

func SetCaptain(Cha : Captain) -> void:
	CurrentlyShownCaptain = Cha
	ShipStats.SetCaptain(Cha)
	ShipDeck.SetDeck(Cha)
	ShipInventory.InitialiseInventory(Cha)
	DispositionScreen.SetStats(Cha)
	CaptainIcon.texture = Cha.ShipIcon

#var tw : Tween


func transitionToPanel(panel: Control) -> void:
	if (currentStats == null):
		currentStats = panel
		currentStats.visible = true
		return
	if (currentStats == panel):
		return
	#if (tw != null):
		#
		#tw.kill()
		#tw.finished.emit()
	
	currentStats.visible = false
	panel.visible = true
	currentStats = panel
	
	#tw = create_tween()
	#tw.set_ease(Tween.EASE_IN_OUT)
	#tw.set_trans(Tween.TRANS_CIRC)
	#
	#tw.tween_property(currentStats, "position", currentStats.position + Vector2(size.x, 0), 0.5)
	##tw.set_parallel()
	##panel.position = Vector2(-100 ,panel.position.y)
	##tw.tween_property(panel, "position", Vector2(8, 0), 1)
	##panel.visible = true
	#tw.finished.connect(currentStats.hide)
	#tw.finished.connect(panel.show)
	

func ShowOnlyStats(stats : Array[STAT_CONST.STATS]) -> void:
	ShipStats.ShowStats(stats)

func ShowStats() -> void:
	transitionToPanel(ShipStats)
	ShipStats.UpdateValues()

func ShowDeck() -> void:
	ActionTracker.OnActionCompleted(ActionTracker.Action.DECK)
	transitionToPanel(ShipDeck)

func ShowInvetory() -> void:
	transitionToPanel(ShipInventory.get_parent())

func ShowDisposition() -> void:
	ActionTracker.OnActionCompleted(ActionTracker.Action.DISPOSITION)
	transitionToPanel(DispositionScreen.get_parent())

func UpdateValues() -> void:
	if (CurrentlyShownCaptain == null):
		return
	ShipStats.UpdateValues()
	ShipDeck.SetDeck(CurrentlyShownCaptain)

func _on_inventory_interface_box_selected(Box: Inventory_Box_Res) -> void:
	InventoryBoxSelected.emit(Box, CurrentlyShownCaptain.GetCharacterInventory())
