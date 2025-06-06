extends PanelContainer

class_name CageFightItem

@export var ItemName : Label

signal OnItemBought()

var Itm : Item

func _ready() -> void:
	ItemName.text = Itm.ItemName

func Init(It : Item) -> void:
	Itm = It

var Accum : float = 0
func InstallButtonPressed() -> void:
	OnItemBought.emit()

func ToggleDetails(t : bool) -> void:
	$VBoxContainer/HBoxContainer.visible = t
	$VBoxContainer/ProgressBar.visible = t
