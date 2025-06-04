extends Control

class_name CardOffensiveAnimation

signal AtackCardDestroyed(CardPos : Vector2)
signal DeffenceCardDestroyed(CardPos : Vector2)
signal AtackConnected
signal DeffenceConnected
signal AnimationFinished

@export var CardScene : PackedScene
@export var DamageFloater : PackedScene
@export var ShipViz : PackedScene
@export var AtackVisual : PackedScene
@export var DefVisual : PackedScene
@export var ShieldVisual : PackedScene
@export var BuffVisual : PackedScene
@export var DeBuffVisual : PackedScene

var fr : bool
var BuffText : String

var Fin : bool = false

var DamageReductionCard : Card

func DoOffensive(AtackCard : CardStats, Mod : CardModule, DeffenceList : Dictionary[BattleShipStats, Dictionary], OriginShip : BattleShipStats, FriendShip : bool) -> void:
	fr = FriendShip
	
	var AttackCard = CardScene.instantiate() as Card
	AttackCard.Dissable(true)
	

	AttackCard.SetCardBattleStats(OriginShip, AtackCard)

	$HBoxContainer.add_child(AttackCard)
	
	AttackCard.show_behind_parent = true
	AttackCard.modulate = Color(1,1,1,0)
	var tw = create_tween()
	tw.tween_property(AttackCard, "modulate", Color(1,1,1,1), 0.2)
	await tw.finished
	
	for g in DeffenceList.values().size():
			var Def = DeffenceList.values()[g]["Def"] as CardStats
			var Viz = DeffenceList.values()[g]["Viz"] as Control
			var DefC
			if (Def != null):
				
				var DefCard = CardScene.instantiate() as Card
				DefCard.Dissable(true)
				#var Opts2 : Array[CardOption] = []
				
				DefCard.SetCardBattleStats(DeffenceList.keys()[g], Def)
				add_child(DefCard)
				if (!FriendShip):
					var pos = Vector2(Viz.global_position.x, Viz.global_position.y)
					DefCard.global_position = pos
				else:
					var pos = Vector2(Viz.global_position.x, Viz.global_position.y)
					DefCard.global_position = pos
				#DefC.size_flags_horizontal = Control.SIZE_EXPAND
				DefCard.show_behind_parent = true
				DefCard.modulate = Color(1,1,1,0)
				
				var tw2 = create_tween()
				tw2.tween_property(DefCard, "modulate", Color(1,1,1,1), 0.2)
				
				var DefMod = Def.OnPerformModule
				if (DefMod is CounterCardModule):
					DefC = DefCard
				else:
					DamageReductionCard = DefCard
			
			call_deferred("SpawnVisual", Viz, AttackCard, DefC)
			await wait(0.2)
			
	AttackCard.KillCard(0.35, false)

func SpawnVisual(Target : Control, AtackCard : Card, DeffenceCard : Card) -> void:
	#await wait (0.15)
	
	AtackCardDestroyed.emit(AtackCard.global_position + (AtackCard.size / 2))
	var Visual = AtackVisual.instantiate() as MissileViz
	if (DeffenceCard != null):
		Visual.Target = DeffenceCard
	else:
		Visual.Target = Target
	Visual.SpawnPos = AtackCard.global_position + (AtackCard.size / 2)
	add_child(Visual)
	
	Visual.connect("Reached", TweenEnded.bind(Target , DeffenceCard))

func SpawnShieldVisual(Target : Control, DefCard : Card) -> void:
	await wait (0.15)

	DeffenceCardDestroyed.emit(DefCard.global_position + (DefCard.size / 2))
	
	var Visual = ShieldVisual.instantiate() as MissileViz
	Visual.Target = Target
	Visual.SpawnPos = DefCard.global_position + (DefCard.size / 2)
	add_child(Visual)

	Visual.connect("Reached", ShieldTweenEnded.bind(Target))

func SpawnUpVisual(Target : Control, DefCard : Card) -> void:
	await wait (0.4)
	
	DeffenceCardDestroyed.emit(DefCard.global_position + (DefCard.size / 2))
	var Visual = BuffVisual.instantiate() as MissileViz
	Visual.Target = Target
	Visual.SpawnPos = DefCard.global_position + (DefCard.size / 2)
	add_child(Visual)

	Visual.connect("Reached", BuffTweenEnded.bind(Target))

