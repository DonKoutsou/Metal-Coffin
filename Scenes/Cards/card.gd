extends PanelContainer

class_name Card

signal OnCardPressed(C : Card, Options : CardOption)

var CStats : CardStats

var Cost : int

func _ready() -> void:
	$PanelContainer.visible = false

func SetCardStats(Stats : CardStats, Options : Array[CardOption]) -> void:
	CStats = Stats
	Cost = Stats.Energy
	if Stats.SelectedOption !=  null:
		$VBoxContainer/CardName.text = Stats.SelectedOption.OptionName + " " + Stats.CardName
		Cost += Stats.SelectedOption.EnergyAdd
	else:
		$VBoxContainer/CardName.text = Stats.CardName
	$VBoxContainer/CardIcon.texture = Stats.Icon
	$CardCost.text = var_to_str(Stats.Energy)
	$VBoxContainer/CardDesc.text = Stats.CardDescription
	
	$CardCost.text = var_to_str(Cost)
	for g in Stats.Options:
		var OptionBut = Button.new()
		OptionBut.text = g.OptionName
		$PanelContainer/HBoxContainer.add_child(OptionBut)
		OptionBut.connect("pressed", OnOptionSelected.bind(g))
	for g in Options:
		var OptionBut = Button.new()
		OptionBut.text = g.OptionName
		$PanelContainer/HBoxContainer.add_child(OptionBut)
		OptionBut.connect("pressed", OnOptionSelected.bind(g))

func OnButtonPressed() -> void:
	if ($PanelContainer/HBoxContainer.get_child_count() > 0 and CStats.SelectedOption == null):
		if ($PanelContainer/HBoxContainer.get_child_count() == 1):
			OnCardPressed.emit(self, CStats.Options[0])
			return
		$PanelContainer.visible = true
	else:
		OnCardPressed.emit(self, null)

func OnOptionSelected(Option : CardOption) -> void:
	#var but = get_viewport().gui_get_focus_owner() as Button
	#Option = but.text
	$PanelContainer.visible = false
	OnCardPressed.emit(self, Option)

func GetCost() -> float:
	#if (CStats.SelectedOption != null):
		#return Cost + CStats.SelectedOption.EnergyAdd
	return Cost
