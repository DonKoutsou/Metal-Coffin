extends Resource

class_name CaptainSpawnInfo
#Used inside the SawnDecider to configure cost of each enemy ship to spawn

@export var Cpt : Captain
@export var Cost : int
@export var MaxAmmInFleet : int
@export var DontGenerateBefore : Happening.GameStage
@export var SpawnAlone : bool = true
