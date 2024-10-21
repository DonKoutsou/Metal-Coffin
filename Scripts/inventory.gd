extends Control
class_name Inventory

@export var InventoryBoxScene : PackedScene
@export var Upgrades : Array[Upgrade]
@export var Upgrade_Tab_Scene : PackedScene
var InventoryContents : Array[Inventory_Box] = []
@onready var world: World = $"../../.."

signal OnItemAdded(It : Item)
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$InvContents.visible = false
	for g in Upgrades.size():
		var Tab = Upgrade_Tab_Scene.instantiate() as UpgradeTab
		$UpgradesContainer/VBoxContainer.add_child(Tab)
		Tab.SetData(Upgrades[g].UpgradeName, Upgrades[g].UpgradeItem.ItemIconSmol)
		Tab.connect("OnUgradePressed", TryUpgrade)
func TryUpgrade(UpTab : UpgradeTab) -> void:
	print("Trying to upgrade " + UpTab.Upgradename)
	var upgrade : Upgrade
	for g in Upgrades.size():
		if (Upgrades[g].UpgradeName == UpTab.Upgradename):
			upgrade = Upgrades[g]
			break
	var UpgradeCost = upgrade.UpgradeItem
	for g in InventoryContents.size():
		if (InventoryContents[g].ItemC.ItemType == UpgradeCost and InventoryContents[g].ItemC.Ammount > 0):
			InventoryContents[g].UpdateAmm(-1)
			UpTab.UpgradeSuccess()
			world.Upgrage(UpTab.Upgradename)
			
	print("No Materials for Upgrade")
	
	
func AddItem(It : Item) -> void:
	OnItemAdded.emit(It)
	for g in InventoryContents.size() :
		var box = InventoryContents[g]
		if (box.ItemC.ItemType == It):
			box.UpdateAmm(1)
			return
	var newbox = InventoryBoxScene.instantiate() as Inventory_Box
	$InvContents.add_child(newbox)
	var newcont = ItemContainer.new()
	newcont.ItemType = It
	newbox.AddIcon(newcont.ItemType.ItemIcon)
	newbox.ItemC = newcont
	newbox.UpdateAmm(1)
	InventoryContents.insert(InventoryContents.size(),newbox)
	newbox.connect("ItemUse", UseItem)

func UseItem(It : Item):
	if (world.UseItem(It)):
		for g in InventoryContents.size() :
			var box = InventoryContents[g]
			if (box.ItemC.ItemType == It):
				box.UpdateAmm(-1)
				return
func _on_inventory_button_pressed() -> void:
	$InvContents.visible = !$InvContents.visible
func _on_upgrades_button_pressed() -> void:
	$UpgradesContainer.visible = !$UpgradesContainer.visible
