extends Control
class_name Inventory

@export var InventoryBoxScene : PackedScene
@export var Upgrades : Array[Upgrade]
@export var Upgrade_Tab_Scene : PackedScene
@export var ItemNotifScene : PackedScene
var InventoryContents : Array[Inventory_Box] = []
@onready var world: World = $"../.."
@onready var inv_contents: HBoxContainer = $HBoxContainer/InvContents

signal OnItemAdded(It : Item)
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	inv_contents.visible = false
	for g in Upgrades.size():
		var Tab = Upgrade_Tab_Scene.instantiate() as UpgradeTab
		$UpgradesContainer/VBoxContainer.add_child(Tab)
		Tab.SetData(Upgrades[g])
		Tab.connect("OnUgradePressed", TryUpgrade)
		
func TryUpgrade(UpTab : UpgradeTab) -> void:
	print("Trying to upgrade " + UpTab.UpgradeData.UpgradeName)
	var upgrade : Upgrade
	for g in Upgrades.size():
		if (Upgrades[g].UpgradeName == UpTab.UpgradeData.UpgradeName):
			upgrade = Upgrades[g]
			break
	var UpgradeCost = upgrade.UpgradeItem
	for g in InventoryContents.size():
		if (InventoryContents[g].ItemC.ItemType == UpgradeCost and InventoryContents[g].ItemC.Ammount > 0):
			var amm = InventoryContents[g].UpdateAmm(-1)
			if (amm == 0):
				InventoryContents[g].queue_free()
				InventoryContents.remove_at(g)
			UpTab.UpgradeSuccess()
			world.Upgrage(UpTab.UpgradeData)
			break
	print("No Materials for Upgrade")
	
	
func AddItems(It : Array[Item]) -> void:
	if (It.size() == 0):
		return
	var notif = ItemNotifScene.instantiate() as ItemNotif
	notif.AddItems(It)
	add_child(notif)
	for z in It.size():
		OnItemAdded.emit(It[z])
		var placed = false
		for g in InventoryContents.size() :
			var box = InventoryContents[g]
			if (box.ItemC.ItemType == It[z]):
				box.UpdateAmm(1)
				placed = true
		if (placed):
			continue
		var newbox = InventoryBoxScene.instantiate() as Inventory_Box
		inv_contents.add_child(newbox)
		var newcont = ItemContainer.new()
		newcont.ItemType = It[z]
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
				var amm = box.UpdateAmm(-1)
				if (amm == 0):
					InventoryContents[g].queue_free()
					InventoryContents.remove_at(g)
				return
func _on_inventory_button_pressed() -> void:
	inv_contents.visible = !inv_contents.visible
func _on_upgrades_button_pressed() -> void:
	$UpgradesContainer.visible = !$UpgradesContainer.visible
