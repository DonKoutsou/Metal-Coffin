extends PanelContainer

class_name CaptainStatContainer

@export var ShipStats : InventoryShipStats
@export var ShipDeck : ShipDeckViz
@export var CaptainIcon : TextureRect

var CurrentlyShownCaptain : Captain

func SetCaptain(Cha : Captain) -> void:
	CurrentlyShownCaptain = Cha
	ShipStats.SetCaptain(Cha)
	ShipDeck.SetDeck(Cha)
	CaptainIcon.texture = Cha.ShipIcon

func ShowStats() -> void:
	ShipStats.visible = true
	ShipDeck.visible = false

func ShowDeck() -> void:
	ShipStats.visible = false
	ShipDeck.visible = true

func UpdateValues() -> void:
	if (CurrentlyShownCaptain == null):
		return
	ShipStats.UpdateValues()
	ShipDeck.SetDeck(CurrentlyShownCaptain)
