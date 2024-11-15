extends PanelContainer

class_name CaptainPanel

signal OnCaptainDischarged(C : Captain)

var Capt : Captain

func SetCap(cpt : Captain):
	Capt = cpt
	$VBoxContainer/PanelContainer/Label.text = cpt.CaptainName
	$PanelContainer/TextureRect.texture = cpt.CaptainPortrait
	$VBoxContainer/ShipStatContainer.SetData(cpt.GetStat("SPEED"))
	$VBoxContainer/ShipStatContainer2.SetData(cpt.GetStat("RADAR_RANGE"))
	$VBoxContainer/ShipStatContainer3.SetData(cpt.GetStat("ANALYZE_RANGE"))
	$VBoxContainer/ShipStatContainer4.SetData(cpt.GetStat("INVENTORY_SPACE"))

func DischargeCaprain():
	OnCaptainDischarged.emit(Capt)
	queue_free()
