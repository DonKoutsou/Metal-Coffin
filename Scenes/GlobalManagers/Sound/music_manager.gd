extends Node

class_name MusicManager

@export var player : FmodEventEmitter2D


var currentMusicTypeValue : float = 0.0 :
	set(value):
		currentMusicTypeValue = value
		player.set_parameter("Music_Type", value)

static var Instance : MusicManager

static func GetInstance() -> MusicManager:
	return Instance

func _ready() -> void:
	Instance = self
	await get_tree().create_timer(8).timeout
	player.play()

func SwitchMusic(t : bool) -> void:
	if (t):
		var tw = create_tween()
		tw.tween_property(self, "currentMusicTypeValue", 1.0, 4)
	else:
		var tw = create_tween()
		tw.tween_property(self, "currentMusicTypeValue", 0.0, 4)

func UpdateMusicVolume(newVolume : float) -> void:
	player.volume = newVolume

func GetMusicVolume() -> float:
	return player.volume
