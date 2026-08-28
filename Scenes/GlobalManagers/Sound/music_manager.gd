extends Node

class_name MusicManager

@export var AmbientMusic : Array[AudioStream]
@export var FightMusic : AudioStream

var Stream : AudioStreamPlayer
var FightStream : AudioStreamPlayer

static var Instance : MusicManager

static func GetInstance() -> MusicManager:
	return Instance

func _ready() -> void:
	Instance = self
	await get_tree().create_timer(2).timeout
	Stream = AudioStreamPlayer.new()
	Stream.volume_db = -6
	Stream.stream = AmbientMusic.pick_random()
	Stream.finished.connect(OnMusicFinished)
	Stream.bus = "Music"
	add_child(Stream)
	
	FightStream = AudioStreamPlayer.new()
	FightStream.volume_db = -6
	FightStream.stream = FightMusic
	FightStream.finished.connect(OnFightMusicFinished)
	FightStream.bus = "Music"
	add_child(FightStream)
	
	Stream.play()

func SwitchMusic(t : bool) -> void:
	if (t):
		FightStream.volume_db = -64
		var FightMusicTween : Tween = create_tween()
		FightMusicTween.tween_property(FightStream, "volume_db", -6, 2)
		FightStream.play()
		
		var AmbientMusicTween : Tween = create_tween()
		AmbientMusicTween.tween_property(Stream, "volume_db", -64, 2)
		await AmbientMusicTween.finished
		Stream.stop()
	else:
		var AmbientMusicTween : Tween = create_tween()
		AmbientMusicTween.tween_property(Stream, "volume_db", -6, 2)
		Stream.play()
		
		var FightMusicTween : Tween = create_tween()
		FightMusicTween.tween_property(FightStream, "volume_db", -64, 2)
		await FightMusicTween.finished
		FightStream.stop()

func OnMusicFinished() -> void:
	if (Stream.stream == null):
		Stream.stream = AmbientMusic.pick_random()
		Stream.play()
	else:
		Stream.stream = null
		Helper.CallLater(OnMusicFinished, 90)
		
func OnFightMusicFinished() -> void:
	FightStream.play()

func wait(secs : float) -> Signal:
	return get_tree().create_timer(secs).timeout
