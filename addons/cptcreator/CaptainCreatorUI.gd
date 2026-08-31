@tool
extends EditorDock

class_name CaptainCreatorUI

var Captains : Array[Captain]
var Items : Array[Item]
var CurrentlySelectedCap : Captain


@export var StatScene : PackedScene
@export var ItemBoxScene : PackedScene
@export_group("Captain Info Nodes")
@export var CaptainName : TextEdit
@export var ShipIcon : TextureRect
@export var ItemText : RichTextLabel
@export var AddItemMenu : PopupMenu
@export var Inventory : CharacterInventoryInterface
@export var Stats : CPT_CR_InventoryShipStats
@export var Disp : CaptainDispositionUI
@export var DispSliderParent : Control
var ShowItemStats = true

#------------------------------------------------------------
func _enter_tree() -> void:
	for g in DispositionManager.Dispositions:
		var slider : CapCrStatSlider = StatScene.instantiate()
		DispSliderParent.add_child(slider)
		slider.SetDataCustom(1, "", g, 0, 0.1)
		slider.StatChanged.connect(DispositionChanged.bind(DispositionManager.Dispositions[g]))
		
	RefreshCharacters()
	RefrshExistingItems()
	Inventory.BoxSelected.connect(ItemSelected)

func DispositionChanged(Stat : STAT_CONST.STATS, newValue : float, disp : DispositionManager.Dispositions):
	CurrentlySelectedCap.disp[disp] = newValue
	UpdateInventoryBoxes()
	UpdateDispositionSliders()
	SaveCurrentCap()

#------------------------------------------------------------
func RefreshCharacters() -> void:
	var Menu = $"InputScroll/VBoxContainer/PanelContainer2/HBoxContainer/MenuBar/Select Captain" as PopupMenu
	Menu.clear()
	Captains.clear()
	
	var DirsToExplore :Array[String] = ["res://Resources/Captains/"]
	for g in DirsToExplore:
		var dir = DirAccess.open(g)
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if dir.current_is_dir():
					print("Found directory: " + file_name)
					DirsToExplore.append(g + "/" + file_name)
				else:
					print("Found file: " + file_name)
					var cap = load(g + "/" + file_name)
					if (cap is Captain):
						Captains.append(cap)
						CheckForIssues(cap)
						Menu.add_item(cap.GetCaptainName())
				
				file_name = dir.get_next()
	
	SetCaptain(Captains[0])

#------------------------------------------------------------
func RefrshExistingItems() -> void:
	var DirsToExplore :Array[String] = ["res://Resources/Items"]
	for g in DirsToExplore:
		var dir = DirAccess.open(g)
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if dir.current_is_dir():
					print("Found directory: " + file_name)
					DirsToExplore.append(g + "/" + file_name)
				else:
					print("Found file: " + file_name)
					var It = load(g + "/" + file_name)
					Items.append(It)
				
				file_name = dir.get_next()
				
	#var Menu = AddItemMenu as PopupMenu
	while AddItemMenu.item_count > 0:
		AddItemMenu.remove_item(0)
	for g in Items.size():
		#Menu.add_item(Items[g].ItemName, g)
		AddItemMenu.add_icon_item(Items[g].ItemIcon ,Items[g].ItemName, g)

#------------------------------------------------------------
func _exit_tree() -> void:
	for g in DispSliderParent.get_children():
		g.queue_free()
	Captains.clear()
	Items.clear()

func CheckForIssues(C : Captain) -> void:
	for g in STAT_CONST.STATS.values().size():
		var HasStat = false
		for stat in C.CaptainStats:
			if (stat.StatName == g):
				HasStat = true
				break
		if (!HasStat):
			var NewStat = ShipStat.new()
			NewStat.StatName = g
			C.CaptainStats.append(NewStat)
	
	for g in DispositionManager.Dispositions.values():
		var HasStat = false
		for stat in C.disp:
			if (stat == g):
				HasStat = true
				break
		if (!HasStat):
			C.disp[g] = 0.0
		
		var HasItStat = false
		for stat in C.itemDisposition:
			if (stat == g):
				HasItStat = true
				break
		if (!HasItStat):
			C.itemDisposition[g] = 0.0

