extends Control

class_name CardOffensiveAnimation

signal AnimationFinished

@export var CardScene : PackedScene
@export var DamageFloater : PackedScene
@export var ShipViz : PackedScene

var LinePos : float = 0

var DrawnLine : bool = false

var AtC
var DefC
var Ic
var Ic2

func _ready() -> void:
	set_physics_process(DrawnLine)

func DoOffensive(AtackCard : OffensiveCardStats, HasDef : bool, OriginShip : BattleShipStats, TargetShip : BattleShipStats, FriendShip : bool) -> void:
	#DrawnLine = true
	Ic = ShipViz.instantiate() as CardFightShipViz
	Ic.SetStatsAnimation(OriginShip, !FriendShip)
	$HBoxContainer.add_child(Ic)

	AtC = CardScene.instantiate() as Card
	var Opts : Array[CardOption] = []
	AtC.SetCardStats(AtackCard, Opts)
	$HBoxContainer.add_child(AtC)
	AtC.size_flags_horizontal = Control.SIZE_EXPAND
	AtC.show_behind_parent = true
	
	if (HasDef):
		DefC = CardScene.instantiate() as Card
		var Opts2 : Array[CardOption] = []
		DefC.SetCardStats(AtackCard.GetCounter(), Opts2)
		$HBoxContainer.add_child(DefC)
		DefC.size_flags_horizontal = Control.SIZE_EXPAND
		DefC.show_behind_parent = true
	
	Ic2 = ShipViz.instantiate() as CardFightShipViz
	Ic2.SetStatsAnimation(TargetShip, FriendShip)
	$HBoxContainer.add_child(Ic2)
	var tw = create_tween()
	tw.tween_property(self, "LinePos", 1, 1)
	tw.tween_callback(TweenEnded.bind(roundi(OriginShip.FirePower * AtackCard.GetDamage())))
	
func TweenEnded(Damage : float) -> void:
	if (DefC == null):
		var d = DamageFloater.instantiate()
		d.modulate = Color(1,0,0,1)
		d.text = var_to_str(Damage)
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

func DoDeffensive(DefCard : CardStats, OriginShip : BattleShipStats, FriendShip : bool) -> void:
	Ic = ShipViz.instantiate() as CardFightShipViz
	Ic.SetStatsAnimation(OriginShip, !FriendShip)
	$HBoxContainer.add_child(Ic)
	var Opts : Array[CardOption] = []
	DefC = CardScene.instantiate() as Card
	DefC.SetCardStats(DefCard, Opts)
	$HBoxContainer.add_child(DefC)
	DefC.size_flags_horizontal = Control.SIZE_EXPAND
	DefC.show_behind_parent = true
	
	var d = DamageFloater.instantiate()
	d.text = "Fire Extinguished"
	d.modulate = Color(1,1,1,1)
	add_child(d)
	d.global_position = (DefC.global_position + (DefC.size / 2)) - d.size / 2
	d.connect("Ended", AnimEnded)

func DoFire(OriginShip : BattleShipStats, FriendShip : bool) -> void:
	Ic = ShipViz.instantiate() as CardFightShipViz
	Ic.SetStatsAnimation(OriginShip, !FriendShip)
	$HBoxContainer.add_child(Ic)
	
	Ic.ToggleFire(true)
	var d = DamageFloater.instantiate()
	d.text = "Fire Damage - 10"
	d.modulate = Color(1,1,1,1)
	add_child(d)
	d.global_position = (Ic.global_position + (Ic.size / 2)) - d.size / 2
	d.connect("Ended", AnimEnded)
	
func AnimEnded() -> void:
	AnimationFinished.emit()
	queue_free()

func _physics_process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if (!DrawnLine):
		return
	var pos1 = AtC.position
	pos1.x += (AtC.size.x / 2)
	var pos2 
	if (DefC != null):
		pos2 = DefC.position
		pos2.x += (DefC.size.x / 2)
		pos2.y = pos1.y
	else :
		pos2 = Ic2.position
		pos2.x += (Ic2.size.x / 2)
		pos2.y = pos1.y
	draw_line(pos1, lerp(pos1, pos2, LinePos), Color(1,0,0,1), 8)
