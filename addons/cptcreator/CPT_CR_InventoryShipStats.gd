@tool
extends InventoryShipStats

class_name CPT_CR_InventoryShipStats

signal StatChanged()

func _ready() -> void:
	super()
	for g : CapCrStatSlider in $GridContainer.get_children():
		g.StatChanged.connect(OnStatChanged)

func OnStatChanged(stat : STAT_CONST.STATS, value : float) -> void:
	StatChanged.emit(stat, value)
