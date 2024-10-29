extends PanelContainer
class_name Inventory_Box

@export var ItemC : ItemContainer

@onready var texture_rect: Button = $TextureRect
@onready var label: Label = $PanelContainer/Label

signal ItemUse(Ic : ItemContainer)

func _ready() -> void:
	var cont = ItemContainer.new()
	ItemC = cont
	ToggleVisuals(false)
	
func GetSaveData() -> Resource:
	return ItemC
	
func ToggleVisuals(t : bool) -> void:
	texture_rect.visible = t
	$PanelContainer.visible = t
	if (!t):
		ItemC.ItemType = null

func RegisterItem(it : Item) -> void:
	ItemC.ItemType = it
	$TextureRect/TextureRect.texture = it.ItemIcon
	if (it is UsableItem):
		$TextureRect/TextureRect.modulate = it.ItecColor
	else:
		$TextureRect/TextureRect.modulate = Color.WHITE

func IsEmpty() -> bool:
	return ItemC.Ammount == 0

func UpdateAmm(Amm : int) -> void:
	ItemC.Ammount += Amm
	$PanelContainer/Label.text = var_to_str(ItemC.Ammount)
	var bollthing = ItemC.Ammount > 0
	ToggleVisuals(bollthing)

func HasSpace() -> bool:
	return ItemC.Ammount < ItemC.ItemType.MaxStackCount

func _on_texture_rect_pressed() -> void:
	if (ItemC.Ammount <= 0):
		return
	ItemUse.emit(ItemC)
