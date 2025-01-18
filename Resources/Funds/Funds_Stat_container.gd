extends PanelContainer
class_name FundsStat

@export var FundsThing : String
@export var PlayerWallet : Wallet

func _physics_process(_delta: float) -> void:
	$Control/TextureRect/Label.text = "{0} {1}".format([PlayerWallet.Funds, FundsThing])
