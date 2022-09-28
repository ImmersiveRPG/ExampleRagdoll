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
	Head,
	Torso,
	Pelvis,
	UpperArmL,
	UpperArmR,
	LowerArmL,
	LowerArmR,
	UpperLegL,
	UpperLegR,
	LowerLegL,
	LowerLegR,
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

var all_bone_names := [
	"pelvis",
	"thighl",
	"calfl",
	"footl",
	"balll",
	"thighr",
	"calfr",
	"footr",
	"ballr",
	"spine_1",
	"spine_2",
	"neck_1",
	"head",
	"clavicler",
	"upperarmr",
	"lowerarmr",
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
	"claviclel",
	"upperarml",
	"lowerarml",
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
]

var head_bone_names := [
	"neck_1",
	"head",
]

var right_arm_bone_names := [
#	"pelvis",
#	"thighl",
#	"calfl",
#	"footl",
#	"balll",
#	"thighr",
#	"calfr",
#	"footr",
#	"ballr",
#	"spine_1",
#	"spine_2",
#	"neck_1",
#	"head",
#	"clavicler",
	"upperarmr",
	"lowerarmr",
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
#	"claviclel",
#	"upperarml",
#	"lowerarml",
#	"handl",
#	"thumb_1_l",
#	"thumb_2_l",
#	"thumb_3_l",
#	"ring_1_l",
#	"ring_2_l",
#	"ring_3_l",
#	"middle_1_l",
#	"middle_2_l",
#	"middle_3_l",
#	"index_1_l",
#	"index_2_l",
#	"index_3_l",
]

var left_arm_bone_names := [
#	"pelvis",
#	"thighl",
#	"calfl",
#	"footl",
#	"balll",
#	"thighr",
#	"calfr",
#	"footr",
#	"ballr",
#	"spine_1",
#	"spine_2",
#	"neck_1",
#	"head",
#	"clavicler",
#	"upperarmr",
#	"lowerarmr",
#	"handr",
#	"thumb_1_r",
#	"thumb_2_r",
#	"thumb_3_r",
#	"ring_1_r",
#	"ring_2_r",
#	"ring_3_r",
#	"middle_1_r",
#	"middle_2_r",
#	"middle_3_r",
#	"index_1_r",
#	"index_2_r",
#	"index_3_r",
#	"claviclel",
	"upperarml",
	"lowerarml",
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
]

var right_leg_bone_names := [
#	"pelvis",
#	"thighl",
#	"calfl",
#	"footl",
#	"balll",
	"thighr",
	"calfr",
	"footr",
	"ballr",
#	"spine_1",
#	"spine_2",
#	"neck_1",
#	"head",
#	"clavicler",
#	"upperarmr",
#	"lowerarmr",
#	"handr",
#	"thumb_1_r",
#	"thumb_2_r",
#	"thumb_3_r",
#	"ring_1_r",
#	"ring_2_r",
#	"ring_3_r",
#	"middle_1_r",
#	"middle_2_r",
#	"middle_3_r",
#	"index_1_r",
#	"index_2_r",
#	"index_3_r",
#	"claviclel",
#	"upperarml",
#	"lowerarml",
#	"handl",
#	"thumb_1_l",
#	"thumb_2_l",
#	"thumb_3_l",
#	"ring_1_l",
#	"ring_2_l",
#	"ring_3_l",
#	"middle_1_l",
#	"middle_2_l",
#	"middle_3_l",
#	"index_1_l",
#	"index_2_l",
#	"index_3_l",
]

var left_leg_bone_names := [
#	"pelvis",
	"thighl",
	"calfl",
	"footl",
	"balll",
#	"thighr",
#	"calfr",
#	"footr",
#	"ballr",
#	"spine_1",
#	"spine_2",
#	"neck_1",
#	"head",
#	"clavicler",
#	"upperarmr",
#	"lowerarmr",
#	"handr",
#	"thumb_1_r",
#	"thumb_2_r",
#	"thumb_3_r",
#	"ring_1_r",
#	"ring_2_r",
#	"ring_3_r",
#	"middle_1_r",
#	"middle_2_r",
#	"middle_3_r",
#	"index_1_r",
#	"index_2_r",
#	"index_3_r",
#	"claviclel",
#	"upperarml",
#	"lowerarml",
#	"handl",
#	"thumb_1_l",
#	"thumb_2_l",
#	"thumb_3_l",
#	"ring_1_l",
#	"ring_2_l",
#	"ring_3_l",
#	"middle_1_l",
#	"middle_2_l",
#	"middle_3_l",
#	"index_1_l",
#	"index_2_l",
#	"index_3_l",
]

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

func recursively_get_all_children(target : Node) -> Array:
	var matches := []
	var to_search := [target]
	while not to_search.empty():
		var entry = to_search.pop_front()

		for child in entry.get_children():
			to_search.append(child)

		matches.append(entry)

	return matches
