extends Resource
class_name CardStats

@export var Icon : Texture
@export var CardName : String
@export_multiline var CardDescription : String
## Energy consumption of card
@export var Energy : int
#@export var Options : Array[CardOption]
## Allow this card to be done twice in one turn?
@export var AllowDuplicates : bool
## Consume this card after use?
@export var Consume : bool = false
## Part that needs to be in inventory to be able to see this card in fight
@export var RequiredPart : Array[ShipPart]

@export var Modules : Array[CardModule]

@export var WeapT : WeaponType

@export var AOE : bool = false

@export var Tier : int = 1

func ShouldConsume() -> bool:
	#if is_instance_valid(SelectedOption):
		#return SelectedOption.CauseConsumption
	return Consume

func GetDescription() -> String:
	#if is_instance_valid(SelectedOption):
		#return SelectedOption.OptionDescription
	return CardDescription

#var SelectedOption : CardOption

func IsAOE() -> bool:
	#if (SelectedOption):
		#return SelectedOption.AOE
	return AOE

enum WeaponType{
	NONE,
	MG100mm,
	ML,
}
