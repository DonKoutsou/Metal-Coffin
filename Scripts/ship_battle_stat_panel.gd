extends PanelContainer

class_name ShipBattleStatPanel

@export var StatScene : PackedScene

signal OnShipSelected(Ship : ShipBattleStatPanel)

var stats

func SetShip(Ship : BattleShipStats):
	stats = Ship
	$VBoxContainer/PanelContainer/Label.text = Ship.Name
	$VBoxContainer/TextureRect.texture = Ship.ShipIcon
	$PanelContainer/TextureRect.texture = Ship.CaptainIcon
	var sc = StatScene.instantiate() as ShipBattleStatContainer
	$VBoxContainer.add_child(sc)
	#$VBoxContainer.move_child(sc, $VBoxContainer.get_child_count() - 2)
	sc.SetData("Hull", Ship.Hull, 100.0)
	var sc2 = StatScene.instantiate() as ShipBattleStatContainer
	$VBoxContainer.add_child(sc2)
	#$VBoxContainer.move_child(sc, $VBoxContainer.get_child_count() - 2)
	sc2.SetData("Firepower", Ship.FirePower, 3.0)
	#$VBoxContainer/ShipStatContainer.SetData(cpt.GetStat("SPEED"))
	#$VBoxContainer/ShipStatContainer2.SetData(cpt.GetStat("RADAR_RANGE"))
	#$VBoxContainer/ShipStatContainer3.SetData(cpt.GetStat("ANALYZE_RANGE"))
	#$VBoxContainer/ShipStatContainer4.SetData(cpt.GetStat("INVENTORY_CAPACITY"))


func ToggleClickable(T : bool):
	$Button.disabled = !T

func _on_button_pressed() -> void:
	OnShipSelected.emit(self)

func SetNumber(Num : int):
	$Label.text = var_to_str(Num)
	$Label.visible = true

func RedactNumber():
	$Label.visible = false
