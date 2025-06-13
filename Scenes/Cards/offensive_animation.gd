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
@export var EnergyVisual : PackedScene
@export var BuffVisual : PackedScene
@export var DeBuffVisual : PackedScene

var Fin : bool = false

var DamageReductionCard : Card


func DoAnimation(AnimationCard : CardStats, Data : Array[AnimationData],Performer : BattleShipStats, FriendShip : bool) -> void:

	var card = CardScene.instantiate() as Card
	card.Dissable(true)
	card.SetCardBattleStats(Performer, AnimationCard)
	$HBoxContainer.add_child(card)

	card.show_behind_parent = true
	card.modulate = Color(1,1,1,0)

	var DefCardTween = create_tween()
	DefCardTween.tween_property(card, "modulate", Color(1,1,1,1), 0.4)
	
	for AnimData in Data:
		var Mod = AnimData.Mod
		if (AnimData is OffensiveAnimationData):
			var DeffenceList = AnimData.DeffenceList
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
						var pos = Vector2(Viz.global_position.x + 200, Viz.global_position.y - (Viz.size.y / 2))
						DefCard.global_position = pos
					else:
						var pos = Vector2(Viz.global_position.x - 200, Viz.global_position.y - (Viz.size.y / 2))
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
				
				if (Mod is OffensiveCardModule):
					call_deferred("SpawnVisual", Viz, card, DefC, "Hit")
				else : if (Mod is RecoilDamageModule):
					call_deferred("SpawnVisual", Viz, card, DefC, "Recoil")
				
		if (AnimData is DeffensiveAnimationData):

			var TargetShips = AnimData.Targets
			
			if (Mod is BuffModule):
				var BuffText : String
				if (Mod.StatToBuff == CardModule.Stat.FIREPOWER):
					BuffText = "Firepower +"
				else : if(Mod.StatToBuff == CardModule.Stat.SPEED):
					BuffText = "Speed +"
				else : if(Mod.StatToBuff == CardModule.Stat.DEFENCE):
					BuffText = "Defence +"
				for Ship in TargetShips:
					call_deferred("SpawnUpVisual", Ship, card, BuffText)
					
			else: if (Mod is ShieldCardModule or Mod is MaxShieldCardModule):
				for Ship in TargetShips:
					call_deferred("SpawnShieldVisual", Ship, card, "Shield +")
					
			else : if (Mod is FireExtinguishModule):
				for Ship in TargetShips:
					call_deferred("SpawnShieldVisual", Ship, card, "Fire\nExtinguished")
					
			else : if (Mod is CleanseDebuffModule):
				for Ship in TargetShips:
					call_deferred("SpawnShieldVisual", Ship, card, "Debuffs\nCleansed")
					
			else : if (Mod is CauseFireModule):
				for Ship in TargetShips:
					call_deferred("SpawnUpVisual", Ship, card, "Fire")
			
			else : if (Mod is ResupplyModule or Mod is ReserveConversionModule):
				for Ship in TargetShips:
					call_deferred("SpawnEnergyVisual", Ship, card, "Energy +")

			else : if (Mod is ReserveModule or Mod is MaxReserveModule):
				for Ship in TargetShips:
					call_deferred("SpawnEnergyVisual", Ship, card, "Energy\nReserve +")
			else : if (Mod is InterceptModule):
				for Ship in TargetShips:
					call_deferred("SpawnShieldVisual", Ship, card, "Interceptor")
					
			else : if (Mod is DeBuffEnemyModule or Mod is DeBuffSelfModule):
				var BuffText : String
				if (Mod.StatToDeBuff == CardModule.Stat.FIREPOWER):
					BuffText = "Firepower -"
				else : if(Mod.StatToDeBuff == CardModule.Stat.SPEED):
					BuffText = "Speed -"
				else : if(Mod.StatToDeBuff == CardModule.Stat.DEFENCE):
					BuffText = "Defence -"
				for Ship in TargetShips:
					call_deferred("SpawnDownVisual", Ship, card, BuffText)

			else : if (Mod is StackDamageCardModule):
				call_deferred("SpawnUpDamageVisual", card, card, "Damage +")
			
		if (Data.size() > 1):
			await wait(0.2)
			
	card.KillCard(0.5, false)
	if (Data.size() == 0):
		await wait(0.2)
		AnimEnded()


func SpawnVisual(Target : Control, AtackCard : Card, DeffenceCard : Card, FloaterText : String) -> void:
	#await wait (0.15)
	
	AtackCardDestroyed.emit(AtackCard.global_position + (AtackCard.size / 2))
	var Visual = AtackVisual.instantiate() as MissileViz
	if (DeffenceCard != null):
		Visual.Target = DeffenceCard
	else:
		Visual.Target = Target
	Visual.SpawnPos = AtackCard.global_position + (AtackCard.size / 2)
	add_child(Visual)
	
	Visual.connect("Reached", TweenEnded.bind(Target , DeffenceCard, FloaterText))

func SpawnShieldVisual(Target : Control, DefCard : Card, FloaterText : String) -> void:
	#await wait (0.15)

	DeffenceCardDestroyed.emit(DefCard.global_position + (DefCard.size / 2))
	
	var Visual = ShieldVisual.instantiate() as MissileViz
	Visual.Target = Target
	Visual.SpawnPos = DefCard.global_position + (DefCard.size / 2)
	add_child(Visual)

	Visual.connect("Reached", ShieldTweenEnded.bind(Target, FloaterText))

