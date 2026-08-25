extends Ingame_UIManager

class_name CageFight_IngameUI

func _ready() -> void:
	Instance = self
	EventHandler.PausePressed.connect(Pause)
	ToggleScreenGlitches(SettingsPanel.GetGlitch())
