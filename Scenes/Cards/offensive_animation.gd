extends Control

class_name CardOffensiveAnimation

signal AnimationFinished

@export var CardScene : PackedScene
@export var DamageFloater : PackedScene

var LinePos : float = 0

var AtackCard : OffensiveCardStats
var DefCard : CardStats
var OriginShip : BattleShipStats
var OriginIcon : Texture
var TargetIcon : Texture

var AtC
var DefC
var Ic
var Ic2

func _ready() -> void:
	Ic = TextureRect.new()
	Ic.texture = OriginIcon
	$HBoxContainer.add_child(Ic)
	Ic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	Ic.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Ic.rotation = -90
	
	AtC = CardScene.instantiate() as Card
	AtC.SetCardStats(AtackCard)
	$HBoxContainer.add_child(AtC)
	AtC.size_flags_horizontal = Control.SIZE_EXPAND
	AtC.show_behind_parent = true
	
	if (DefCard != null):
		DefC = CardScene.instantiate() as Card
		DefC.SetCardStats(DefCard)
		$HBoxContainer.add_child(DefC)
		DefC.size_flags_horizontal = Control.SIZE_EXPAND
		DefC.show_behind_parent = true
	
	Ic2 = TextureRect.new()
	Ic2.texture = TargetIcon
	$HBoxContainer.add_child(Ic2)
	Ic2.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	Ic2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Ic2.rotation = -90
	
	var tw = create_tween()
	tw.tween_property(self, "LinePos", 1, 1)
	tw.tween_callback(TweenEnded)
func TweenEnded() -> void:
	if (DefC == null):
		var d = DamageFloater.instantiate()
		d.modulate = Color(1,0,0,1)
		d.text = var_to_str(OriginShip.FirePower * AtackCard.Damage)
		add_child(d)
		d.global_position = (Ic2.global_position + (Ic2.size / 2)) - d.size / 2.
		d.connect("Ended", AnimEnded)
	else :
		var d = DamageFloater.instantiate()
		d.text = "Blocked"
		d.modulate = Color(1,1,1,1)
		add_child(d)
		d.global_position = (DefC.global_position + (DefC.size / 2)) - d.size / 2
		d.connect("Ended", AnimEnded)

func AnimEnded() -> void:
	AnimationFinished.emit()
	queue_free()

func _physics_process(delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	#draw_set_transform(position)
	var pos1 = AtC.position
	pos1.x += (AtC.size.x / 2)
	var pos2 
	if (DefC != null):
		pos2 = DefC.position
		pos2.x += (DefC.size.x / 2)
	else :
		pos2 = Ic2.position
		pos2.x += (Ic2.size.x / 2)
	draw_line(pos1, lerp(pos1, pos2, LinePos), Color(1,0,0,1), 8)