#------------------------------------------------------------
func SetCaptain(C : Captain) -> void:
	
	CurrentlySelectedCap = C
	CaptainName.text = C.GetCaptainName()
	ShipIcon.texture = C.ShipIcon
	
	print(C.ProvidingFunds)

	
	CheckForIssues(C)
	

	UpdateInventoryBoxes()
	UpdateDispositionSliders()
	
		
	SaveCurrentCap()
	
#------------------------------------------------------------
func _on_chaptain_select_index_pressed(index: int) -> void:
	SetCaptain(Captains[index])

#------------------------------------------------------------
func SaveCurrentCap() -> void:
	ResourceSaver.save(CurrentlySelectedCap, CurrentlySelectedCap.resource_path)

#------------------------------------------------------------
func InventorySizeChanged() -> void:
	UpdateInventoryBoxes()

#------------------------------------------------------------
func UpdateInventoryBoxes() -> void:
	if (CurrentlySelectedCap._CharInv != null):
		CurrentlySelectedCap._CharInv.queue_free()
		
	var newInventory = CharacterInventory.newInv(CurrentlySelectedCap)
	CurrentlySelectedCap.RegisterInventory(newInventory)
	Inventory.InitialiseInventory(CurrentlySelectedCap)
	Stats.SetCaptainEditor(CurrentlySelectedCap, ShowItemStats)
	Disp.SetStats(CurrentlySelectedCap)
	SelectedBox = null

func UpdateDispositionSliders() -> void:
	for g in Disp.CharacterStats:
		var slid : CapCrStatSlider = DispSliderParent.get_child(g)
		var disp = snappedf(Disp.CharacterStats[g], 0.1)
		slid.UpdateStatCustom(disp, snappedf(Disp.ItemStats[g], 0.1), 0)

#------------------------------------------------------------
func GetShipMaxSpeed() -> float:
	var thrust = CurrentlySelectedCap.GetStatFinalValue(STAT_CONST.STATS.THRUST)
	var weight = CurrentlySelectedCap.GetStatFinalValue(STAT_CONST.STATS.WEIGHT)
	var Spd = (thrust * 1000) / weight

	return Spd

#------------------------------------------------------------
func GetFuelRange() -> float:
	var Weight = CurrentlySelectedCap.GetStatFinalValue(STAT_CONST.STATS.WEIGHT)
	var fuelStats = CurrentlySelectedCap.GetFuelStats()
	
	var fuel = fuelStats["FUEL"]
	var fuel_ef = fuelStats["F_EFF"]
	var fleetsize = 1
	var total_fuel = fuel
	var inverse_ef_sum = 1.0 / ((fuel_ef / pow(Weight, 0.5)) * 10)

	var effective_efficiency = fleetsize / inverse_ef_sum
	# Calculate average efficiency for the group
	return total_fuel * effective_efficiency / fleetsize
	
var SelectedBox : Inventory_Box_Res

#------------------------------------------------------------
func ItemSelected(It : Inventory_Box_Res) -> void:
	SelectedBox = It
	ItemText.text = "{0}\n{1}".format([It._ContainedItem.ItemName, It._ContainedItem.GetItemDesc()])

#------------------------------------------------------------
func _on_remove_item_pressed() -> void:
	if (SelectedBox != null):
		for g in CurrentlySelectedCap.StartingItems.size():
			if (CurrentlySelectedCap.StartingItems[g] == SelectedBox.GetContainedItem()):
				CurrentlySelectedCap.StartingItems.remove_at(g)
				break
	SaveCurrentCap()
	UpdateInventoryBoxes()

#------------------------------------------------------------
func _on_move_item_pressed() -> void:
	if (SelectedBox != null):
		for g in CurrentlySelectedCap.StartingItems.size():
			if (CurrentlySelectedCap.StartingItems[g] == SelectedBox.GetContainedItem()):
				var it = CurrentlySelectedCap.StartingItems[g]
				CurrentlySelectedCap.StartingItems.remove_at(g)
				CurrentlySelectedCap.StartingItems.push_front(it)
				break
	SaveCurrentCap()
	UpdateInventoryBoxes()

#------------------------------------------------------------
func _on_upgrade_item_pressed() -> void:
	if (SelectedBox != null):
		for g in CurrentlySelectedCap.StartingItems.size():
			if (CurrentlySelectedCap.StartingItems[g] == SelectedBox.GetContainedItem()):
				var it = CurrentlySelectedCap.StartingItems[g]
				if (it is ShipPart):
					CurrentlySelectedCap.StartingItems.remove_at(g)
					CurrentlySelectedCap.StartingItems.append(it.UpgradeVersion)
					#CurrentlySelectedCap.StartingItems.push_front(it)
				break
	SaveCurrentCap()
	UpdateInventoryBoxes()

