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

enum BodyPart {
	Head,
	Torso,
	Pelvis,
	UpperArm,
	LowerArm,
	UpperLeg,
	LowerLeg,
}

var _is_quitting := false
var _rng : RandomNumberGenerator
var _world : Node = null
var _player : Node = null

func _ready() -> void:
	# Setup random number generator
	_rng = RandomNumberGenerator.new()
	_rng.randomize()


func array_random_index(array : Array) -> int:
	var i : int = _rng.randi_range(0, array.size() - 1)
	return i

func array_random_value(array : Array):
	var i : int = array_random_index(array)
	return array[i]
