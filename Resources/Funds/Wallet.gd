extends Resource

class_name Wallet

signal OnFundsUpdated(NewF : int)

@export var Funds : int

func AddFunds(Amm : int) -> void:
	Funds += Amm
	OnFundsUpdated.emit(Funds)

func SetFunds(Amm : int) -> void:
	Funds = Amm
	OnFundsUpdated.emit(Funds)
