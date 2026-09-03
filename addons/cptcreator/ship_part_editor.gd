@tool
extends EditorDock

class_name ShipPartEditor

@export var ItemMenu : PopupMenu
@export var ItemNameLabel : Label
@export var ItemDescLabel : RichTextLabel
@export var slider : CapCrStatSlider
var Items : Array[Item]

var CurrentlySelectedItem : Item
#------------------------------------------------------------
func _enter_tree() -> void:
	RefrshExistingItems()
	SetItem(randi_range(0, Items.size() - 1))

#------------------------------------------------------------
func SaveCurrentItem() -> void:
	ResourceSaver.save(CurrentlySelectedItem, CurrentlySelectedItem.resource_path)

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
	while ItemMenu.item_count > 0:
		ItemMenu.remove_item(0)
	for g in Items.size():
		#Menu.add_item(Items[g].ItemName, g)
		ItemMenu.add_icon_item(Items[g].ItemIcon ,Items[g].ItemName, g)

func SetItem(index : int) -> void:
	CurrentlySelectedItem = Items[index]
	ItemNameLabel.text = CurrentlySelectedItem.GetItemName()
	ItemDescLabel.text = CurrentlySelectedItem.GetItemDesc()
	UpdateData()

func UpdateData() -> void:

	slider.SetDataCustom(300000, "₯", "VALUE", STAT_CONST.STATS.VALUE, 100)
	slider.UpdateStatCustom(CurrentlySelectedItem.Cost, 0, 0)
	slider.UpdateStatValue(CurrentlySelectedItem.Cost, 0, 0)

func _on_items_index_pressed(index: int) -> void:
	SetItem(index)


func _on_ship_stat_container_stat_changed(stat : STAT_CONST.STATS, value : float) -> void:
	CurrentlySelectedItem.Cost = value
	SaveCurrentItem()
	UpdateData()
