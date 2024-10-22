extends Control
class_name Inventory

@export var InventoryBoxScene : PackedScene
@export var InventoryTradeScene : PackedScene
@export var Upgrades : Array[Upgrade]
@export var Upgrade_Tab_Scene : PackedScene
@export var ItemNotifScene : PackedScene
var InventoryContents : Array[Inventory_Box] = []
@onready var world: World = $"../.."
@onready var inv_contents: GridContainer = $InvContents

signal OnItemAdded(It : Item)
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_process(false)
	inv_contents.visible = false
	for g in PlayerData.GetInstance().INVENTORY_CAPACITY:
		var newbox = InventoryBoxScene.instantiate() as Inventory_Box
		inv_contents.add_child(newbox)
		InventoryContents.append(newbox)
		newbox.connect("ItemUse", UseItem)
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
			InventoryContents[g].UpdateAmm(-1)
			UpTab.UpgradeSuccess()
			world.Upgrage(UpTab.UpgradeData)
			break
	print("No Materials for Upgrade")
	
	
func AddItems(It : Array[Item]) -> void:
	
	var Unplaced : Array[Item] = []
	for z in It.size():
		OnItemAdded.emit(It[z])
		var placed = false
		for g in InventoryContents.size() :
			var box = InventoryContents[g]
			if (box.ItemC.ItemType == It[z]):
				if (box.ItemC.ItemType.MaxStackCount == box.ItemC.Ammount):
					continue
				box.UpdateAmm(1)
				placed = true
		if (placed):
			continue
		for g in InventoryContents.size() :
			var box = InventoryContents[g]
			if (box.IsEmpty()):
				box.RegisterItem(It[z])
				box.UpdateAmm(1)
				placed = true
				break
		if (!placed):
			Unplaced.append(It[z])
	if (Unplaced.size() > 0):
		var TradeScene = InventoryTradeScene.instantiate() as InventoryTrade
		get_parent().add_child(TradeScene)
		var InvItems : Array[Item] = []
		for g in InventoryContents.size():
			var it = InventoryContents[g].ItemC.ItemType
			for z in InventoryContents[g].ItemC.Ammount:
				InvItems.append(it)
		TradeScene.StartTrade(InvItems, Unplaced)
		TradeScene.connect("TradeFinished", TradeFinished)
	else :
		if (It.size() == 0):
			return
		var notif = ItemNotifScene.instantiate() as ItemNotif
		notif.AddItems(It)
		add_child(notif)
func FlushInventory() -> void:
	for g in InventoryContents.size():
		InventoryContents[g].UpdateAmm(-InventoryContents[g].ItemC.Ammount)
func TradeFinished(itms : Array[Item]) -> void:
	FlushInventory()
	AddItems(itms)

func UseItem(It : Item):
	if (world.UseItem(It)):
		for g in InventoryContents.size() :
			var box = InventoryContents[g]
			if (box.ItemC.ItemType == It):
				box.UpdateAmm(-1)
				return
	#Icon = TextureRect.new()
	#Icon.texture = It.ItemIcon
	#get_parent().add_child(Icon)
	#set_process(true)

#var Icon : TextureRect
#func _process(delta: float) -> void:
#	if (Input.is_action_pressed("Click")):
#		Icon.global_position = get_global_mouse_position()
#	else:
#		set_process(false)
#		Icon.queue_free()
func _on_inventory_button_pressed() -> void:
	inv_contents.visible = !inv_contents.visible
func _on_upgrades_button_pressed() -> void:
	$UpgradesContainer.visible = !$UpgradesContainer.visible
