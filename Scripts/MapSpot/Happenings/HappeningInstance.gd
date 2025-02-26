extends PanelContainer

class_name HappeningInstance

#@export var TestHappening : Happening

var Hp : Happening

var SelectedOption : int

signal HappeningFinished

signal ResponseReceived

signal NextDiag

var HappeningInstigator : MapShip

func _ready() -> void:
	set_physics_process(false)
	$VBoxContainer/NextDiag.visible = false
	$VBoxContainer/ProgressBar.visible = false
	#PresentHappening(TestHappening)
	#PresentHappening(load("res://Resources/Happenings/TestHappening.tres"))

func PresentHappening(Hap : Happening):
	SimulationManager.GetInstance().TogglePause(true)
	Hp = Hap
	set_physics_process(true)
	#$VBoxContainer/NextDiag.visible = true
	#$VBoxContainer/HBoxContainer.visible = false
	
	for Stage in Hap.Stages:
		$VBoxContainer/Label.text = Hap.HappeningName
		for z in Stage.HappeningTexts.size():
			var Last = Stage.HappeningTexts.size() ==  z + 1
			
			var text = Stage.HappeningTexts[z]
			
			$VBoxContainer/Label2.text = text
			#$Timer.start()
			if (Last and Stage.Options.size() > 0):
				break
				
			$VBoxContainer/NextDiag.visible = true
			$VBoxContainer/HBoxContainer.visible = false
			
			await NextDiag
			
			$VBoxContainer/NextDiag.visible = false
			$VBoxContainer/HBoxContainer.visible = true
		
		if (Stage.Options.size() > 0):
			var OptionAmm = Stage.Options.size()
			for f in $VBoxContainer/HBoxContainer.get_child_count():
				var but = $VBoxContainer/HBoxContainer.get_child(f) as Button
				if (f >= OptionAmm):
					but.visible = false
					continue
				but.text = Stage.Options[f].OptionName
				if (Stage.Options[f] is Drone_Happening_Option):
					var hasspave = HappeningInstigator.GetDroneDock().HasSpace()
					but.disabled = !hasspave
					if (!hasspave):
						but.text += " No space in drone dock"
					var Dronehap = Stage.Options[f] as Drone_Happening_Option
					but.icon = Dronehap.Cpt.CaptainPortrait
		
			await ResponseReceived
			
			$VBoxContainer/Label2.text = Stage.Options[SelectedOption].OptionResault()
			
			$Timer.start()
			set_physics_process(true)
			$VBoxContainer/ProgressBar.visible = true
			$VBoxContainer/HBoxContainer.visible = false
			
			await $Timer.timeout
			
			$VBoxContainer/ProgressBar.visible = false
			$VBoxContainer/HBoxContainer.visible = true
			
			if (Stage.Options[SelectedOption].FinishDiag):
				HappeningFinished.emit()
				#Hp.Options[SelectedOption].OptionOutCome(HappeningInstigator)
				queue_free()
				SimulationManager.GetInstance().TogglePause(false)
				
			Stage.Options[SelectedOption].OptionOutCome(HappeningInstigator)
	set_physics_process(false)
	
	#var OptionAmm = Hap.GetOptionsCount()
	#for g in $VBoxContainer/HBoxContainer.get_child_count():
		#var but = $VBoxContainer/HBoxContainer.get_child(g) as Button
		#if (g >= OptionAmm):
			#but.visible = false
			#continue
		#but.text = Hap.Options[g].OptionName
		#if (Hap.Options[g] is Drone_Happening_Option):
			#var hasspave = HappeningInstigator.GetDroneDock().HasSpace()
			#but.disabled = !hasspave
			#if (!hasspave):
				#but.text += " No space in drone dock"
			#var Dronehap = Hap.Options[g] as Drone_Happening_Option
			#but.icon = Dronehap.Cpt.CaptainPortrait
			

func _on_option_1_pressed() -> void:
	#$VBoxContainer/Label2.text = Hp.Options[0].OptionResault()
	#OnActionSelected()
	SelectedOption = 0
	ResponseReceived.emit()
func _on_option_2_pressed() -> void:
	#$VBoxContainer/Label2.text = Hp.Options[1].OptionResault()
	SelectedOption = 1
	ResponseReceived.emit()
func _on_option_3_pressed() -> void:
	#$VBoxContainer/Label2.text = Hp.Options[2].OptionResault()
	SelectedOption = 2
	ResponseReceived.emit()
func _on_option_4_pressed() -> void:
	#$VBoxContainer/Label2.text = Hp.Options[3].OptionResault()
	#OnActionSelected()
	SelectedOption = 3
	ResponseReceived.emit()
func OnActionSelected():
	$VBoxContainer/ProgressBar.visible = true
	$VBoxContainer/HBoxContainer.visible = false
	$Timer.start()
	set_physics_process(true)
	
	await $Timer.timeout
	
	HappeningFinished.emit()
	Hp.Options[SelectedOption].OptionOutCome(HappeningInstigator)
	queue_free()
	SimulationManager.GetInstance().TogglePause(false)
	
func _physics_process(_delta: float) -> void:
	$VBoxContainer/ProgressBar.value = $Timer.time_left


func _on_next_diag_pressed() -> void:
	NextDiag.emit()
