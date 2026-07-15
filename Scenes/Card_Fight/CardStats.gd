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
		Desc += "[color=#ffc315]On Use[/color] : "
		for g in OnUseModules:
			Desc += g.GetDesc(RealTier) + "\n"
	
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
		Desc += "[color=#ffc315]On Use[/color] : "
		for g in OnUseModules:
			Desc += g.GetBattleDesc(User, RealTier) + "\n"

	return Desc

func IsSame(C : CardStats) -> bool:
	return C.GetCardName() == GetCardName()

static func FindTooltips(card : CardStats) -> PackedStringArray:
	var desc = card.GetDescription()
	var words = strip_bbcode(desc.remove_chars("\n")).split(" ")
	var tips : PackedStringArray = []
	
	for g in words:
		if (ToolTips.has(g)):
			tips.append(ToolTips[g])
			
	if (desc.find("On Use") > 0):
		tips.append(ToolTips["ONUSE"])
	if (desc.find("On Counter") > 0):
		tips.append(ToolTips["ONCOUNTER"])
	if (desc.find("On Hit") > 0):
		tips.append(ToolTips["ONHIT"])
		
	return tips

static func strip_bbcode(source:String) -> String:
	var regex = RegEx.new()
	regex.compile("\\[.+?\\]")
	return regex.sub(source, "", true)

const ToolTips : Dictionary[String, String] = {
	"fire" : "[color=#ff3c22]Fire[/color] damages the ship onec per turn until extinguished",
	"fires" : "[color=#ff3c22]Fire[/color] damages the ship onec per turn until extinguished",
	"ONUSE" : "[color=#ffc315]On Use[/color] effects are performed the moment the card is played",
	"ONCOUNTER" : "[color=#ffc315]On Counter[/color] effects are applied on successfull counters",
	"ONHIT" : "[color=#ffc315]On Hit[/color] effects are applied once the atack lands",
	"Shield" : "[color=#6be2e9]Shield[/color] protects the ship from direct damage"
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
