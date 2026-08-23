extends RefCounted

class_name Rand

var r : RandomNumberGenerator
var mut : Mutex

func GetState() -> int:
	return r.state

func Init(state : int = -1, customSeed : int = -1) -> void:
	r = RandomNumberGenerator.new()
	if (customSeed != -1):
		r.seed = customSeed
	else:
		r.seed = 1
		
	if (state != -1):
		r.state = state
	
	mut = Mutex.new()

func RandFRange(from : float, to : float) -> float:
	mut.lock()
	var randomFloat = r.randf_range(from, to)
	mut.unlock()
	print("Got random {0}".format([randomFloat]))
	return randomFloat

func RandF() -> float:
	mut.lock()
	var randomFloat = r.randf()
	mut.unlock()
	print("Got random {0}".format([randomFloat]))
	return randomFloat

func RandI() -> int:
	mut.lock()
	var randomInt = r.randi()
	mut.unlock()
	print("Got random {0}".format([randomInt]))
	return randomInt

func RandWeighted(weights : PackedFloat32Array) -> int:
	mut.lock()
	var randomInt = r.rand_weighted(weights)
	mut.unlock()
	print("Got random {0}".format([randomInt]))
	return randomInt

func RandIRange(from : int, to : int) -> int:
	mut.lock()
	var randomInt = r.randi_range(from, to)
	mut.unlock()
	print("Got random {0}".format([randomInt]))
	return randomInt

func shuffle_array(arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := RandIRange(0, i)

		var temp = arr[i]
		arr[i] = arr[j]
		arr[j] = temp

static func NewRand(state : int = -1, customSeed : int = -1) -> Rand:
	var rand = Rand.new()
	rand.Init(state, customSeed)
	return rand
