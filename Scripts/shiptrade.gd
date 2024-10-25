extends Control

class_name ShipTrade

signal OnTradeFinished(ShipToTake : BaseShip)

var OrigShip : BaseShip
var NewShip : BaseShip

func StartTrade(MyShip : BaseShip, ShipToTrade : BaseShip) -> void:
	OrigShip = MyShip
	NewShip = ShipToTrade
	$HBoxContainer/MyShip/HBoxContainer/VBoxContainer/Panel/InventoryShipStats.UpdateValues(MyShip)
	$HBoxContainer/MyShip/HBoxContainer/VBoxContainer/HBoxContainer/TextureRect.texture = MyShip.Icon
	$HBoxContainer/MyShip/HBoxContainer/VBoxContainer/HBoxContainer/VBoxContainer/Label.text = MyShip.ShipName
	$HBoxContainer/MyShip/HBoxContainer/VBoxContainer/HBoxContainer/VBoxContainer/Label2.text = MyShip.ShipDesc
	$HBoxContainer/Ship2trade/HBoxContainer/VBoxContainer/Panel/InventoryShipStats	.UpdateValues(ShipToTrade)
	$HBoxContainer/Ship2trade/HBoxContainer/VBoxContainer/HBoxContainer/TextureRect.texture = ShipToTrade.Icon
	$HBoxContainer/Ship2trade/HBoxContainer/VBoxContainer/HBoxContainer/VBoxContainer/Label.text = ShipToTrade.ShipName
	$HBoxContainer/Ship2trade/HBoxContainer/VBoxContainer/HBoxContainer/VBoxContainer/Label2.text = ShipToTrade.ShipDesc

func TradeFinished(Ship : BaseShip) -> void:
	OnTradeFinished.emit(Ship)
func _on_ship_2_trade_button_pressed() -> void:
	TradeFinished(NewShip)
	queue_free()


func _on_my_ship_button_pressed() -> void:
	TradeFinished(OrigShip)
	queue_free()
