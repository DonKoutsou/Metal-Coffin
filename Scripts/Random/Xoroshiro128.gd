# Based on the xoshiro/xoroshiro RNG family by
# David Blackman and Sebastiano Vigna.
# Official implementations are released under CC0:
# https://prng.di.unimi.it/

extends RefCounted
class_name Xoroshiro128

# SplitMix64 constants, written as signed 64-bit equivalents.

# 0x9E3779B97F4A7C15
const SPLITMIX_INC: int = -7046029254386353131

# 0xBF58476D1CE4E5B9
const SPLITMIX_MUL1: int = -4658895280553007687

# 0x94D049BB133111EB
const SPLITMIX_MUL2: int = -7723592293110705685

const INT64_MAX: int = 9223372036854775807
const FLOAT_53_SCALE: float = 1.0 / 9007199254740992.0 # 2^53

var _s0: int
var _s1: int

var _splitmix_state: int
var _calls: int = 0


func _init(seed_value: int = 1) -> void:
	set_seed(seed_value)


func set_seed(seed_value: int) -> void:
	_calls = 0
	_splitmix_state = seed_value

	_s0 = _splitmix64()
	_s1 = _splitmix64()

	# xoroshiro state must not be all zero.
	if (_s0 | _s1) == 0:
		_s0 = SPLITMIX_INC


func _splitmix64() -> int:
	_splitmix_state += SPLITMIX_INC

	var z: int = _splitmix_state
	z = (z ^ _urshift(z, 30)) * SPLITMIX_MUL1
	z = (z ^ _urshift(z, 27)) * SPLITMIX_MUL2
	z = z ^ _urshift(z, 31)

	return z


func _urshift(x: int, n: int) -> int:
	# Logical unsigned right shift for signed 64-bit ints.

	if n <= 0:
		return x

	if n >= 64:
		return 0

	if x >= 0:
		return x >> n

	# Special case because 1 << 63 overflows signed int.
	if n == 1:
		return (x >> n) & INT64_MAX

	var mask: int = (1 << (64 - n)) - 1
	return (x >> n) & mask


func _rotl(x: int, k: int) -> int:
	return (x << k) | _urshift(x, 64 - k)


func next_u64() -> int:
	# Returns the raw 64-bit output.
	# Because GDScript has signed ints, values above INT64_MAX
	# will appear as negative numbers.

	_calls += 1

	var s0: int = _s0
	var s1: int = _s1

	var result: int = s0 + s1

	s1 = s1 ^ s0

	_s0 = _rotl(s0, 55) ^ s1 ^ (s1 << 14)
	_s1 = _rotl(s1, 36)

	return result


func next_i63() -> int:
	# Non-negative 63-bit integer.
	# Uses the high 63 bits.
	return _urshift(next_u64(), 1)


func next_i32() -> int:
	# Non-negative 32-bit integer.
	# Uses high bits rather than low bits.
	return _urshift(next_u64(), 32)


func next_float() -> float:
	# Returns a float in [0.0, 1.0).
	# Uses the top 53 bits.
	return float(_urshift(next_u64(), 11)) * FLOAT_53_SCALE


func next_bool() -> bool:
	# Do not use the lowest bit for xoroshiro128+.
	# The low bits are weaker, so use a high bit instead.
	return _urshift(next_u64(), 63) != 0


func range_int(min_inclusive: int, max_exclusive: int) -> int:
	if max_exclusive <= min_inclusive:
		#push_error("max_exclusive must be greater than min_inclusive.")
		return min_inclusive

	var span: int = max_exclusive - min_inclusive

	# Rejection sampling using 63-bit non-negative values.
	# This avoids modulo bias.
	var limit: int = INT64_MAX - (INT64_MAX % span)

	while true:
		var r: int = next_i63()
		if r < limit:
			return min_inclusive + (r % span)

	return min_inclusive


func range_float(min_inclusive: float, max_exclusive: float) -> float:
	return min_inclusive + (max_exclusive - min_inclusive) * next_float()


func rand_weighted(weights) -> int:
	var total_weight: float = 0.0

	for weight in weights:
		var w := float(weight)
		if w > 0.0:
			total_weight += w

	if total_weight <= 0.0:
		push_error("rand_weighted() requires at least one positive weight.")
		return -1

	var r := range_float(0.0, total_weight)
	var running_total: float = 0.0

	for i in range(weights.size()):
		var w := float(weights[i])

		if w <= 0.0:
			continue

		running_total += w

		if r < running_total:
			return i

	# Fallback for floating-point edge cases.
	for i in range(weights.size() - 1, -1, -1):
		if float(weights[i]) > 0.0:
			return i

	return -1

func get_state() -> Dictionary:
	return {
		"algorithm": "xoroshiro128+",
		"calls": str(_calls),
		"s0": str(_s0),
		"s1": str(_s1),
		"splitmix_state": str(_splitmix_state),
	}


func set_state(state: Dictionary) -> void:
	if state.get("algorithm", "") != "xoroshiro128+":
		push_error("Invalid RNG state.")
		return

	_calls = int(state.get("calls", "0"))

	_s0 = int(state["s0"])
	_s1 = int(state["s1"])

	# Optional, but restores the full object state.
	_splitmix_state = int(state.get("splitmix_state", "0"))

	if (_s0 | _s1) == 0:
		push_error("Invalid xoroshiro128+ state: all zero.")
		_s0 = SPLITMIX_INC
