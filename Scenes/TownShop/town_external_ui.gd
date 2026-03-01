extends Control

class_name TownExternalUI

@export var Coin : TextureRect
@export var AnimPlayer : AnimationPlayer
@export var Flap : Control
@export var CoinTexture : Texture
@export var CoinPlecement : Control

@export var CoinSlideInSound :AudioStream
@export var CoinSlideSound : AudioStream

var MoneySpent : int = 0
var CoinsGot : int = 0

func _ready() -> void:
	Coin.visible = false
	UISoundMan.GetInstance().Refresh()
	#CoinsReceived(10)
	#Power = 1
	#Anim2()

func DropCoins(Amm : int) -> void:
	
	TimesToPlay = min(TimesToPlay + Amm, 6)
	if (!AnimPlayer.is_playing()):
		var Delsound = DeletableSoundGlobal.new()
		Delsound.stream = CoinSlideInSound
		Delsound.pitch_scale = randf_range(0.95, 1.05)
		Delsound.bus = "MapSounds"
		add_child(Delsound)
		Delsound.volume_db = -5
		Delsound.play()
		AnimPlayer.play("DropCoin")

func CoinsReceived(Amm : int)-> void:
	CoinsGot = min(20, CoinsGot + Amm)

func _physics_process(_delta: float) -> void:
	var offset = 0
	for g in CoinsGot:
		Helper.GetInstance().CallLater(OnCoinsGot, offset)
		offset += randf_range(0.2, 0.3)
		CoinsGot = 0

func OnCoinsGot() -> void:
	var Delsound = DeletableSoundGlobal.new()
	Delsound.stream = CoinSlideSound
	Delsound.pitch_scale = randf_range(0.95, 1.05)
	Delsound.bus = "MapSounds"
	add_child(Delsound)
	Delsound.volume_db = -5
	Delsound.play()
	
	var text = TextureRect.new()
	text.texture = CoinTexture
	text.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	text.size = Vector2(32,32)
	text.pivot_offset = Vector2(16,16)
	text.rotation_degrees = randf_range(0,360)
	CoinPlecement.add_child(text)
	var selectedx = randf_range(-25, 35)
	text.position = Vector2(selectedx, -45)
	var tw = create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_BOUNCE)
	tw.tween_property(text, "position", Vector2(selectedx, 102),randf_range(0.45, 0.55))
	#tw.finished.connect(OnCoinsGot)
	tw.finished.connect(text.queue_free)

var TimesToPlay: int = 0
var Power : float = 0
func Anim2() -> void:
	
	var mat = Flap.material as ShaderMaterial
	var v = mat.get_shader_parameter("x_rot")
	#mat.set_shader_parameter("x_rot", 2)
	var tw = create_tween()
	#tw.set_ease(Tween.EASE_IN)
	tw.set_trans(Tween.TRANS_QUAD)
	Power *= 0.95
	if (v > 0):
		tw.tween_method(SetFlapParam, v, -20 * Power, Power)
	else:
		tw.tween_method(SetFlapParam, v, 50 * Power, Power)
	if (Power > 0.001):
		tw.finished.connect(Anim2)
	else:
		mat.set_shader_parameter("x_rot", 0)
		
func SetFlapParam(value : float) -> void:
	var mat = Flap.material as ShaderMaterial
	mat.set_shader_parameter("x_rot", value)

func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	TimesToPlay -= 1
	
	if (TimesToPlay > 0):
		var Delsound = DeletableSoundGlobal.new()
		Delsound.stream = CoinSlideInSound
		Delsound.pitch_scale = randf_range(0.95, 1.05)
		Delsound.bus = "MapSounds"
		add_child(Delsound)
		Delsound.volume_db = -5
		Delsound.play()
		AnimPlayer.play("DropCoin")
