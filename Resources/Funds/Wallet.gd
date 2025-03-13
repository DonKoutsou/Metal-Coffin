extends Resource

class_name Wallet

signal OnFundsUpdated(NewF : float)

@export var Funds : float

func AddFunds(Amm : float) -> void:
	Funds += Amm
	OnFundsUpdated.emit(Funds)

func SetFunds(Amm : float) -> void:
	Funds = Amm
	OnFundsUpdated.emit(Funds)
