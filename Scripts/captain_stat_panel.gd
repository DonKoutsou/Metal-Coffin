extends PanelContainer

class_name CaptainPanel

@export var StatScene : PackedScene

signal OnCaptainDischarged(C : Captain)

var Capt : Captain

func SetCap(cpt : Captain):
	Capt = cpt
	$VBoxContainer/PanelContainer/Label.text = cpt.CaptainName
	$PanelContainer/TextureRect.texture = cpt.CaptainPortrait
	for g in cpt.CaptainStats:
		var sc = StatScene.instantiate() as CaptainStatContainer
		$VBoxContainer.add_child(sc)
		$VBoxContainer.move_child(sc, $VBoxContainer.get_child_count() - 2)
		sc.SetData(g)
	#$VBoxContainer/ShipStatContainer.SetData(cpt.GetStat("SPEED"))
	#$VBoxContainer/ShipStatContainer2.SetData(cpt.GetStat("RADAR_RANGE"))
	#$VBoxContainer/ShipStatContainer3.SetData(cpt.GetStat("ANALYZE_RANGE"))
	#$VBoxContainer/ShipStatContainer4.SetData(cpt.GetStat("INVENTORY_CAPACITY"))

func DischargeCaprain():
	OnCaptainDischarged.emit(Capt)
	#queue_free()
