extends PanelContainer

class_name HappeningInstance

var Hp : Happening

func _ready() -> void:
	PresentHappening(load("res://Resources/Happenings/TestHappening.tres"))

func PresentHappening(Hap : Happening):
	Hp = Hap
	$VBoxContainer/Label.text = Hap.HappeningName
	$VBoxContainer/Label2.text = Hap.HappeningText
	
	var OptionAmm = Hap.GetOptionsCount()
	for g in $VBoxContainer/HBoxContainer.get_child_count():
		var but = $VBoxContainer/HBoxContainer.get_child(g)
		if (g >= OptionAmm):
			but.visible = false
			continue
		but.text = Hap.Options[g].OptionName

func _on_option_1_pressed() -> void:
	$VBoxContainer/Label2.text = Hp.Options[0].OptionResault()

func _on_option_2_pressed() -> void:
	$VBoxContainer/Label2.text = Hp.Options[1].OptionResault()

func _on_option_3_pressed() -> void:
	$VBoxContainer/Label2.text = Hp.Options[2].OptionResault()

func _on_option_4_pressed() -> void:
	$VBoxContainer/Label2.text = Hp.Options[3].OptionResault()
