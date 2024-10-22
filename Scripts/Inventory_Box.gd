extends PanelContainer
class_name Inventory_Box

@export var ItemC : ItemContainer

@onready var texture_rect: Button = $TextureRect
@onready var label: Label = $PanelContainer/Label

signal ItemUse(it : Item)

func _ready() -> void:
	ToggleVisuals(false)
	var cont = ItemContainer.new()
	ItemC = cont

func ToggleVisuals(t : bool) -> void:
	texture_rect.visible = t
	$PanelContainer.visible = t

func RegisterItem(it : Item) -> void:
	ItemC.ItemType = it
	$TextureRect.icon = it.ItemIcon

func IsEmpty() -> bool:
	return ItemC.Ammount == 0
	
func UpdateAmm(Amm : int) -> void:
	ItemC.Ammount += Amm
	$PanelContainer/Label.text = var_to_str(ItemC.Ammount)
	ToggleVisuals(ItemC.Ammount > 0)

func _on_texture_rect_pressed() -> void:
	if (ItemC.Ammount <= 0):
		return
	ItemUse.emit(ItemC.ItemType)
