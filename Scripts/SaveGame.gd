extends Resource
class_name SaveData

@export var DataName : String
@export var Datas : Array[Resource]

func GetData(DaName : String) -> Resource:
	var index
	for g in Datas.size():
		var dat = Datas[g]
		if (dat.DataName == DaName):
			index = g
	return Datas[index]
