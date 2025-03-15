extends PanelContainer

class_name HappeningInstance

#@export var TestHappening : Happening
@export var OptionParent : Control
@export var HappeningTitle : Label
@export var HappeningText : Label
@export var HappeningBackgroundTexture : TextureRect
@export var ProgBar : ProgressBar
@export var NextDiagButton : Button
@export var TextFloater : PackedScene


var SelectedOption : int

var CurrentBranch : Array[HappeningStage]
var CurrentStage : int = 0

signal HappeningFinished

signal ResponseReceived

signal NextDiag

var HappeningInstigator : MapShip

func _ready() -> void:
	set_physics_process(false)
	NextDiagButton.visible = false
	ProgBar.visible = false
	

func PresentHappening(Hap : Happening):
	SimulationManager.GetInstance().TogglePause(true)

	set_physics_process(true)
	
	HappeningTitle.text = Hap.HappeningName
	HappeningBackgroundTexture.texture = Hap.HappeningBg
	
	CurrentBranch = Hap.Stages
	
	call_deferred("NextStage")
	
	#set_physics_process(false)

func NextStage() -> void:
	var Stage = CurrentBranch[CurrentStage]
	CurrentStage += 1
	for z in Stage.HappeningTexts.size():
		var Last = Stage.HappeningTexts.size() ==  z + 1
		
		var text = Stage.HappeningTexts[z]
		
		HappeningText.text = text
		
		if (Last and Stage.Options.size() > 0):
			break
			
		NextDiagButton.visible = true
		OptionParent.visible = false
		
		await NextDiag
		
		NextDiagButton.visible = false
		OptionParent.visible = true
	
	if (Stage.Options.size() > 0):
		var OptionAmm = Stage.Options.size()
		for f in OptionParent.get_child_count():
			var but = OptionParent.get_child(f) as Button
			if (f >= OptionAmm):
				but.visible = false
				continue
			var Opt = Stage.Options[f] as Happening_Option
			but.text = Opt.OptionName
			if (Opt.WorldviewCheck != WorldView.WorldViews.NONE):
				var Checks = WorldView.WorldViews.keys()[Opt.WorldviewCheck].split("_")
				var CurrentCheck
				if (Opt.CheckPossetive):
					CurrentCheck = Checks[1]
				else:
					CurrentCheck = Checks[0]
				but.text += "\nWorldView check : {0}".format([CurrentCheck])
			#if (Stage.Options[f] is Drone_Happening_Option):
				##var hasspave = HappeningInstigator.GetDroneDock().HasSpace()
				##but.disabled = !hasspave
				##if (!hasspave):
					##but.text += " No space in drone dock"
				#var Dronehap = Stage.Options[f] as Drone_Happening_Option
				#but.icon = Dronehap.Cpt.CaptainPortrait
		
		await ResponseReceived
		
		var Option = Stage.Options[SelectedOption] as Happening_Option
		
		var Check = Option.Check()

		HappeningText.text = Stage.Options[SelectedOption].OptionResault()
		
		if (Option.WorldviewCheck != WorldView.WorldViews.NONE):
			var CheckResault = TextFloater.instantiate() as Floater
			if (Check):
				CheckResault.SetColor(true)
				CheckResault.text = "WorldView Check Successfull"
			else:
				CheckResault.SetColor(false)
				CheckResault.text = "WorldView Check Failed"
			add_child(CheckResault)
		$Timer.start()
		set_physics_process(true)
		ProgBar.visible = true
		OptionParent.visible = false
		
		await $Timer.timeout
		
		ProgBar.visible = false
		OptionParent.visible = true
		
		Stage.Options[SelectedOption].OptionOutCome(HappeningInstigator)
		
		if (Stage.Options[SelectedOption].FinishDiag):
			HappeningFinished.emit()
			queue_free()
		
		else:
			var Possiblebranch
			if (!Check):
				Possiblebranch = Option.WorldViewCheckFailBranch
			else:
				Possiblebranch = Option.BranchContinuation
			
			if (Possiblebranch != null):
				CurrentBranch = Possiblebranch
				CurrentStage = 0
	
	if (CurrentBranch.size() == CurrentStage):
		HappeningFinished.emit()
		queue_free()
	else:
		call_deferred("NextStage")
		
	
func _on_option_1_pressed() -> void:
	SelectedOption = 0
	ResponseReceived.emit()
func _on_option_2_pressed() -> void:
	
	SelectedOption = 1
	ResponseReceived.emit()
func _on_option_3_pressed() -> void:
	
	SelectedOption = 2
	ResponseReceived.emit()
func _on_option_4_pressed() -> void:
	
	SelectedOption = 3
	ResponseReceived.emit()
	
#func OnActionSelected():
	#ProgBar.visible = true
	#OptionParent.visible = false
	#$Timer.start()
	#set_physics_process(true)
	#
	#await $Timer.timeout
	#
	#HappeningFinished.emit()
	#Hp.Options[SelectedOption].OptionOutCome(HappeningInstigator)
	#queue_free()
	#SimulationManager.GetInstance().TogglePause(false)
	
func _physics_process(_delta: float) -> void:
	ProgBar.value = $Timer.time_left


func _on_next_diag_pressed() -> void:
	NextDiag.emit()
