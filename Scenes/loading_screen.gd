extends CanvasLayer

class_name LoadingScreen

@export var Labe : Label

signal LoadingDestroyed

func _ready() -> void:
	$AnimationPlayer.play("Logo")

func ProcessStarted(ProcessName : String) -> void:
	#var l = Label.new()
	Labe.text += "\n{0} {1} : Process Started...".format([Time.get_time_string_from_system(),ProcessName])
	#$VBoxContainer.add_child(l)
func ProcesFinished(ProcessName : String) -> void:
	#var l = Label.new()
	Labe.text += "\n{0} {1} : Process Finished".format([Time.get_time_string_from_system(),ProcessName])
	#$VBoxContainer.add_child(l)
func UpdateProgress(Precent : float) -> void:
	var tw = create_tween()
	tw.tween_property($ProgressBar, "value", Precent, 1)
	#$ProgressBar.value = Precent

func _physics_process(_delta: float) -> void:
	Labe.visible_characters = min(Labe.text.length(), Labe.visible_characters + 1)

func StartDest():
	var t = Timer.new()
	t.wait_time = 2
	t.autostart = true
	add_child(t)
	await t.timeout
	LoadingDestroyed.emit()
	queue_free()