func SpawnEnergyVisual(Target : Control, DefCard : Card, FloaterText : String) -> void:
	#await wait (0.15)

	DeffenceCardDestroyed.emit(DefCard.global_position + (DefCard.size / 2))
	
	var Visual = EnergyVisual.instantiate() as MissileViz
	Visual.Target = Target
	Visual.SpawnPos = DefCard.global_position + (DefCard.size / 2)
	add_child(Visual)

	Visual.connect("Reached", ShieldTweenEnded.bind(Target, FloaterText))

func SpawnUpVisual(Target : Control, DefCard : Card, FloaterText : String) -> void:
	#await wait (0.4)
	
	DeffenceCardDestroyed.emit(DefCard.global_position + (DefCard.size / 2))
	var Visual = BuffVisual.instantiate() as MissileViz
	Visual.Target = Target
	Visual.SpawnPos = DefCard.global_position + (DefCard.size / 2)
	add_child(Visual)

	Visual.connect("Reached", BuffTweenEnded.bind(Target, FloaterText))

func SpawnDownVisual(Target : Control, DefCard : Card, FloaterText : String) -> void:
	#await wait (0.4)
	
	DeffenceCardDestroyed.emit(DefCard.global_position + (DefCard.size / 2))
	var Visual = DeBuffVisual.instantiate() as MissileViz
	Visual.Target = Target
	Visual.SpawnPos = DefCard.global_position + (DefCard.size / 2)
	add_child(Visual)

	Visual.connect("Reached", BuffTweenEnded.bind(Target, FloaterText))

func SpawnUpDamageVisual(Target : Control, DefCard : Card, FloaterText : String) -> void:
	#await wait (0.2)
	
	DeffenceCardDestroyed.emit(DefCard.global_position + (DefCard.size / 2))
	var Visual = BuffVisual.instantiate() as MissileViz
	Visual.Target = Target
	Visual.SpawnPos = DefCard.global_position + (DefCard.size / 2)
	add_child(Visual)

	Visual.connect("Reached", BuffTweenEnded.bind(Target, FloaterText))

func wait(secs : float) -> Signal:
	return get_tree().create_timer(secs).timeout


func TweenEnded(Target : Control, DeffenceCard : Card, FloaterText : String) -> void:
	AtackConnected.emit()
	if (DeffenceCard == null):
		
		#print("Damage Floater")
		var d = DamageFloater.instantiate()
		d.modulate = Color(1,0,0,1)
		d.text = FloaterText
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

func ShieldTweenEnded(target : Control, FloaterText : String) -> void:
	DeffenceConnected.emit()
	var DFloater = DamageFloater.instantiate() as Floater
	DFloater.text = FloaterText
	DFloater.modulate = Color(1,1,1,1)
	add_child(DFloater)
	DFloater.global_position = (target.global_position + (target.size / 2)) - DFloater.size / 2
	DFloater.Ended.connect(AnimEnded)

func BuffTweenEnded(target : Control, FloaterText : String) -> void:
	DeffenceConnected.emit()
	var DFloater = DamageFloater.instantiate() as Floater
	DFloater.text = FloaterText
	DFloater.modulate = Color(1,1,1,1)
	add_child(DFloater)
	DFloater.global_position = (target.global_position + (target.size / 2)) - DFloater.size / 2
	DFloater.Ended.connect(AnimEnded)


	
func DoSelection(C : CardStats, Performer : BattleShipStats, User : Control) -> void:
	var DeffenceCard = CardScene.instantiate() as Card
	DeffenceCard.Dissable(true)
	
	DeffenceCard.SetCardBattleStats(Performer, C)
	add_child(DeffenceCard)
	
	var pos = Vector2(User.global_position.x - 200, User.global_position.y - (User.size.y / 2))
	DeffenceCard.global_position = pos

	DeffenceCard.show_behind_parent = true
	DeffenceCard.modulate = Color(1,1,1,0)

	var DefCardTween = create_tween()
	DefCardTween.tween_property(DeffenceCard, "modulate", Color(1,1,1,1), 0.3)
	
	var UpTween = create_tween()
	UpTween.set_ease(Tween.EASE_OUT)
	UpTween.set_trans(Tween.TRANS_BACK)
	UpTween.tween_property(DeffenceCard, "position", Vector2(pos.x, pos.y - 10), 0.3)
	await UpTween.finished
	
	var DownTween = create_tween()
	DownTween.set_ease(Tween.EASE_OUT)
	DownTween.set_trans(Tween.TRANS_BACK)
	DownTween.tween_property(DeffenceCard, "position", pos, 0.2)
	await DownTween.finished
	
	AnimationFinished.emit()
	Fin = true
	queue_free()

func DoDraw(User : Control) -> void:
	var DeffenceCard = CardScene.instantiate() as Card
	DeffenceCard.Dissable(true)
	
	DeffenceCard.Flip()
	add_child(DeffenceCard)
	
	var pos = Vector2(User.global_position.x - 200, User.global_position.y - (User.size.y / 2))
	DeffenceCard.global_position = pos

	DeffenceCard.show_behind_parent = true
	DeffenceCard.modulate = Color(1,1,1,0)

	var DefCardTween = create_tween()
	DefCardTween.tween_property(DeffenceCard, "modulate", Color(1,1,1,1), 0.2)
	
	var UpTween = create_tween()
	UpTween.set_ease(Tween.EASE_OUT)
	UpTween.set_trans(Tween.TRANS_BACK)
	UpTween.tween_property(DeffenceCard, "position", Vector2(pos.x, pos.y - 10), 0.3)
	await UpTween.finished
	
	var DownTween = create_tween()
	DownTween.set_ease(Tween.EASE_OUT)
	DownTween.set_trans(Tween.TRANS_BACK)
	DownTween.tween_property(DeffenceCard, "position", pos, 0.3)
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
	
