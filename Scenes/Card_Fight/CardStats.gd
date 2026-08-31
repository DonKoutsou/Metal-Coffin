extends Resource
class_name CardStats

@export var Icon : Texture
@export var CardName : String
@export var CardDescriptionOverride : String

## Energy consumption of card
@export var Energy : int

## Allow this card to be done twice in one turn?
@export var AllowDuplicates : bool

## Consume/Exhaust this card after use?
@export var OnUsed : OnUsePlacement = OnUsePlacement.NORMAL

##Modules applied once card is used
@export var OnUseModules : Array[CardModule]

##Modules applied once card is discarded
@export var OnDiscardModules : Array[CardModule]

##Modules applied once card is performed, mostly used for attacks. (Applied mostly to AI since players use attacks immidietly)
@export var OnPerformModule : CardModule

##Passive abilities
@export var Passive : Card_Passive

@export var Type : CardType

##Makes the card spawn on top of the deck at the start of the fight
@export var PutOnTop : bool = false

##If burned can't be used no more
@export var Burned : bool = false

##Weapon that this card needs to be able to be used
@export var WeapT : WeaponType

##Used for AI to easily determine if card can be used
@export var UseConditions : Array[CardUseCondition]

##Allow card to be upgraded with its owner ship part
@export var AllowTier : bool = true

##IF card is provided from disposition
@export var IsDisposition : bool = false

@export var PlayAnimation : CardFightShipViz2.AnimatioType = CardFightShipViz2.AnimatioType.NONE

var EnergyReduction : int = 0
var Tier : int = 0

#-------------------------------------------------------
func GetCost() -> int:
	return max(0, Energy - EnergyReduction)

#-------------------------------------------------------
func GetCardName() ->String:
	var n : String = ""
	if (Tier > 0 and AllowTier):
		n = CardName + " +{0}".format([Tier])
	else:
		n = CardName
	if (PutOnTop):
		n = "[color=#ffc315]SW[/color] " + n
	return n

#-------------------------------------------------------
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

#-------------------------------------------------------
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

#-------------------------------------------------------
func ShouldConsume() -> bool:
	return OnUsed == OnUsePlacement.CONSUME

#-------------------------------------------------------
func ShouldExhaust() -> bool:
	return OnUsed == OnUsePlacement.EXHAUST

#-------------------------------------------------------
func IsSame(C : CardStats) -> bool:
	return C.GetCardName() == GetCardName() and C.IsDisposition == IsDisposition

func IsEnergyDependant() -> bool:
	return UseConditions.has(CardUseCondition.ENERGY_DEPENDANT)

#-------------------------------------------------------
static func FindTooltips(card : CardStats) -> PackedStringArray:
	var tips : PackedStringArray = []
	
	if (card.IsDisposition):
		tips.append("TLTP_DISPOSITION")
	
	if (card.Type == CardStats.CardType.POWER):
		tips.append("TLTP_POWER")
		tips.append_array(GetTooltipsForModule(card.Passive.Module))
	
	if (card.PutOnTop):
		tips.append("TLTP_SWIFT")
	
	for g in card.OnUseModules:
		tips.append_array(GetTooltipsForModule(g))
			
	if (card.OnUseModules.size() > 0):
		tips.append("TLTP_ONUSE")
	if (card.OnDiscardModules.size() > 0):
		tips.append("TLTP_ONDISC")
	if (card.UseConditions.has(CardStats.CardUseCondition.ENERGY_DEPENDANT)):
		tips.append("TLTP_ENDEP")

	var perfModule = card.OnPerformModule
	if (perfModule != null):
		tips.append_array(GetTooltipsForModule(perfModule))
	
	return tips

#-------------------------------------------------------
static func GetTooltipsForModule(mod : CardModule) -> PackedStringArray:
	var tips : PackedStringArray = []
	if (mod is DeffenceCardModule):
		if (mod.AOE):
			if (!mod.SelfUse):
				tips.append("TLTP_SELF_EXC")
			tips.append("TLTP_AOE")
	if (mod is FireExtinguishModule):
		tips.append("TLTP_FIRE")
	if (mod is OffensiveCardModule):
		if (mod.AOE):
			tips.append("TLTP_AOE")
			
		if (mod.OnSuccesfullAtackModules.size() > 0):
			if (mod.forEachHit):
				tips.append("TLTP_PERHIT")
			else:
				tips.append("TLTP_ONHIT")
		
		if (mod.OnUnSuccesfullAtackModules.size() > 0):
			if (mod.forEachMis):
				tips.append("TLTP_ONMISS")
			else:
				tips.append("TLTP_PERMISS")
			
	if (mod is CounterCardModule):
		if (mod.OnSuccesfullDeffenceModules.size() > 0):
			tips.append("TLTP_ONCOUNTER")
		if (mod.CounterType == OffensiveCardModule.AtackTypes.DIRECT_ATTACK):
			tips.append("TLTP_COUNTER_DIR")
		if (mod.CounterType == OffensiveCardModule.AtackTypes.HOMING_ATTACK):
			tips.append("TLTP_COUNTER_HOM")
		
	if (mod is DamageReductionCardModule):
		if (mod.CounterType == OffensiveCardModule.AtackTypes.ANY_ATACK):
			tips.append("TLTP_DMG_RDC_ANY")
	
	return tips


enum WeaponType{
	NONE,
	MG_100mm,
	ML,
	COIL,
	MG_180mm,
	DRONE_DOCK,
	FLAME_THROWER,
}

enum OnUsePlacement{
	NORMAL,
	CONSUME,
	EXHAUST,
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
