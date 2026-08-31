extends Node

class_name DispositionManager

@export var DispositionRewards : Array[Disposition]

enum Dispositions {
	KINETIC,
	ELECTRICAL,
	THERMAL,
	MAGNETIC,
	RADIANT,
	NUCLEAR
}

static var Instance : DispositionManager

func _ready() -> void:
	Instance = self

func GetRewards(ch : Captain) -> Dictionary[CardStats, int]:
	var rewards : Dictionary[CardStats, int]

	for g in ch.disp:
		var dispositionValue = ch.disp[g] + ch.itemDisposition[g]
		
		var disp : Disposition = DispositionRewards[g]
		for d in disp.Levels:
			if (dispositionValue >= d.DispoistionStage):
				for reward in d.Rewards:
					if (rewards.has(reward)):
						rewards[reward] += d.Rewards[reward]
					else:
						rewards[reward] = d.Rewards[reward]
				
		
	return rewards
