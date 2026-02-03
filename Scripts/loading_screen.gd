extends Control

class_name LoadingScreen

#@export var Labe : Label

#signal LoadingDestroyed

@export_multiline var Text : String
@export var SkipButton : Button
@export var TextLabel : Label

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
	Tw = create_tween()
	Tw.tween_property(TextLabel, "position", Vector2(TextLabel.position.x,-TextLabel.size.y - get_viewport_rect().size.y), 4 * TextLabel.get_line_count())
	await Tw.finished
	#Tw.kill()
	IntroFinished.emit()
	#queue_free()

func DissableText() -> void:
	TextLabel.visible = false

func ProcessStarted(_ProcessName : String) -> void:
	#var l = Label.new()
	#l.text += "\n{0} {1} : Process Started...".format([Time.get_time_string_from_system(),ProcessName])
	#$VBoxContainer.add_child(l)
	pass
func ProcesFinished(_ProcessName : String) -> void:
	#var l = Label.new()
	#l.text += "\n{0} {1} : Process Finished".format([Time.get_time_string_from_system(),ProcessName])
	#$VBoxContainer.add_child(l)
	pass
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
