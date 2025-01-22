extends Resource
class_name CardStats

@export var Icon : Texture
@export var CardName : String
@export var CardDescription : String
@export var Energy : int
@export var Options : Array[CardOption]
@export var AllowDuplicates : bool
@export var Consume : bool = false
var SelectedOption : CardOption
