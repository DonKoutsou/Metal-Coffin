extends Control

class_name CardOffensiveAnimation

signal AtackCardDestroyed(CardPos : Vector2)
signal DeffenceCardDestroyed(CardPos : Vector2)
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

var fr : bool
var BuffText : String

func DoOffensive(AtackCard : OffensiveCardStats, DeffenceList : Dictionary[BattleShipStats, Dictionary], OriginShip : BattleShipStats, FriendShip : bool) -> void:
	fr = FriendShip
	
	var AttackCard = CardScene.instantiate() as Card
	AttackCard.Dissable()
	
	if (!FriendShip):
		$HBoxContainer.set_alignment(BoxContainer.ALIGNMENT_END)
		AttackCard.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	else:
		$HBoxContainer.set_alignment(BoxContainer.ALIGNMENT_BEGIN)
		AttackCard.size_flags_horizontal = Control.SIZE_EXPAND

	AttackCard.SetCardStats(AtackCard)

	$HBoxContainer.add_child(AttackCard)
	
	AttackCard.show_behind_parent = true
	AttackCard.modulate = Color(1,1,1,0)
	var tw = create_tween()
	tw.tween_property(AttackCard, "modulate", Color(1,1,1,1), 0.2)
	await tw.finished

	for g in DeffenceList.values().size():
			var HasDef = DeffenceList.values()[g]["HasDef"] as bool
			var Viz = DeffenceList.values()[g]["Viz"] as Control
			var DefC
			if (HasDef):
				DefC = CardScene.instantiate() as Card
				DefC.Dissable()
				#var Opts2 : Array[CardOption] = []
				DefC.SetCardStats(AtackCard.GetCounter())
				add_child(DefC)
				if (!FriendShip):
					var pos = Vector2(Viz.global_position.x + 200, Viz.global_position.y - (Viz.size.y / 2))
					DefC.global_position = pos
				else:
					var pos = Vector2(Viz.global_position.x - 200, Viz.global_position.y - (Viz.size.y / 2))
					DefC.global_position = pos
				#DefC.size_flags_horizontal = Control.SIZE_EXPAND
				DefC.show_behind_parent = true
				DefC.modulate = Color(1,1,1,0)
				
				var tw2 = create_tween()
				tw2.tween_property(DefC, "modulate", Color(1,1,1,1), 0.2)
				
			call_deferred("SpawnVisual", Viz, AttackCard, DefC, roundi(OriginShip.GetFirePower() * AtackCard.GetDamage()))
			await wait(0.2)
			
	AttackCard.KillCard(0.5, false)

func SpawnVisual(Target : Control, AtackCard : Card, DeffenceCard : Card, Damage : float) -> void:
	await wait (0.15)
	
	AtackCardDestroyed.emit(AtackCard.global_position + (AtackCard.size / 2))
	var Visual = AtackVisual.instantiate() as MissileViz
	if (DeffenceCard != null):
		Visual.Target = DeffenceCard
	else:
		Visual.Target = Target
	Visual.SpawnPos = AtackCard.global_position + (AtackCard.size / 2)
	add_child(Visual)
	
	Visual.connect("Reached", TweenEnded.bind(Target , Damage, DeffenceCard))

func SpawnShieldVisual(Target : Control, DefCard : Card) -> void:
	await wait (0.15)

	DefCard.KillCard(0.5, false)
	DeffenceCardDestroyed.emit(DefCard.global_position + (DefCard.size / 2))
	var Visual = ShieldVisual.instantiate() as MissileViz
	Visual.Target = Target
	Visual.SpawnPos = DefCard.global_position + (DefCard.size / 2)
	add_child(Visual)

	Visual.connect("Reached", ShieldTweenEnded.bind(Target))

func SpawnUpVisual(Target : Control, DefCard : Card) -> void:
	await wait (0.4)

	DefCard.KillCard(0.5, false)
	DeffenceCardDestroyed.emit(DefCard.global_position + (DefCard.size / 2))
	var Visual = BuffVisual.instantiate() as MissileViz
	Visual.Target = Target
	Visual.SpawnPos = DefCard.global_position + (DefCard.size / 2)
	add_child(Visual)

	Visual.connect("Reached", BuffTweenEnded.bind(Target))

func wait(secs : float) -> Signal:
	return get_tree().create_timer(secs).timeout


