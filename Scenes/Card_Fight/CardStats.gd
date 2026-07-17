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
@export var Type : CardType
@export var PutOnTop : bool = false
@export var Burned : bool = false
@export var WeapT : WeaponType
@export var UseConditions : Array[CardUseCondition]
@export var AllowTier : bool = true

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
	if (OnUseModules.size() > 0):
		Desc += "[color=#ffc315]\nOn Use[/color] : "
		for g in OnUseModules:
			Desc += "\n" + g.GetDesc(RealTier)
	if (OnDiscardModules.size() > 0):
		Desc += "[color=#ffc315]\nOn Discard[/color] : "
		for g in OnDiscardModules:
			Desc += "\n" + g.GetDesc(RealTier)
	
	return Desc

func GetBattleDescription(User : BattleShipStats) -> String:
	if (CardDescriptionOverride != ""):
		return CardDescriptionOverride
	
	var RealTier = 0
	if (AllowTier):
		RealTier = Tier
	
	var Desc = ""
	if is_instance_valid(OnPerformModule):
		Desc += OnPerformModule.GetBattleDesc(User, RealTier)
	if (OnUseModules.size() > 0):
		if (Desc.length() > 0):
			Desc += "\n"
		Desc += "[color=#ffc315]On Use[/color] : "
		for g in OnUseModules:
			Desc +=  "\n" + g.GetBattleDesc(User, RealTier)
	if (OnDiscardModules.size() > 0):
		if (Desc.length() > 0):
			Desc += "\n"
		Desc += "[color=#ffc315]On Discard[/color] : "
		for g in OnDiscardModules:
			Desc += "\n" + g.GetBattleDesc(User, RealTier)
	return Desc

func IsSame(C : CardStats) -> bool:
	return C.GetCardName() == GetCardName()

static func FindTooltips(card : CardStats) -> PackedStringArray:
	var desc = card.GetDescription()
	var words = strip_bbcode(desc.replace("\n", " ")).split(" ")
	var tips : PackedStringArray = []
	
	for g in card.OnUseModules:
		if (g is DeffenceCardModule):
			if (g.AOE):
				if (!g.SelfUse):
					tips.append(ToolTips["SELF_EXC"])
				tips.append(ToolTips["AOE"])
	
	for g in words:
		if (ToolTips.has(g)):
			tips.append(ToolTips[g])
			
	if (desc.find("On Use") > 0):
		tips.append(ToolTips["ONUSE"])
	if (desc.find("On Discard") > 0):
		tips.append(ToolTips["ONDISC"])
	if (desc.find("On Counter") > 0):
		tips.append(ToolTips["ONCOUNTER"])
	if (desc.find("On Hit") > 0):
		tips.append(ToolTips["ONHIT"])
	if (desc.find("On Miss") > 0):
		tips.append(ToolTips["ONMISS"])
	if (card.UseConditions.has(CardStats.CardUseCondition.ENERGY_DEPENDANT)):
		tips.append(ToolTips["ENDEP"])
	
	var perfModule = card.OnPerformModule
	if (perfModule != null):
		if (perfModule is OffensiveCardModule and perfModule.AOE):
			tips.append(ToolTips["AOE"])
		if (perfModule is CounterCardModule):
			if (perfModule.CounterType == OffensiveCardModule.AtackTypes.DIRECT_ATTACK):
				tips.append(ToolTips["COUNTER_DIR"])
			if (perfModule.CounterType == OffensiveCardModule.AtackTypes.HOMING_ATTACK):
				tips.append(ToolTips["COUNTER_HOM"])
			
		if (perfModule is DamageReductionCardModule):
			if (perfModule.CounterType == OffensiveCardModule.AtackTypes.ANY_ATACK):
				tips.append(ToolTips["DMG_RDC_ANY"])
			
	
	return tips

static func strip_bbcode(source:String) -> String:
	var regex = RegEx.new()
	regex.compile("\\[.+?\\]")
	return regex.sub(source, "", true)

const ToolTips : Dictionary[String, String] = {
	"fire" : "[color=#ff3c22]Fire[/color] damages the ship once per turn until extinguished",
	"fires" : "[color=#ff3c22]Fire[/color] damages the ship once per turn until extinguished",
	"ONUSE" : "[color=#ffc315]ON USE[/color] effects are performed the moment the card is played",
	"ONDISC" : "[color=#ffc315]ON DISCARD[/color] effects are performed the moment the card is discarded",
	"ONCOUNTER" : "[color=#ffc315]ON COUNTER[/color] effects are applied on successfull counters",
	"ONHIT" : "[color=#ffc315]ON HIT[/color] effects are applied once the attack lands",
	"ONMISS" : "[color=#ffc315]ON MISS[/color] effects are applied if the attack fails to land",
	"Shield" : "[color=#6be2e9]SHIELD[/color] protects the ship from direct damage",
	"ENDEP" : "[color=#ffc315]ENERGY DEPENDANT[/color] cards will use all of the user's energy to improve its stats",
	"UNAVOIDABLE" : "[color=#ffc315]UNAVOIDABLE[/color]\ncan't be avoided using a defence card",
	"AOE" : "[color=#ffc315]TEAM[/color] cards are applied to the entire team",
	"SELF_EXC" : "The effect of this card is not applied on the user",
	"COUNTER_DIR" : "This card will defend the user from an offensive [color=#ffc315]DIRECT ATTACK[/color] card",
	"COUNTER_HOM" : "This card will defend the user from an offensive [color=#ffc315]HOMING ATTACK[/color] card",
	"DMG_RDC_ANY" : "This card will reduce the damage of an offensive card",
}

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
	UTILITY
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
