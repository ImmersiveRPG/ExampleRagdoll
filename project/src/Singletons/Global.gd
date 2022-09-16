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

var _rng : RandomNumberGenerator
var _root_node : Node

onready var _scene_bullet := ResourceLoader.load("res://src/Bullet/Bullet.tscn")
onready var _scene_bullet_glow := ResourceLoader.load("res://src/BulletGlow/BulletGlow.tscn")
onready var _scene_bullet_spark := ResourceLoader.load("res://src/BulletSpark/BulletSpark.tscn")

func _ready() -> void:
	# Setup random number generator
	_rng = RandomNumberGenerator.new()
	_rng.randomize()

func create_bullet(parent : Node, start_pos : Vector3, target_pos : Vector3) -> void:
	var bullet = _scene_bullet.instance()
	parent.add_child(bullet)
	bullet.global_transform.origin = start_pos
	bullet.look_at(target_pos, Vector3.UP)
	bullet.start()

func create_bullet_spark(pos : Vector3) -> void:
	var spark = _scene_bullet_spark.instance()
	Global._root_node.add_child(spark)
	spark.global_transform.origin = pos

func array_random_index(array : Array) -> int:
	var i : int = _rng.randi_range(0, array.size() - 1)
	return i

func array_random_value(array : Array):
	var i : int = array_random_index(array)
	return array[i]

func array_pop_random_value(array : Array):
	var i : int = array_random_index(array)
	return array.pop_at(i)

enum BodyPart {
	Head,
	Torso,
	Pelvis,
	UpperArm,
	LowerArm,
	UpperLeg,
	LowerLeg,
}
