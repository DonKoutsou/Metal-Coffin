extends Resource
class_name CardOption

@export var OptionName : String
@export_multiline var OptionDescription : String
@export var NewPic : Texture
@export var EnergyAdd : int
@export var DamageFlat : int
@export var DamageMult : float = 1 #Multiplied over base damage of card
@export var Fire : bool = false

@export var AOE : bool = false
@export var DamageMitigationFlat : int
@export var DamageMitigationPercent : float
@export var ComatibleWeapon : CardStats.WeaponType
@export var CauseConsumption : bool
@export var NegateCounter : bool = false
