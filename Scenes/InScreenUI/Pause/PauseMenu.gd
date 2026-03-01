extends PanelContainer

class_name PauseMenu

@export var Manual : FlightManual
@export var PopupPlecement : Control

func _on_flight_manual_pressed() -> void:
	Manual.visible = true

func _on_save_pressed() -> void:
	if (CageFightWorld.GetInstance() != null):
		PopUpManager.GetInstance().DoFadeNotif("Can't save in a cagefight", PopupPlecement)
		return
	if (get_tree().get_nodes_in_group("CardFight").size() > 0):
		PopUpManager.GetInstance().DoFadeNotif("Can't save while in a fight", PopupPlecement)
		return
	SaveLoadManager.GetInstance().Save()
	PopUpManager.GetInstance().DoFadeNotif("Save successful", PopupPlecement)
	
func _on_exit_pressed() -> void:
	var world = World.GetInstance()
	if (world != null):
		world.EndGame()
		return
	var cardworld = CageFightWorld.GetInstance()
	if (cardworld != null):
		cardworld.EndGame()
