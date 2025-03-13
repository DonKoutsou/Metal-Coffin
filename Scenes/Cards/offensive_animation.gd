extends Control

class_name CardOffensiveAnimation

signal AnimationFinished

@export var CardScene : PackedScene
@export var DamageFloater : PackedScene
@export var ShipViz : PackedScene
@export_group("Event Handlers")
@export var UIEventH : UIEventHandler
#var LinePos : float = 0

#var DrawPositions : Array
var DrawPositions2 : Dictionary

var DrawnLine : bool = false

var AtC
var DefC
var Ic
var Ic2 : Array
var fr : bool
func _ready() -> void:
	set_physics_process(DrawnLine)
	#set_physics_process(true)
	#DoOffensive(OffensiveCardStats.new(), false, BattleShipStats.new(), [BattleShipStats.new(), BattleShipStats.new()], false)

func DoOffensive(AtackCard : OffensiveCardStats, HasDef : bool, OriginShip : BattleShipStats, TargetShips : Array[BattleShipStats], FriendShip : bool) -> void:
	fr = FriendShip
	Ic = ShipViz.instantiate() as CardFightShipViz
	Ic.SetStatsAnimation(OriginShip, !FriendShip)
	$HBoxContainer.add_child(Ic)

	AtC = CardScene.instantiate() as Card
	AtC.Dissable()
	var Opts : Array[CardOption] = []
	AtC.SetCardStats(AtackCard, Opts)
	$HBoxContainer.add_child(AtC)
	AtC.size_flags_horizontal = Control.SIZE_EXPAND
	AtC.show_behind_parent = true
	
	if (HasDef):
		DefC = CardScene.instantiate() as Card
		DefC.Dissable()
		var Opts2 : Array[CardOption] = []
		DefC.SetCardStats(AtackCard.GetCounter(), Opts2)
		$HBoxContainer.add_child(DefC)
		DefC.size_flags_horizontal = Control.SIZE_EXPAND
		DefC.show_behind_parent = true
	
	var ShipPlemenent = VBoxContainer.new()
	$HBoxContainer.add_child(ShipPlemenent)
	ShipPlemenent.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	for g in TargetShips.size():
		var t = ShipViz.instantiate() as CardFightShipViz
		t.SetStatsAnimation(TargetShips[g], FriendShip)
		ShipPlemenent.add_child(t)
		Ic2.append(t)
		
		DrawPositions2[g] = 0.0
		
		var tw = create_tween()
		tw.tween_method(MoveLine, 0.0, 1.0, 1.0)
		#tw.tween_property(self, DrawPositions2[g], 1, 1)
		tw.tween_callback(TweenEnded.bind(roundi(OriginShip.FirePower * AtackCard.GetDamage())))

var LineToMove = 0
func MoveLine(Val : float) -> void:
	DrawPositions2[LineToMove] = Val
	LineToMove += 1
	if (LineToMove > DrawPositions2.size() - 1):
		LineToMove = 0

func TweenEnded(Damage : float) -> void:
	if (DefC == null):
		
		for g in Ic2:
			var d = DamageFloater.instantiate()
			d.modulate = Color(1,0,0,1)
			d.text = var_to_str(Damage)
			add_child(d)
			d.global_position = (g.global_position + (g.size / 2)) - d.size / 2.
			d.connect("Ended", AnimEnded)
		if (fr):
			UIEventH.OnControlledShipDamaged(Damage)
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
	DefC.Dissable()
	DefC.SetCardStats(DefCard, Opts)
	$HBoxContainer.add_child(DefC)
	DefC.size_flags_horizontal = Control.SIZE_EXPAND
	DefC.show_behind_parent = true
	
	
	var d = DamageFloater.instantiate()
	if (DefCard.CardName == "Extinguish fires"):
		d.text = "Fire Extinguished"
	else : if (DefCard.CardName == "Shield Overcharge"):
		d.text = "Shield Added"
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
	draw_set_transform(-global_position)
	for g in Ic2.size():
		var pos1 = AtC.global_position
		pos1.x += AtC.size.x / 2
		pos1.y += AtC.size.y / 2
		var pos2 
		if (DefC != null):
			pos2 = DefC.global_position
			pos2.x += DefC.size.x / 2
			pos2.y = pos1.y
		else :
			pos2 = Ic2[g].global_position
			pos2.x += Ic2[g].size.x / 2
			pos2.y += Ic2[g].size.y / 2
			#pos2.y = pos1.y
			
		draw_line(pos1, lerp(pos1, pos2, DrawPositions2[g]), Color(1,0,0), 8)
