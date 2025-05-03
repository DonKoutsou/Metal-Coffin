extends Control

class_name CardOffensiveAnimation

signal AnimationFinished

@export var CardScene : PackedScene
@export var DamageFloater : PackedScene
@export var ShipViz : PackedScene
@export var AtackVisual : PackedScene
@export var DefVisual : PackedScene
@export var ShieldVisual : PackedScene
@export var BuffVisual : PackedScene
@export_group("Event Handlers")
@export var UIEventH : UIEventHandler
#var LinePos : float = 0

#var DrawPositions : Array
var DrawPositions2 : Dictionary

var DrawnLine : bool = false

var AtC : Card
var DefC : Card
var IcPos : Vector2
var Targets : Array[Control]
#var Ic2Pos : Vector2
var fr : bool

var BuffText : String
#func _ready() -> void:
	#set_physics_process(false)
	#set_physics_process(true)
	#DoOffensive(OffensiveCardStats.new(), true, BattleShipStats.new(), [BattleShipStats.new()], false)

func DoOffensive(AtackCard : OffensiveCardStats, HasDef : bool, OriginShip : BattleShipStats, TargetShips : Array[Control], FriendShip : bool) -> void:
	fr = FriendShip
	#Ic = ShipViz.instantiate() as CardFightShipViz
	#Ic.SetStatsAnimation(OriginShip, !FriendShip)
	#$HBoxContainer.add_child(Ic)
	
	if (fr):
		$HBoxContainer.set_alignment(BoxContainer.ALIGNMENT_END)
		if (HasDef):
			DefC = CardScene.instantiate() as Card
			DefC.Dissable()
			#var Opts2 : Array[CardOption] = []
			DefC.SetCardStats(AtackCard.GetCounter())
			$HBoxContainer.add_child(DefC)
			DefC.size_flags_horizontal = Control.SIZE_EXPAND
			DefC.show_behind_parent = true
			DefC.modulate = Color(1,1,1,0)
			
		Targets.append_array(TargetShips)
		AtC = CardScene.instantiate() as Card
		AtC.Dissable()
		#var Opts : Array[CardOption] = []
		AtC.SetCardStats(AtackCard)
		$HBoxContainer.add_child(AtC)
		AtC.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		AtC.show_behind_parent = true
		
		AtC.modulate = Color(1,1,1,0)
		
		var tw = create_tween()
		tw.tween_property(AtC, "modulate", Color(1,1,1,1), 0.2)
		await tw.finished
		
		if (HasDef):
			var tw2 = create_tween()
			tw2.tween_property(DefC, "modulate", Color(1,1,1,1), 0.2)
			#await tw2.finished
	else:
		$HBoxContainer.set_alignment(BoxContainer.ALIGNMENT_BEGIN)
		Targets.append_array(TargetShips)
		AtC = CardScene.instantiate() as Card
		AtC.Dissable()
		#var Opts : Array[CardOption] = []
		AtC.SetCardStats(AtackCard)
		$HBoxContainer.add_child(AtC)
		AtC.size_flags_horizontal = Control.SIZE_EXPAND
		AtC.show_behind_parent = true
		AtC.modulate = Color(1,1,1,0)
		var tw = create_tween()
		tw.tween_property(AtC, "modulate", Color(1,1,1,1), 0.2)
		await tw.finished
		if (HasDef):
			DefC = CardScene.instantiate() as Card
			DefC.Dissable()
			#var Opts2 : Array[CardOption] = []
			DefC.SetCardStats(AtackCard.GetCounter())
			$HBoxContainer.add_child(DefC)
			DefC.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			DefC.show_behind_parent = true
			DefC.modulate = Color(1,1,1,0)
			var tw2 = create_tween()
			tw2.tween_property(DefC, "modulate", Color(1,1,1,1), 0.2)
			#await tw2.finished
		
	#var ShipPlemenent = VBoxContainer.new()
	#$HBoxContainer.add_child(ShipPlemenent)
	#ShipPlemenent.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	for g in Targets.size():
		
		var Target
		if (DefC != null):
			Target = DefC
		else :
			Target = Targets[g]
		
		call_deferred("SpawnVisual", Target, roundi(OriginShip.GetFirePower() * AtackCard.GetDamage()))

		#var tw = create_tween()
		#tw.tween_method(MoveLine, 0.0, 1.0, 1.0)
		##tw.tween_property(self, DrawPositions2[g], 1, 1)
		#tw.tween_callback(TweenEnded.bind(roundi(OriginShip.FirePower * AtackCard.GetDamage())))

func SpawnVisual(Target : Control, Damage : float) -> void:
	await wait (0.15)
	
	#var tw = create_tween()
	#tw.set_ease(Tween.EASE_IN)
	#tw.set_trans(Tween.TRANS_QUAD)
	#tw.tween_property(AtC, "scale", Vector2.ZERO, 0.5)
	AtC.KillCard(0.5, false)
	
	var Visual = AtackVisual.instantiate() as MissileViz
	Visual.Target = Target
	Visual.SpawnPos = AtC.global_position + (AtC.size / 2)
	add_child(Visual)
	
	
	
	Visual.connect("Reached", TweenEnded.bind(Damage))

func SpawnShieldVisual(Target : Control) -> void:
	await wait (0.15)
	
	#var tw = create_tween()
	#tw.set_ease(Tween.EASE_IN)
	#tw.set_trans(Tween.TRANS_QUAD)
	#tw.tween_property(DefC, "scale", Vector2.ZERO, 0.5)
	DefC.KillCard(0.5, false)
	
	var Visual = ShieldVisual.instantiate() as MissileViz
	Visual.Target = Target
	Visual.SpawnPos = DefC.global_position + (DefC.size / 2)
	add_child(Visual)

	Visual.connect("Reached", ShieldTweenEnded.bind(Target))

