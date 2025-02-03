extends Control
class_name FundsStat

@export var FundsThing : String
@export var PlayerWallet : Wallet

func _physics_process(_delta: float) -> void:
	$Label.text = "{0} {1}".format([PlayerWallet.Funds, FundsThing])
