extends HBoxContainer
class_name UpgradeTab

signal OnUgradePressed(UpName : String)

var UpgradeData : Upgrade

func SetData(Data : Upgrade) -> void:
	UpgradeData = Data
	$Label.text = Data.UpgradeName
	$TextureRect.texture = Data.UpgradeItem.ItemIconSmol

func UpgradeSuccess() -> void:
	$ProgressBar.value += 1

func _on_button_pressed() -> void:
	if ($ProgressBar.value == $ProgressBar.max_value):
		return
	OnUgradePressed.emit(self)
