extends Control

class_name DialoguePlayer

@onready var label: Label = $PanelContainer2/Label

signal DialoguePlayed()

var textToShow : Array[String]

var Callback : Callable = Callable()

var CharactersShowing = 0

func _ready() -> void:
	set_physics_process(false)
	#PlayDialogue(["Dis a test tes tes  sgsesgesg eesg sge sges ges ges", " ga gawe geagg ae gea gae geag g"])
func PlayDialogue(Text : Array[String], Avatar : Texture, Name : String):
	textToShow.append_array(Text)
	$PanelContainer/TextureRect.texture = Avatar
	$PanelContainer/TextureRect.visible = Avatar != null
	$PanelContainer/Label.text = Name
	ApplyNextText()
	
func DialogueEnded():
	#$AudioStreamPlayer.stop()
	textToShow.remove_at(0)
	$Timer.start()

func SkipLine() -> void:
	CharactersShowing = 0
	textToShow.remove_at(0)
	if (textToShow.size() > 0):
		ApplyNextText()
		return 
	DialoguePlayed.emit()
	if (Callback != Callable()):
		Callback.call()
	queue_free()
	
func ApplyNextText():
	#label.text = textToShow[0]
	#label.visible_ratio = 0
	#var tw = create_tween()
	#tw.tween_property(label, "visible_ratio", 1, textToShow[0].length() / 10)
	#tw.connect("finished", DialogueEnded)
	#$AudioStreamPlayer.play()
	set_physics_process(true)

func _on_timer_timeout() -> void:
	if (textToShow.size() > 0):
		ApplyNextText()
		return 
	DialoguePlayed.emit()
	if (Callback != Callable()):
		Callback.call()
	queue_free()

var d = 0.06;

func _physics_process(delta: float) -> void:
	d -= delta
	if (d > 0):
		return
	d = 0.06
	$PanelContainer2/Label.text = textToShow[0].substr(0, CharactersShowing)
	$AudioStreamPlayer.pitch_scale = randf_range(0.85, 1.15)
	$AudioStreamPlayer.play()
	if (CharactersShowing >= textToShow[0].length()):
		DialogueEnded()
		set_physics_process(false)
		CharactersShowing = 0
		return
	CharactersShowing += 1


func _on_skip_pressed() -> void:
	DialoguePlayed.emit()
	if (Callback != Callable()):
		Callback.call()
	queue_free()


func _on_next_pressed() -> void:
	SkipLine()
