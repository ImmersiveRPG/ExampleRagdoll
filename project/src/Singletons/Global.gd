# Copyright (c) 2022 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
# This file is licensed under the MIT License
# https://github.com/ImmersiveRPG/ExampleRagdoll

extends Node

const GAME_TITLE := "Godot Ragdoll"

const AIR_FRICTION := 10.0
const FLOOR_SLOPE_MAX_THRESHOLD := deg2rad(60)
const FLOOR_FRICTION := 60.0
const GRAVITY := -40.0
const MOUSE_SENSITIVITY := 0.1
const MOUSE_ACCELERATION_X := 10.0
const MOUSE_ACCELERATION_Y := 10.0
const MOUSE_Y_MAX := 70.0
const MOUSE_Y_MIN := -60.0

enum BulletType {
	_308,
	_9MM,
}

enum BodyPart {
	Head = 1 << 0,
	Torso = 1 << 1,
	Pelvis = 1 << 2,
	UpperArmL = 1 << 3,
	UpperArmR = 1 << 4,
	LowerArmL = 1 << 5,
	LowerArmR = 1 << 6,
	HandL = 1 << 7,
	HandR = 1 << 8,
	UpperLegL = 1 << 9,
	UpperLegR = 1 << 10,
	LowerLegL = 1 << 11,
	LowerLegR = 1 << 12,
	FootL = 1 << 13,
	FootR = 1 << 14,
}

var DB = {
	"Bullets" : {
		BulletType._308 : {
			"mass" : 0.018,
			"speed" : 1219.0,
			"max_distance" : 5000.0,
		},
		BulletType._9MM : {
			"mass" : 0.0075,
			"speed" : 400.0,
			"max_distance" : 2000.0,
		},
	}
}

const bone_names := {
	BodyPart.Head : [
		"neck_1",
		"head",
	],
	BodyPart.Torso : [
		"spine_1",
		"spine_2",
		"clavicler",
		"claviclel",
	],
	BodyPart.Pelvis : [
		"pelvis",
	],
	BodyPart.UpperArmL : [
		"upperarml",
	],
	BodyPart.UpperArmR : [
		"upperarmr",
	],
	BodyPart.LowerArmL : [
		"lowerarml",
	],
	BodyPart.LowerArmR : [
		"lowerarmr",
	],
	BodyPart.HandL : [
		"handl",
		"thumb_1_l",
		"thumb_2_l",
		"thumb_3_l",
		"ring_1_l",
		"ring_2_l",
		"ring_3_l",
		"middle_1_l",
		"middle_2_l",
		"middle_3_l",
		"index_1_l",
		"index_2_l",
		"index_3_l",
	],
	BodyPart.HandR : [
		"handr",
		"thumb_1_r",
		"thumb_2_r",
		"thumb_3_r",
		"ring_1_r",
		"ring_2_r",
		"ring_3_r",
		"middle_1_r",
		"middle_2_r",
		"middle_3_r",
		"index_1_r",
		"index_2_r",
		"index_3_r",
	],
	BodyPart.UpperLegL : [
		"thighl",
	],
	BodyPart.UpperLegR : [
		"thighr",
	],
	BodyPart.LowerLegL : [
		"calfl",
	],
	BodyPart.LowerLegR : [
		"calfr",
	],
	BodyPart.FootL : [
		"footl",
		"balll",
	],
	BodyPart.FootR : [
		"footr",
		"ballr",
	],
}

func get_bone_names(body_parts : int) -> Array:
	var values := []

	for key in BodyPart.values():
		if body_parts & key > 0:
			for x in bone_names[key]:
				values.append(x)

	return values

var _is_quitting := false
var _rng : RandomNumberGenerator
var _world : Node = null
var _player : Node = null

func _ready() -> void:
	# Setup random number generator
	_rng = RandomNumberGenerator.new()
	_rng.randomize()

# Scales a transform without affecting the origin
func shrink_transform(tran : Transform, percent : float) -> Transform:
	var origin := tran.origin
	tran = tran.scaled(Vector3.ONE * percent)
	tran.origin = origin
	return tran

func array_random_index(array : Array) -> int:
	var i : int = _rng.randi_range(0, array.size() - 1)
	return i

func array_random_value(array : Array):
	var i : int = array_random_index(array)
	return array[i]

func enum_all_values(the_enum : Dictionary) -> int:
	var retval := 0
	for values in the_enum.values():
		retval += values
	return retval

func recursively_get_all_children(target : Node) -> Array:
	var matches := []
	var to_search := [target]
	while not to_search.empty():
		var entry = to_search.pop_front()

		for child in entry.get_children():
			to_search.append(child)

		matches.append(entry)

	return matches
