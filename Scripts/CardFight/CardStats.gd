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
@export var WeapT : WeaponType
@export var UseConditions : Array[CardUseCondition]
@export var AllowTier : bool = true
var Tier : int = 0

func GetCardName() ->String:
	if (Tier > 0 and AllowTier):
		return CardName + " +{0}".format([Tier])
	
	return CardName

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

enum WeaponType{
	NONE,
	MG100mm,
	ML,
	COIL,
	MG180mm,
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
}