func SpawnUpVisual(Target : Control) -> void:
	await wait (0.4)
	
	#var tw = create_tween()
	#tw.set_ease(Tween.EASE_IN)
	#tw.set_trans(Tween.TRANS_QUAD)
	#tw.tween_property(DefC, "scale", Vector2.ZERO, 0.5)
	DefC.KillCard(0.5, false)
	
	var Visual = BuffVisual.instantiate() as MissileViz
	Visual.Target = Target
	Visual.SpawnPos = DefC.global_position + (DefC.size / 2)
	add_child(Visual)

	Visual.connect("Reached", BuffTweenEnded.bind(Target))

func wait(secs : float) -> Signal:
	return get_tree().create_timer(secs).timeout

var LineToMove = 0
func MoveLine(Val : float) -> void:
	DrawPositions2[LineToMove] = Val
	LineToMove += 1
	if (LineToMove > DrawPositions2.size() - 1):
		LineToMove = 0

func TweenEnded(Damage : float) -> void:
	if (DefC == null):
		for g in Targets:
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
		DefC.KillCard(0.5, false)
		
		var ShieldEff = DefVisual.instantiate() as BurstParticleGroup2D
		add_child(ShieldEff)
		ShieldEff.global_position = (DefC.global_position + (DefC.size / 2))
		ShieldEff.burst()

func ShieldTweenEnded(target : Control) -> void:
	var d = DamageFloater.instantiate()
	d.text = BuffText
	d.modulate = Color(1,1,1,1)
	add_child(d)
	d.global_position = (target.global_position + (target.size / 2)) - d.size / 2
	d.connect("Ended", AnimEnded)

func BuffTweenEnded(target : Control) -> void:
	var d = DamageFloater.instantiate()
	d.text = BuffText
	d.modulate = Color(1,1,1,1)
	add_child(d)
	d.global_position = (target.global_position + (target.size / 2)) - d.size / 2
	d.connect("Ended", AnimEnded)

func DoDeffensive(DefCard : CardStats, TargetShips : Array[Control], _FriendShip : bool) -> void:

	#var Opts : Array[CardOption] = []
	DefC = CardScene.instantiate() as Card
	DefC.Dissable()
	DefC.SetCardStats(DefCard)
	$HBoxContainer.add_child(DefC)
	#DefC.size_flags_horizontal = Control.SIZE_EXPAND
	DefC.show_behind_parent = true
	DefC.modulate = Color(1,1,1,0)

	var tw2 = create_tween()
	tw2.tween_property(DefC, "modulate", Color(1,1,1,1), 0.4)
	#await tw2.finished
	
	if (DefCard.Buffs):
		BuffText = "Firepower\nBuffed"
		for g in TargetShips:
			call_deferred("SpawnUpVisual", g)
	else: if (DefCard.SpeedBuffs):
		BuffText = "Speed\nBuffed"
		for g in TargetShips:
			call_deferred("SpawnUpVisual", g)
	else: if (DefCard.Shield):
		BuffText = "Shield\nAdded"
		for g in TargetShips:
			call_deferred("SpawnShieldVisual", g)
	
	else : if (DefCard.FireExt):
		BuffText = "Fire\nExtinguished"
		for g in TargetShips:
			call_deferred("SpawnShieldVisual", g)
	
		#var d = DamageFloater.instantiate()
		#if (DefCard.CardName == "Extinguish fires"):
			#d.text = "Fire Extinguished"
		#else : if (DefCard.CardName == "Shield Overcharge" or DefCard.CardName == "Shield Overcharge Team"):
			#d.text = "Shield Added"
		#d.modulate = Color(1,1,1,1)
		#g.add_child(d)
		##d.global_position = (DefC.global_position + (DefC.size / 2)) - d.size / 2
		#d.connect("Ended", AnimEnded)
	
	

func DoFire(OriginShip : BattleShipStats, FriendShip : bool) -> void:
	var Ship = ShipViz.instantiate() as CardFightShipViz
	Ship.disabled = true
	Ship.SetStatsAnimation(OriginShip, FriendShip)
	$HBoxContainer.add_child(Ship)
	
	Ship.ToggleFire(true)
	var d = DamageFloater.instantiate()
	d.text = "Fire Damage - 10"
	d.modulate = Color(1,1,1,1)
	add_child(d)
	d.global_position = (Ship.global_position + (Ship.size / 2)) - d.size / 2
	d.connect("Ended", AnimEnded)

var Finished : bool = false

func AnimEnded() -> void:
	if (Finished):
		return
	Finished = true
	AnimationFinished.emit()


#func _physics_process(_delta: float) -> void:
	#queue_redraw()
#
#func _draw() -> void:
	#if (!DrawnLine):
		#return
	#draw_set_transform(-global_position)
	#for g in Ic2.size():
		#var pos1 = AtC.global_position
		#pos1.x += AtC.size.x / 2
		#pos1.y += AtC.size.y / 2
		#var pos2 
		#if (DefC != null):
			#pos2 = DefC.global_position
			#pos2.x += DefC.size.x / 2
			#pos2.y = pos1.y
		#else :
			#pos2 = Ic2[g].global_position
			#pos2.x += Ic2[g].size.x / 2
			#pos2.y += Ic2[g].size.y / 2
			##pos2.y = pos1.y
			
		#draw_line(pos1, lerp(pos1, pos2, DrawPositions2[g]), Color(1,0,0), 8)