func TweenEnded(Target : Control, Damage : float, DeffenceCard : Card) -> void:
	if (DeffenceCard == null):
		var d = DamageFloater.instantiate()
		d.modulate = Color(1,0,0,1)
		d.text = var_to_str(Damage).replace(".0", "")
		add_child(d)
		d.global_position = (Target.global_position + (Target.size / 2)) - d.size / 2.
		d.connect("Ended", AnimEnded)
	
		if (!fr):
			UIEventH.OnControlledShipDamaged(Damage)
	else :
		var d = DamageFloater.instantiate()
		d.text = "Blocked"
		d.modulate = Color(1,1,1,1)
		add_child(d)
		d.global_position = (DeffenceCard.global_position + (DeffenceCard.size / 2)) - d.size / 2
		d.connect("Ended", AnimEnded)
		DeffenceCard.KillCard(0.5, false)
		DeffenceCardDestroyed.emit(DeffenceCard.global_position + (DeffenceCard.size / 2))
		var ShieldEff = DefVisual.instantiate() as BurstParticleGroup2D
		add_child(ShieldEff)
		ShieldEff.global_position = (DeffenceCard.global_position + (DeffenceCard.size / 2))
		ShieldEff.burst()

func ShieldTweenEnded(target : Control) -> void:
	var DFloater = DamageFloater.instantiate() as Floater
	DFloater.text = BuffText
	DFloater.modulate = Color(1,1,1,1)
	add_child(DFloater)
	DFloater.global_position = (target.global_position + (target.size / 2)) - DFloater.size / 2
	DFloater.Ended.connect(AnimEnded)

func BuffTweenEnded(target : Control) -> void:
	var DFloater = DamageFloater.instantiate() as Floater
	DFloater.text = BuffText
	DFloater.modulate = Color(1,1,1,1)
	add_child(DFloater)
	DFloater.global_position = (target.global_position + (target.size / 2)) - DFloater.size / 2
	DFloater.Ended.connect(AnimEnded)

func DoDeffensive(DefCard : CardStats, TargetShips : Array[Control], _FriendShip : bool) -> void:

	var DeffenceCard = CardScene.instantiate() as Card
	DeffenceCard.Dissable()
	DeffenceCard.SetCardStats(DefCard)
	$HBoxContainer.add_child(DeffenceCard)

	DeffenceCard.show_behind_parent = true
	DeffenceCard.modulate = Color(1,1,1,0)

	var DefCardTween = create_tween()
	DefCardTween.tween_property(DeffenceCard, "modulate", Color(1,1,1,1), 0.4)

	if (DefCard is Buff):
		if (DefCard.StatToBuff == Buff.Stat.FIREPOWER):
			BuffText = "Firepower +"
		else : if(DefCard.StatToBuff == Buff.Stat.SPEED):
			BuffText = "Speed +"
		for Ship in TargetShips:
			call_deferred("SpawnUpVisual", Ship, DeffenceCard)
	else: if (DefCard.Shield):
		BuffText = "Shield +"
		for Ship in TargetShips:
			call_deferred("SpawnShieldVisual", Ship, DeffenceCard)
	
	else : if (DefCard.FireExt):
		BuffText = "Fire\nExtinguished"
		for Ship in TargetShips:
			call_deferred("SpawnShieldVisual", Ship, DeffenceCard)

func DoSelection(C : CardStats, User : Control) -> void:
	var DeffenceCard = CardScene.instantiate() as Card
	DeffenceCard.Dissable()
	DeffenceCard.SetCardStats(C)
	add_child(DeffenceCard)
	
	var pos = Vector2(User.global_position.x - 200, User.global_position.y - (User.size.y / 2))
	DeffenceCard.global_position = pos

	DeffenceCard.show_behind_parent = true
	DeffenceCard.modulate = Color(1,1,1,0)

	var DefCardTween = create_tween()
	DefCardTween.tween_property(DeffenceCard, "modulate", Color(1,1,1,1), 0.4)
	
	var UpTween = create_tween()
	UpTween.set_ease(Tween.EASE_OUT)
	UpTween.set_trans(Tween.TRANS_BACK)
	UpTween.tween_property(DeffenceCard, "position", Vector2(pos.x, pos.y - 10), 0.4)
	await UpTween.finished
	
	var DownTween = create_tween()
	DownTween.set_ease(Tween.EASE_OUT)
	DownTween.set_trans(Tween.TRANS_BACK)
	DownTween.tween_property(DeffenceCard, "position", pos, 0.4)
	await DownTween.finished
	
	AnimationFinished.emit()

func DoFire(OriginShip : BattleShipStats, FriendShip : bool) -> void:
	var Ship = ShipViz.instantiate() as CardFightShipViz
	Ship.disabled = true
	Ship.SetStatsAnimation(OriginShip, FriendShip)
	$HBoxContainer.add_child(Ship)
	
	Ship.ToggleFire(true)
	var d = DamageFloater.instantiate() as Floater
	d.text = "Fire Damage - 10"
	add_child(d)
	d.global_position = (Ship.global_position + (Ship.size / 2)) - d.size / 2
	d.Ended.connect(AnimEnded)

var Finished : bool = false

func AnimEnded() -> void:
	if (Finished):
		return
	Finished = true
	AnimationFinished.emit()