func SpawnDownVisual(Target : Control, DefCard : Card) -> void:
	await wait (0.4)
	
	DeffenceCardDestroyed.emit(DefCard.global_position + (DefCard.size / 2))
	var Visual = DeBuffVisual.instantiate() as MissileViz
	Visual.Target = Target
	Visual.SpawnPos = DefCard.global_position + (DefCard.size / 2)
	add_child(Visual)

	Visual.connect("Reached", BuffTweenEnded.bind(Target))

func SpawnUpDamageVisual(Target : Control, DefCard : Card) -> void:
	#await wait (0.2)
	
	DeffenceCardDestroyed.emit(DefCard.global_position + (DefCard.size / 2))
	var Visual = BuffVisual.instantiate() as MissileViz
	Visual.Target = Target
	Visual.SpawnPos = DefCard.global_position + (DefCard.size / 2)
	add_child(Visual)

	Visual.connect("Reached", BuffTweenEnded.bind(Target))

func wait(secs : float) -> Signal:
	return get_tree().create_timer(secs).timeout


func TweenEnded(Target : Control, DeffenceCard : Card) -> void:
	AtackConnected.emit()
	if (DeffenceCard == null):
		
		#print("Damage Floater")
		var d = DamageFloater.instantiate()
		d.modulate = Color(1,0,0,1)
		d.text = "Hit"
		d.connect("Ended", AnimEnded)
		add_child(d)
		d.global_position = (Target.global_position + (Target.size / 2)) - d.size / 2.
		if (DamageReductionCard != null):
			DamageReductionCard.KillCard(0.5, false)
			DeffenceCardDestroyed.emit(DamageReductionCard.global_position + (DamageReductionCard.size / 2))
		
	else :
		var d = DamageFloater.instantiate()
		d.text = "Blocked"
		d.modulate = Color(1,1,1,1)
		
		d.connect("Ended", AnimEnded)
		add_child(d)
		d.global_position = (DeffenceCard.global_position + (DeffenceCard.size / 2)) - d.size / 2
		DeffenceCard.KillCard(0.5, false)
		DeffenceCardDestroyed.emit(DeffenceCard.global_position + (DeffenceCard.size / 2))
		var ShieldEff = DefVisual.instantiate() as BurstParticleGroup2D
		add_child(ShieldEff)
		ShieldEff.global_position = (DeffenceCard.global_position + (DeffenceCard.size / 2))
		ShieldEff.burst()

func ShieldTweenEnded(target : Control) -> void:
	DeffenceConnected.emit()
	var DFloater = DamageFloater.instantiate() as Floater
	DFloater.text = BuffText
	DFloater.modulate = Color(1,1,1,1)
	add_child(DFloater)
	DFloater.global_position = (target.global_position + (target.size / 2)) - DFloater.size / 2
	DFloater.Ended.connect(AnimEnded)

func BuffTweenEnded(target : Control) -> void:
	DeffenceConnected.emit()
	var DFloater = DamageFloater.instantiate() as Floater
	DFloater.text = BuffText
	DFloater.modulate = Color(1,1,1,1)
	add_child(DFloater)
	DFloater.global_position = (target.global_position + (target.size / 2)) - DFloater.size / 2
	DFloater.Ended.connect(AnimEnded)

