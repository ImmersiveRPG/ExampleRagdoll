# Copyright (c) 2022 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
# This file is licensed under the MIT License
# https://github.com/ImmersiveRPG/ExampleRagdoll

extends Node


var _scene_bullet := preload("res://src/Bullet/Bullet.tscn")
var _scene_bullet_glow := preload("res://src/BulletGlow/BulletGlow.tscn")
var _scene_bullet_spark := preload("res://src/BulletSpark/BulletSpark.tscn")
var _scene_npc = preload("res://src/NPC/NPC.tscn")

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

func create_npc() -> void:
	# Create NPC and add to world
	var npc = _scene_npc.instance()
	Global._root_node.get_node("NPCs").add_child(npc)

	# Move the NPC to a random position near center
	var r := 5.0
	npc.transform.origin = Vector3(
		Global._rng.randf_range(-r, r),
		0.0,
		Global._rng.randf_range(-r, r)
	)

