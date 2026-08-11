extends Resource
class_name CardStats

@export var Icon : Texture
@export var CardName : String
@export var CardDescriptionOverride : String
## Energy consumption of card
@export var Energy : int
#@export var Options : Array[CardOption]
## Allow this card to be done twice in one turn?
@export var AllowDuplicates : bool
## Consume this card after use?
@export var Consume : bool = false
@export var OnUseModules : Array[CardModule]
@export var OnDiscardModules : Array[CardModule]
@export var OnPerformModule : CardModule
@export var Passive : Card_Passive
@export var Type : CardType
@export var PutOnTop : bool = false
@export var Burned : bool = false
@export var WeapT : WeaponType
@export var UseConditions : Array[CardUseCondition]
@export var AllowTier : bool = true
@export var IsDisposition : bool = false
var EnergyReduction : int = 0
var Tier : int = 0


func GetCost() -> int:
	return max(0, Energy - EnergyReduction)

func GetCardName() ->String:
	var n : String = ""
	if (Tier > 0 and AllowTier):
		n = CardName + " +{0}".format([Tier])
	else:
		n = CardName
	if (PutOnTop):
		n = "[color=#ffc315]SW[/color] " + n
	return n

func ShouldConsume() -> bool:
	#if is_instance_valid(SelectedOption):
		#return SelectedOption.CauseConsumption
	return Consume

func GetDescription() -> String:
	var RealTier = 0
	if (AllowTier):
		RealTier = Tier
		
	if (CardDescriptionOverride != ""):
		return CardDescriptionOverride
	var Desc = ""
	if is_instance_valid(OnPerformModule):
		Desc += OnPerformModule.GetDesc(RealTier)
		Desc += "\n"
	if (OnUseModules.size() > 0):
		Desc += "[color=#ffc315][[CT_ONUSE]][/color] : "
		for g in OnUseModules:
			Desc += g.GetDesc(RealTier)
	if (OnDiscardModules.size() > 0):
		if (Desc.length() > 0):
			Desc += "\n"
		Desc += "[color=#ffc315][[CT_ONDISC]][/color] : "
		for g in OnDiscardModules:
			Desc += g.GetDesc(RealTier)
	
	if (Passive != null):
		Desc += Passive.GetDesc(RealTier)
		Desc += "\n"
		
	return Helper.Translate(Desc)

func GetBattleDescription(User : BattleShipStats) -> String:
	if (CardDescriptionOverride != ""):
		return CardDescriptionOverride
	
	var RealTier = 0
	if (AllowTier):
		RealTier = Tier
	
	var Desc = ""
	if is_instance_valid(OnPerformModule):
		Desc += OnPerformModule.GetBattleDesc(User, RealTier)
		Desc += "\n"
	if (OnUseModules.size() > 0):
		Desc += "[color=#ffc315][[CT_ONUSE]][/color] : "
		for g in OnUseModules:
			Desc +=  g.GetBattleDesc(User, RealTier)
	if (OnDiscardModules.size() > 0):
		if (Desc.length() > 0):
			Desc += "\n"
		Desc += "[color=#ffc315][[CT_ONDISC]][/color] : "
		Desc += "\n"
		for g in OnDiscardModules:
			Desc += g.GetBattleDesc(User, RealTier)
	
	if (Passive != null):
		Desc += Passive.GetBattleDesc(User, RealTier)
		Desc += "\n"
	
	return Helper.Translate(Desc)

func IsSame(C : CardStats) -> bool:
	return C.GetCardName() == GetCardName() and C.IsDisposition == IsDisposition

static func FindTooltips(card : CardStats) -> PackedStringArray:
	#var desc = card.GetDescription()
	#var words = strip_bbcode(desc.replace("\n", " ")).split(" ")
	var tips : PackedStringArray = []
	
	if (card.IsDisposition):
		tips.append("TLTP_DISPOSITION")
	
	if (card.Type == CardStats.CardType.POWER):
		tips.append("TLTP_POWER")
	
	if (card.PutOnTop):
		tips.append("TLTP_SWIFT")
	
	for g in card.OnUseModules:
		if (g is DeffenceCardModule):
			if (g.AOE):
				if (!g.SelfUse):
					tips.append("TLTP_SELF_EXC")
				tips.append("TLTP_AOE")
			
	if (card.OnUseModules.size() > 0):
		for g in card.OnUseModules:
			if (g is FireExtinguishModule):
				tips.append("TLTP_FIRE")
		tips.append("TLTP_ONUSE")
	if (card.OnDiscardModules.size() > 0):
		tips.append("TLTP_ONDISC")
	if (card.UseConditions.has(CardStats.CardUseCondition.ENERGY_DEPENDANT)):
		tips.append("TLTP_ENDEP")

	var perfModule = card.OnPerformModule
	if (perfModule != null):
		if (perfModule is OffensiveCardModule):
			if (perfModule.AOE):
				tips.append("TLTP_AOE")
				
			if (perfModule.OnSuccesfullAtackModules.size() > 0):
				if (perfModule.forEachHit):
					tips.append("TLTP_PERHIT")
				else:
					tips.append("TLTP_ONHIT")
			
			if (perfModule.OnUnSuccesfullAtackModules.size() > 0):
				if (perfModule.forEachMis):
					tips.append("TLTP_ONMISS")
				else:
					tips.append("TLTP_PERMISS")
				
		if (perfModule is CounterCardModule):
			if (perfModule.OnSuccesfullDeffenceModules.size() > 0):
				tips.append("TLTP_ONCOUNTER")
			if (perfModule.CounterType == OffensiveCardModule.AtackTypes.DIRECT_ATTACK):
				tips.append("TLTP_COUNTER_DIR")
			if (perfModule.CounterType == OffensiveCardModule.AtackTypes.HOMING_ATTACK):
				tips.append("TLTP_COUNTER_HOM")
			
		if (perfModule is DamageReductionCardModule):
			if (perfModule.CounterType == OffensiveCardModule.AtackTypes.ANY_ATACK):
				tips.append("TLTP_DMG_RDC_ANY")
	
	return tips

static func strip_bbcode(source:String) -> String:
	var regex = RegEx.new()
	regex.compile("\\[.+?\\]")
	return regex.sub(source, "", true)
	
enum WeaponType{
	NONE,
	MG_100mm,
	ML,
	COIL,
	MG_180mm,
	DRONE_DOCK,
	FLAME_THROWER,
}

enum CardType {
	OFFENSIVE,
	DEFFENSIVE,
	UTILITY,
	POWER,
}

enum CardUseCondition{
	NONE,
	NO_SOLO,
	ENERGY_DEPENDANT,
	HAS_DEBUFF,
	ENOUGH_HP,
	ENOUGH_DEF,
	ENOUGH_FP,
	ENOUGHT_SPEED,
	RESERVE_DEPENDANT,
	ENOUGH_TURNS_PASSED,
	ON_FIRE,
}
