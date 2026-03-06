extends Control

class_name LoadingScreen

#@export var Labe : Label

#signal LoadingDestroyed

@export_multiline var Text : String
@export var SkipButton : Button
@export var TextLabel : Label
@export var TextPar : Control

signal IntroFinished

var Tw : Tween

func _on_skip_button_pressed() -> void:
	#Tw.kill()
	Tw.finished.emit()
	

func _ready() -> void:
	UISoundMan.GetInstance().AddSelf(SkipButton)
	SkipButton.visible = false
	$AnimationPlayer.play("Logo")
	$SubViewportContainer/SubViewport/TownBackground.set_physics_process(false)
	$SubViewportContainer/SubViewport/TownBackground.Dissable()
	TextLabel.text = Text
	Helper.Instance.CallLater(StartTextScroll, 0.5)

func StartTextScroll() -> void:
	Tw = create_tween()
	var t = TextLabel.get_line_count()
	var finalpos = Vector2(TextPar.position.x, -TextPar.size.y)
	Tw.tween_property(TextPar, "position", finalpos, t)
	await Tw.finished
	#Tw.kill()
	IntroFinished.emit()

func DissableText() -> void:
	TextPar.visible = false

func ProcessStarted(ProcessName : String) -> void:
	var l = Label.new()
	l.autowrap_mode = TextServer.AUTOWRAP_WORD
	l.text += "\n{0} {1} : Process Started...".format([Time.get_time_string_from_system(),ProcessName])
	$PanelContainer2/VBoxContainer.add_child(l)

func ProcesFinished(ProcessName : String) -> void:
	var l = Label.new()
	l.autowrap_mode = TextServer.AUTOWRAP_WORD
	l.text += "\n{0} {1} : Process Finished".format([Time.get_time_string_from_system(),ProcessName])
	$PanelContainer2/VBoxContainer.add_child(l)

func UpdateProgress(Precent : float) -> void:
	var tw = create_tween()
	tw.tween_property($ProgressBar, "value", Precent, 1)
	#$ProgressBar.value = Precent

var GoingDown : bool = true
func _physics_process(delta: float) -> void:
	if (GoingDown):
		SkipButton.modulate.a -= delta * 2
		if (SkipButton.modulate.a <= 0.5):
			GoingDown = false
	else:
		SkipButton.modulate.a += delta * 2
		if (SkipButton.modulate.a >= 1):
			GoingDown = true

func StartDest():
	SkipButton.visible = true
	$ProgressBar.visible = false
	#var t = Timer.new()
	#t.wait_time = 2
	#t.autostart = true
	#add_child(t)
	#await t.timeout
	#LoadingDestroyed.emit()
	#queue_free()
func Dest():
	return
