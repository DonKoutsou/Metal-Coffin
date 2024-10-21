extends HBoxContainer
class_name UpgradeTab

signal OnUgradePressed(UpName : String)

var Upgradename : String

func SetData(Name : String, Textr : Texture) -> void:
	Upgradename = Name
	$Label.text = Name
	$TextureRect.texture = Textr

func UpgradeSuccess() -> void:
	$ProgressBar.value += 1

func _on_button_pressed() -> void:
	if ($ProgressBar.value == $ProgressBar.max_value):
		return
	OnUgradePressed.emit(self)
