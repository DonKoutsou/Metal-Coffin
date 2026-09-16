extends PanelContainer

class_name CaptainStatContainer

@export_group("Scenes")
@export_file("*.tscn") var statScene : String
@export_file("*.tscn") var DeckScene : String
@export_file("*.tscn") var InventoryScene : String
@export_file("*.tscn") var LegendScene : String
@export_file("*.tscn") var DispositionScene : String

var ShipStats : InventoryShipStats
var ShipDeck : ShipDeckViz
var ShipInventory : CharacterInventoryInterface
var DispositionScreen : CaptainDispositionUI

@export_group("Nodes")
@export var CaptainIcon : TextureRect
@export var CaptainIcon2 : TextureRect

var currentStats : Control

var CurrentlyShownCaptain : Captain

signal InventoryBoxSelected(box : Inventory_Box_Res, inv : CharacterInventory)


func SetCaptain(Cha : Captain) -> void:
	if (CurrentlyShownCaptain == Cha):
		return
	CurrentlyShownCaptain = Cha
	
	if (ShipStats != null):
		ShipStats.SetCaptain(Cha)
	
	if (ShipDeck != null):
		ShipDeck.SetDeck(Cha)
	
	if (ShipInventory != null):
		ShipInventory.InitialiseInventory(Cha)
	
	if (DispositionScreen != null):
		DispositionScreen.SetStats(Cha)
	CaptainIcon.texture = Cha.ShipIcon
	if (Cha.CaptainPortrait != ""):
		CaptainIcon2.texture = load(Cha.CaptainPortrait)
	else:
		CaptainIcon2.texture = null

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
	currentStats.queue_free()
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
	if (ShipStats != null):
		return
	var shipStatScene : PackedScene = load(statScene)
	ShipStats = shipStatScene.instantiate()
	
	var LegendSc : PackedScene = load(LegendScene)
	var Legend : Control = LegendSc.instantiate()
	
	var statParent = VBoxContainer.new()
	statParent.add_child(Legend)
	statParent.add_child(ShipStats)
	statParent.size_flags_vertical = Control.SIZE_EXPAND_FILL
	statParent.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	$PanelContainer.add_child(statParent)
	transitionToPanel(statParent)
	ShipStats.SetCaptain(CurrentlyShownCaptain)
	ShipStats.UpdateValues()

func ShowDeck() -> void:
	if (ShipDeck != null):
		return
	var shipdeckScene : PackedScene = load(DeckScene)
	ShipDeck = shipdeckScene.instantiate()
	$PanelContainer.add_child(ShipDeck)
	ActionTracker.OnActionCompleted(ActionTracker.Action.DECK)
	ShipDeck.SetDeck(CurrentlyShownCaptain)
	transitionToPanel(ShipDeck)

func ShowInvetory() -> void:
	if (ShipInventory != null):
		return
	var shipInventoryScene : PackedScene = load(InventoryScene)
	ShipInventory = shipInventoryScene.instantiate()
	var inventoryParent = InputScroll.new()
	inventoryParent.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inventoryParent.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	inventoryParent.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	$PanelContainer.add_child(inventoryParent)
	inventoryParent.add_child(ShipInventory)
	ShipInventory.InitialiseInventory(CurrentlyShownCaptain)
	ShipInventory.BoxSelected.connect(_on_inventory_interface_box_selected)
	transitionToPanel(inventoryParent)

func ShowDisposition() -> void:
	if (DispositionScreen != null):
		return
	var dispositionSc : PackedScene = load(DispositionScene)
	DispositionScreen = dispositionSc.instantiate()
	
	var LegendSc : PackedScene = load(LegendScene)
	var Legend : Control = LegendSc.instantiate()
	
	var dispositionParent = VBoxContainer.new()
	dispositionParent.add_child(Legend)
	dispositionParent.add_child(DispositionScreen)
	dispositionParent.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dispositionParent.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	$PanelContainer.add_child(dispositionParent)
	transitionToPanel(dispositionParent)
	
	DispositionScreen.SetStats(CurrentlyShownCaptain)
	
	ActionTracker.OnActionCompleted(ActionTracker.Action.DISPOSITION)
	transitionToPanel(dispositionParent)

func UpdateValues() -> void:
	if (CurrentlyShownCaptain == null):
		return
	if (ShipStats != null):
		ShipStats.UpdateValues()
	if (ShipStats != null):
		ShipDeck.SetDeck(CurrentlyShownCaptain)

func _on_inventory_interface_box_selected(Box: Inventory_Box_Res) -> void:
	InventoryBoxSelected.emit(Box, CurrentlyShownCaptain.GetCharacterInventory())
