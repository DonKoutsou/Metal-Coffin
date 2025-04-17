extends Node

class_name MusicManager

@export var AmbientMusic : Array[AudioStream]

var Stream : AudioStreamPlayer

func _ready() -> void:
	Stream = AudioStreamPlayer.new()
	Stream.volume_db = -18
	Stream.stream = AmbientMusic.pick_random()
	Stream.finished.connect(OnMusicFinished)
	add_child(Stream)
	Stream.play()

func OnMusicFinished() -> void:
	if (Stream.stream == null):
		Stream.stream = AmbientMusic.pick_random()
		Stream.play()
	else:
		Stream.stream = null
		await wait(90)
	
func wait(secs : float) -> Signal:
	return get_tree().create_timer(secs).timeout
