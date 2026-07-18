extends PanelContainer

class_name CaptainStatContainer

@export var ShipStats : InventoryShipStats
@export var ShipDeck : ShipDeckViz
@export var ShipInventory : CharacterInventoryInterface
@export var CaptainIcon : TextureRect

var CurrentlyShownCaptain : Captain

signal InventoryBoxSelected(box : Inventory_Box_Res, inv : CharacterInventory)

func SetCaptain(Cha : Captain) -> void:
	CurrentlyShownCaptain = Cha
	ShipStats.SetCaptain(Cha)
	ShipDeck.SetDeck(Cha)
	ShipInventory.InitialiseInventory(Cha.GetCharacterInventory())
	CaptainIcon.texture = Cha.ShipIcon

func ShowStats() -> void:
	ShipStats.visible = true
	ShipDeck.visible = false
	ShipInventory.visible = false

func ShowOnlyStats(stats : Array[STAT_CONST.STATS]) -> void:
	ShipStats.ShowStats(stats)

func ShowDeck() -> void:
	ShipStats.visible = false
	ShipDeck.visible = true
	ShipInventory.visible = false

func ShowInvetory() -> void:
	ShipInventory.visible = true
	ShipStats.visible = false
	ShipDeck.visible = false

func UpdateValues() -> void:
	if (CurrentlyShownCaptain == null):
		return
	ShipStats.UpdateValues()
	ShipDeck.SetDeck(CurrentlyShownCaptain)


func _on_inventory_interface_box_selected(Box: Inventory_Box_Res) -> void:
	InventoryBoxSelected.emit(Box, CurrentlyShownCaptain.GetCharacterInventory())
