extends PanelContainer

class_name FleetSeparationShipViz

@export var CapPortrait : TextureRect
@export var ShipIcon : TextureRect
@export var CapName : Label


signal OnShipSelected

var ContainedShip : MapShip

func SetShip(Ship : MapShip) -> void:
	ContainedShip = Ship
	CapPortrait.texture = Ship.Cpt.CaptainPortrait
	ShipIcon.texture = Ship.Cpt.ShipIcon
	CapName.text = Ship.Cpt.CaptainName



func _on_button_pressed() -> void:
	OnShipSelected.emit()