func DoDeffensive(DefCard : CardStats, Mod : CardModule, Performer : BattleShipStats, TargetShips : Array[Control], _FriendShip : bool) -> void:

	var DeffenceCard = CardScene.instantiate() as Card
	DeffenceCard.Dissable(true)
	DeffenceCard.SetCardBattleStats(Performer, DefCard)
	$HBoxContainer.add_child(DeffenceCard)

	DeffenceCard.show_behind_parent = true
	DeffenceCard.modulate = Color(1,1,1,0)

	var DefCardTween = create_tween()
	DefCardTween.tween_property(DeffenceCard, "modulate", Color(1,1,1,1), 0.4)

	if (Mod is BuffModule):
		if (Mod.StatToBuff == CardModule.Stat.FIREPOWER):
			BuffText = "Firepower +"
		else : if(Mod.StatToBuff == CardModule.Stat.SPEED):
			BuffText = "Speed +"
		else : if(Mod.StatToBuff == CardModule.Stat.DEFENCE):
			BuffText = "Defence +"
		for Ship in TargetShips:
			call_deferred("SpawnUpVisual", Ship, DeffenceCard)
			await wait(0.2)
	else: if (Mod is ShieldCardModule or Mod is MaxShieldCardModule):
		BuffText = "Shield +"
		for Ship in TargetShips:
			call_deferred("SpawnShieldVisual", Ship, DeffenceCard)
			await wait(0.2)
	else : if (Mod is CauseFireModule):
		BuffText = "Fire"
		for Ship in TargetShips:
			call_deferred("SpawnUpVisual", Ship, DeffenceCard)
			await wait(0.2)
	else : if (Mod is FireExtinguishModule):
		BuffText = "Fire\nExtinguished"
		for Ship in TargetShips:
			call_deferred("SpawnShieldVisual", Ship, DeffenceCard)
			await wait(0.2)
	else : if (Mod is ResupplyModule or Mod is ReserveConversionModule):
		BuffText = "Energy +"
		for Ship in TargetShips:
			call_deferred("SpawnUpVisual", Ship, DeffenceCard)
			await wait(0.2)
	else : if (Mod is ReserveModule or Mod is MaxReserveModule):
		BuffText = "Energy\nReserve +"
		for Ship in TargetShips:
			call_deferred("SpawnUpVisual", Ship, DeffenceCard)
			await wait(0.2)
	else : if (Mod is DeBuffEnemyModule or Mod is DeBuffSelfModule):
		if (Mod.StatToDeBuff == CardModule.Stat.FIREPOWER):
			BuffText = "Firepower -"
		else : if(Mod.StatToDeBuff == CardModule.Stat.SPEED):
			BuffText = "Speed -"
		else : if(Mod.StatToDeBuff == CardModule.Stat.DEFENCE):
			BuffText = "Defence -"
		for Ship in TargetShips:
			call_deferred("SpawnDownVisual", Ship, DeffenceCard)
			await wait(0.2)
	else : if (Mod is CleanseDebuffModule):
		BuffText = "Debuffs\nCleansed"
		call_deferred("SpawnShieldVisual", DeffenceCard, DeffenceCard)
		await wait(0.2)
	else : if (Mod is StackDamageCardModule):
		BuffText = "Damage +"
		call_deferred("SpawnUpDamageVisual", DeffenceCard, DeffenceCard)
		DeffenceCard.KillCard(0.5, false)
		return

	DeffenceCard.KillCard(0.5, false)
	if (TargetShips.size() == 0):
		await wait(0.2)
		AnimEnded()
	
func DoSelection(C : CardStats, Performer : BattleShipStats, User : Control) -> void:
	var DeffenceCard = CardScene.instantiate() as Card
	DeffenceCard.Dissable(true)
	
	DeffenceCard.SetCardBattleStats(Performer, C)
	add_child(DeffenceCard)
	
	var pos = Vector2(User.global_position.x, User.global_position.y)
	DeffenceCard.global_position = pos

	DeffenceCard.show_behind_parent = true
	DeffenceCard.modulate = Color(1,1,1,0)

	var DefCardTween = create_tween()
	DefCardTween.tween_property(DeffenceCard, "modulate", Color(1,1,1,1), 0.4)
	
	var UpTween = create_tween()
	UpTween.set_ease(Tween.EASE_OUT)
	UpTween.set_trans(Tween.TRANS_BACK)
	UpTween.tween_property(DeffenceCard, "position", Vector2(pos.x, pos.y + 10), 0.4)
	await UpTween.finished
	
	var DownTween = create_tween()
	DownTween.set_ease(Tween.EASE_OUT)
	DownTween.set_trans(Tween.TRANS_BACK)
	DownTween.tween_property(DeffenceCard, "position", pos, 0.4)
	await DownTween.finished
	
	AnimationFinished.emit()
	Fin = true
	queue_free()

func DoFire(OriginShip : BattleShipStats, FriendShip : bool) -> void:
	var Ship = ShipViz.instantiate() as CardFightShipViz
	Ship.disabled = true
	Ship.SetStatsAnimation(OriginShip, FriendShip)
	$HBoxContainer.add_child(Ship)
	
	Ship.ToggleFire(true)
	var d = DamageFloater.instantiate() as Floater
	d.text = "Fire Damage"
	add_child(d)
	d.global_position = (Ship.global_position + (Ship.size / 2)) - d.size / 2
	d.Ended.connect(AnimEnded)

var Finished : bool = false

func AnimEnded() -> void:
	if (Finished):
		#print("Tried to finish but already finished")
		return
	Finished = true
	Fin = true
	AnimationFinished.emit()
	queue_free()
	#print("Animation Finised Emitted")
	
