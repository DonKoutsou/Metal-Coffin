extends Node3D

@export var ItemDrop : Array[Item]

var RotationDirection : Vector3
var Reward : Array[Item]

func _ready() -> void:
	var it = ItemDrop.pick_random() as Item
	var RewardAmmount = randi_range(1, it.RandomFindMaxCount)
	for g in RewardAmmount :
		Reward.insert(g, it)

	var randomscale = randf_range(0.8, 1.2)
	scale = Vector3(randomscale,randomscale,randomscale)
	RotationDirection = Vector3(randf_range(0, 0.01), randf_range(0, 0.01), randf_range(0, 0.01))
	rotation = Vector3(randf_range(0, PI), randf_range(0, PI), randf_range(0, PI))
	
func _physics_process(_delta: float) -> void:
	rotation += RotationDirection
	position.z += 0.4
	if (position.z > 25):
		queue_free()

func _on_area_3d_area_entered(_area: Area3D) -> void:
	get_parent().SupplyGathered(Reward)
	queue_free()
