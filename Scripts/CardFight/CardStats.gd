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
## Part that needs to be in inventory to be able to see this card in fight
@export var RequiredPart : Array[ShipPart]

@export var OnUseModules : Array[CardModule]
@export var OnPerformModule : CardModule
@export var Type : CardType
@export var WeapT : WeaponType

var Tier : int = 0

func GetCardName() ->String:
	if (Tier > 0):
		return CardName + " +{0}".format([Tier])
	
	return CardName

func ShouldConsume() -> bool:
	#if is_instance_valid(SelectedOption):
		#return SelectedOption.CauseConsumption
	return Consume

func GetDescription() -> String:
	if (CardDescriptionOverride != ""):
		return CardDescriptionOverride
	var Desc = ""
	if is_instance_valid(OnPerformModule):
		Desc += OnPerformModule.GetDesc(Tier)
	if (OnUseModules.size() > 0):
		Desc += "[color=#ffc315]On Use[/color] : "
		for g in OnUseModules:
			Desc += g.GetDesc(Tier) + "\n"

	return Desc

func GetBattleDescription(User : BattleShipStats) -> String:
	if (CardDescriptionOverride != ""):
		return CardDescriptionOverride
	var Desc = ""
	if is_instance_valid(OnPerformModule):
		Desc += OnPerformModule.GetBattleDesc(User, Tier)
	if (OnUseModules.size() > 0):
		Desc += "[color=#ffc315]On Use[/color] : "
		for g in OnUseModules:
			Desc += g.GetBattleDesc(User, Tier) + "\n"

	return Desc

func IsSame(C : CardStats) -> bool:
	return C.GetCardName() == GetCardName()

enum WeaponType{
	NONE,
	MG100mm,
	ML,
	COIL,
}

enum CardType {
	OFFENSIVE,
	DEFFENSIVE,
	UTILITY
}
