@tool
extends Control

class_name TransitionPanel

@export var DoorCloseSound : AudioStream
@export var DoorOpenSound : AudioStream
@export var PanelTexture : TextureRect
@export var Anim : AnimationPlayer

signal PanelClosed
signal PanelOpened

func Close() -> void:
	Anim.play("Close")

func Open() -> void:
	Anim.play("Open")

func _Close() -> void:
	PlaySound(DoorCloseSound)
	await Helper.GetInstance().wait(0.5)
	var CloseTw = create_tween()
	CloseTw.set_ease(Tween.EASE_OUT)
	CloseTw.set_trans(Tween.TRANS_BOUNCE)
	CloseTw.tween_property(PanelTexture, "position", Vector2.ZERO, 2)
	await CloseTw.finished
	PanelClosed.emit()
	#FullScreenToggleStarted.emit(ScreenState.HALF_SCREEN)

func _Open() -> void:
	PlaySound(DoorOpenSound)
	var OpenTw = create_tween()
	OpenTw.set_ease(Tween.EASE_IN)
	OpenTw.set_trans(Tween.TRANS_QUART)
	OpenTw.tween_property(PanelTexture, "position", Vector2(0, -PanelTexture.size.y - 40), 1.6)
	await OpenTw.finished
	PanelOpened.emit()

func PlaySound(Sound : AudioStream) -> void:
	var Delsound = DeletableSoundGlobal.new()
	Delsound.stream = Sound
	Delsound.bus = "MapSounds"
	get_parent().add_child(Delsound)
	Delsound.volume_db = -12
	Delsound.play()
