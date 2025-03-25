extends PanelContainer

class_name CardFightShipInfo

@export var CaptainPortrait : TextureRect
@export var ShipIcon : TextureRect
@export var ShipName : Label
@export var ShipDesc : Label
@export var CardPlecement : Control

@export var CardScene : PackedScene

func _ready() -> void:
	UISoundMan.GetInstance().AddSelf($VBoxContainer/Button)

func SetUpShip(Ship : BattleShipStats) -> void:
	CaptainPortrait.texture = Ship.CaptainIcon
	ShipIcon.texture = Ship.ShipIcon
	ShipName.text = Ship.Name
	#ShipDesctext = Ship.
	for g in Ship.Cards.keys():
		var C = CardScene.instantiate() as Card
		C.SetCardStats(g, [])
		CardPlecement.add_child(C)
		C.Dissable()
func _on_scroll_container_gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseMotion and Input.is_action_pressed("Click")):
		$VBoxContainer/HBoxContainer/PanelContainer3/VBoxContainer/Cards.scroll_vertical -= event.relative.y

func _on_button_pressed() -> void:
	queue_free()
