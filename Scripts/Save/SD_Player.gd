extends Resource
class_name PlayerSaveData

var DataName = "PLData"
@export var Pos : Vector2
@export var Rot : float
@export var Speed : float
@export var FleetData : Array[FleetSaveData]
@export var PlayerFleet : Array[DroneSaveData]
@export var CameraPos : Vector2
@export var CameraZoom : Vector2
