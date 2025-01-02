extends PanelContainer

class_name Card

signal OnCardPressed(C : Card, Options : String)

var CStats : CardStats

var Option : String

var Cost : int

func _ready() -> void:
	$PanelContainer.visible = false
	#var st = CardStats.new()
	#st.CardName = "Barrage"
	#st.Energy = 1
	#st.Icon = load("res://Assets/Items/rocket.png")
	#st.Options.append_array(["FIRE", "AP", "NORMAL"])
	#SetCardStats(st)

func SetCardStats(Stats : CardStats, Option : String = "") -> void:
	CStats = Stats

	$VBoxContainer/CardName.text = Option + " " + Stats.CardName
	$VBoxContainer/CardIcon.texture = Stats.Icon
	$VBoxContainer/CardDesc.text = Stats.CardDescription
	$VBoxContainer/CardCost.text = var_to_str(Stats.Energy)
	Cost = Stats.Energy
	for g in Stats.Options:
		var OptionBut = Button.new()
		OptionBut.text = g
		$PanelContainer/HBoxContainer.add_child(OptionBut)
		OptionBut.connect("pressed", OnOptionSelected)

func OnButtonPressed() -> void:
	if ($PanelContainer/HBoxContainer.get_child_count() > 0):
		$PanelContainer.visible = true
	else:
		OnCardPressed.emit(self, "")

func OnOptionSelected() -> void:
	var but = get_viewport().gui_get_focus_owner() as Button
	Option = but.text
	$PanelContainer.visible = false
	OnCardPressed.emit(self, but.text)
