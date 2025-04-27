extends PanelContainer

class_name WorldViewQuestionair

@export_group("Nodes")
@export var Text : Label
@export var QuestionAnswers : HBoxContainer
@export var DiagButtons : VBoxContainer
@export var Line : Control
@export_group("Texts")
@export_multiline var IntroDialogue : Array[String]
@export var PossibleQuestions : Array[WorldviewQuestion]
@export_multiline var OutroDialogue : Array[String]
var PickedQuestions : Array[WorldviewQuestion]

var CurrentIntroDialogue : int = 0
var CurrentOutroDialogue : int = 0
var CurrentQuestion : int = 0

var ShowingOutro : bool = false

signal Ended

func Init() -> void:
	UISoundMan.GetInstance().Refresh()
	Tw = create_tween()
	Tw.set_trans(Tween.TRANS_BOUNCE)
	Tw.tween_property(Line, "amplitude", randf_range(3, 20), 1)
	for g in 4:
		var Stat = WorldView.WorldViews.values()[g + 1]
		var Picked : Array[WorldviewQuestion]
		
		while Picked.size() < 3:
			var Question = PossibleQuestions.pick_random()
			if (Question.WorldviewSkill != Stat):
				continue
			if (Picked.has(Question) or PickedQuestions.has(Question)):
				continue
			Picked.append(Question)
			
		PickedQuestions.append_array(Picked)
		
	PickedQuestions.shuffle()
	DiagButtons.visible = true
	Text.visible = true
	Text.text = IntroDialogue[CurrentIntroDialogue]
	Text.visible_ratio = 0

var d = 0.06
var Tw : Tween
func _physics_process(delta: float) -> void:
	
	Text.visible_ratio += delta
	
	d -= delta
	if (d > 0):
		return
	d = 0.06

	if (Text.visible_ratio < 1):
		$AudioStreamPlayer.pitch_scale = randf_range(0.85, 1.15)
		$AudioStreamPlayer.play()
		if (Tw.finished):
			Tw = create_tween()
			Tw.set_trans(Tween.TRANS_BOUNCE)
			Tw.tween_property(Line, "amplitude", randf_range(-60, 60), 0.2)
	else:
		#if ($VBoxContainer/Control.modulate == Color(1,1,1,0)):
			#var Tw2 = create_tween()
			#Tw2.set_ease(Tween.EASE_OUT)
			#Tw2.set_trans(Tween.TRANS_QUAD)
			#Tw2.tween_property($VBoxContainer/Control, "modulate", Color(1,1,1,1), 0.5)
			#.modulate = Color(1,1,1,1)
		Tw = create_tween()
		##Tw.set_trans(Tween.TRANS_BOUNCE)
		Tw.tween_property(Line, "amplitude", 0, 0.1)
		##$VBoxContainer/LineDrawer.amplitude = 0

var DissapearingTween : Tween

func DissText() -> void:
	DissapearingTween = create_tween()
	DissapearingTween.set_ease(Tween.EASE_OUT)
	DissapearingTween.set_trans(Tween.TRANS_QUAD)
	DissapearingTween.tween_property($VBoxContainer/Control, "modulate", Color(1,1,1,0), 0.5)
	await DissapearingTween.finished
	DissapearingTween = null
	

func NextButtonPressed() -> void:
	if (DissapearingTween != null):
		return
	await DissText()
	var Tw2 = create_tween()
	Tw2.set_ease(Tween.EASE_OUT)
	Tw2.set_trans(Tween.TRANS_QUAD)
	Tw2.tween_property($VBoxContainer/Control, "modulate", Color(1,1,1,1), 0.5)
	if (ShowingOutro):
		CurrentOutroDialogue += 1
		if (OutroDialogue.size() <= CurrentOutroDialogue):
			Ended.emit()
			$VBoxContainer.visible = false
			return
		Text.visible = true
		Text.text = OutroDialogue[CurrentOutroDialogue]
		Text.visible_ratio = 0
		return
	CurrentIntroDialogue += 1
	if (IntroDialogue.size() <= CurrentIntroDialogue):
		UpdateQuestion()
		DiagButtons.hide()
		QuestionAnswers.show()
	else:
		Text.text = IntroDialogue[CurrentIntroDialogue]
		Text.visible_ratio = 0

func SkipButton() -> void:
	if (DissapearingTween != null):
		return
	await DissText()
	var Tw2 = create_tween()
	Tw2.set_ease(Tween.EASE_OUT)
	Tw2.set_trans(Tween.TRANS_QUAD)
	Tw2.tween_property($VBoxContainer/Control, "modulate", Color(1,1,1,1), 0.5)
	if (ShowingOutro):
		Ended.emit()
		$VBoxContainer.visible = false
		return

	UpdateQuestion()
	DiagButtons.hide()
	QuestionAnswers.show()

func UpdateQuestion() -> void:
	if (DissapearingTween != null):
		return
	await DissText()
	var Tw2 = create_tween()
	Tw2.set_ease(Tween.EASE_OUT)
	Tw2.set_trans(Tween.TRANS_QUAD)
	Tw2.tween_property($VBoxContainer/Control, "modulate", Color(1,1,1,1), 0.5)
	
	if (PickedQuestions.size() <= CurrentQuestion):
		ShowingOutro = true
		DiagButtons.show()
		QuestionAnswers.hide()
		Text.visible = true
		Text.text = OutroDialogue[CurrentOutroDialogue]
		Text.visible_ratio = 0
		#Ended.emit()
		#$VBoxContainer.visible = false
		#queue_free()
		return
	Text.text = PickedQuestions[CurrentQuestion].QuestionText
	Text.visible_ratio = 0
	QuestionAnswers.get_child(0).text = PickedQuestions[CurrentQuestion].NegativeAnswer
	QuestionAnswers.get_child(1).text = PickedQuestions[CurrentQuestion].PossetiveAnswer

func Option1Pressed() -> void:
	WorldView.GetInstance().AdjustStat(PickedQuestions[CurrentQuestion].WorldviewSkill, - 10, false)
	CurrentQuestion += 1
	UpdateQuestion()
func Option2Pressed() -> void:
	WorldView.GetInstance().AdjustStat(PickedQuestions[CurrentQuestion].WorldviewSkill, 10, false)
	CurrentQuestion += 1
	UpdateQuestion()