#------------------------------------------------------------
func _on_item_select_index_pressed(index: int) -> void:
	CurrentlySelectedCap.StartingItems.append(Items[index])
	SaveCurrentCap()
	UpdateInventoryBoxes()

#------------------------------------------------------------
func _on_cap_name_text_changed() -> void:
	var NewLine = CaptainName.text
	print("Changed {0}'s name to {1} and saved to file {2}".format([CurrentlySelectedCap.GetCaptainName(), NewLine, CurrentlySelectedCap.resource_path]))
	CurrentlySelectedCap.CaptainName = NewLine
	ResourceSaver.save(CurrentlySelectedCap, CurrentlySelectedCap.resource_path)


## ITEMS
#func AddItem(It : Item) -> void:
	#var boxes
	#if (It is ShipPart):
		#boxes = GetBoxParentForType(It.PartType).get_children()
	#else:
		#boxes = InventoryBoxParent.get_children()
		#
	#var Empty : Inventory_Box = null
#
	#for g in boxes:
		#if (g.IsEmpty()):
			#if (Empty == null):
				#Empty = g
			#continue
		#if (g.GetContainedItemName() == It.ItemName and g.HasSpace()):
			#g.UpdateAmm(1)
			#break
#
	#if (Empty != null):
		#Empty.RegisterItem(It)
		#Empty.UpdateAmm(1)
	#
	#if (!ShowItemStats):
		#return
	#if (It is ShipPart):
		#print(It.resource_name + " is ship part")
		#var up = It.Upgrades
		#for g : ShipPartUpgrade in up:
			#FindSliderWithStat(g.UpgradeName).AddToItemStat(g.UpgradeAmmount, g.PenaltyAmmount)

#------------------------------------------------------------
func FindSliderWithStat(St : STAT_CONST.STATS) -> CapCrStatSlider:

	return null

#------------------------------------------------------------
func _on_change_pic_pressed() -> void:
	var fd = EditorFileDialog.new()
	#fd.mode = Window.MODE_EXCLUSIVE_FULLSCREEN
	fd.access = EditorFileDialog.ACCESS_RESOURCES
	EditorInterface.get_base_control().add_child(fd)
	fd.connect("file_selected", NewPicSelected)
	fd.popup_file_dialog()
	#get_parent().add_child(fd)
	#var d = await fd.file_selected
	
#------------------------------------------------------------
func NewPicSelected(NewPic) -> void:
	CurrentlySelectedCap.CaptainPortrait = NewPic
	SaveCurrentCap()

#------------------------------------------------------------
func _on_change_ship_icon_pressed() -> void:
	var fd = EditorFileDialog.new()
	#fd.mode = Window.MODE_EXCLUSIVE_FULLSCREEN
	fd.access = EditorFileDialog.ACCESS_RESOURCES
	EditorInterface.get_base_control().add_child(fd)
	fd.connect("file_selected", NewShipPicSelected)
	fd.popup_file_dialog()
	#get_parent().add_child(fd)
	#var d = await fd.file_selected

#------------------------------------------------------------
func NewShipPicSelected(NewPic) -> void:
	CurrentlySelectedCap.ShipIcon = load(NewPic)
	SaveCurrentCap()
	ShipIcon.texture = CurrentlySelectedCap.ShipIcon

#------------------------------------------------------------
func _on_show_it_stats_toggled(toggled_on: bool) -> void:
	ShowItemStats = toggled_on
	UpdateInventoryBoxes()

#------------------------------------------------------------
func _on_starting_funds_value_changed(value: float) -> void:
	CurrentlySelectedCap.ProvidingFunds = value
	SaveCurrentCap()
	print("StartingFundsUpdated " + var_to_str(value))

#------------------------------------------------------------
func _on_inventory_ship_stats_stat_changed(stat : STAT_CONST.STATS, value : float) -> void:
	if (stat == STAT_CONST.STATS.VALUE):
		CurrentlySelectedCap.ProvidingFunds = value
	else:
		CurrentlySelectedCap._GetStat(stat).StatBase = value
	UpdateInventoryBoxes()
