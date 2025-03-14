extends PanelContainer

class_name WorldViewQuestionair

@export var IntroDialogue : Array[String]
@export var PossibleQuestions : Array[WorldviewQuestion]
var PickedQuestions : Array[WorldviewQuestion]

var CurrentIntroDialogue : int = 0
var CurrentQuestion : int = 0

signal Ended

func _ready() -> void:
	for g in 4:
		var Stat = WorldView.WorldViews.values()[g + 1]
		var Picked : Array[WorldviewQuestion]
		
		while Picked.size() < 4:
			var Question = PossibleQuestions.pick_random()
			if (Question.WorldviewSkill != Stat):
				continue
			if (Picked.has(Question)):
				continue
			Picked.append(Question)
			
		PickedQuestions.append_array(Picked)
		
	PickedQuestions.shuffle()
	$VBoxContainer/Label.text = IntroDialogue[CurrentIntroDialogue]
	$VBoxContainer/Label.visible_ratio = 0
func _physics_process(delta: float) -> void:
	$VBoxContainer/Label.visible_ratio += delta

func NextButtonPressed() -> void:
	CurrentIntroDialogue += 1
	if (IntroDialogue.size() <= CurrentIntroDialogue):
		UpdateQuestion()
		$VBoxContainer/HBoxContainer2.hide()
		$VBoxContainer/HBoxContainer.show()
	else:
		$VBoxContainer/Label.text = IntroDialogue[CurrentIntroDialogue]
		$VBoxContainer/Label.visible_ratio = 0

func SkipButton() -> void:
	UpdateQuestion()
	$VBoxContainer/HBoxContainer2.hide()
	$VBoxContainer/HBoxContainer.show()

func UpdateQuestion() -> void:
	if (PickedQuestions.size() <= CurrentQuestion):
		Ended.emit()
		queue_free()
		return
	$VBoxContainer/Label.text = PickedQuestions[CurrentQuestion].QuestionText
	$VBoxContainer/Label.visible_ratio = 0
	$VBoxContainer/HBoxContainer/Button.text = PickedQuestions[CurrentQuestion].NegativeAnswer
	$VBoxContainer/HBoxContainer/Button2.text = PickedQuestions[CurrentQuestion].PossetiveAnswer

func Option1Pressed() -> void:
	WorldView.AdjustStat(PickedQuestions[CurrentQuestion].WorldviewSkill, - 10)
	CurrentQuestion += 1
	UpdateQuestion()
func Option2Pressed() -> void:
	WorldView.AdjustStat(PickedQuestions[CurrentQuestion].WorldviewSkill, 10)
	CurrentQuestion += 1
	UpdateQuestion()
