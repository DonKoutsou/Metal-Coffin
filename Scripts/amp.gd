extends PanelContainer

@export var Eqs : Array[EQ]

func toggle(t : bool):
	for g in Eqs:
		g.Toggle(t)
