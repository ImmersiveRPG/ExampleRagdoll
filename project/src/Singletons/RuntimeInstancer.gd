# Copyright (c) 2022 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
# This file is licensed under the MIT License
# https://github.com/ImmersiveRPG/ExampleRagdoll

extends Node


const _scene_bullet := preload("res://src/Bullet/Bullet.tscn")
const _scene_bullet_glow := preload("res://src/BulletGlow/BulletGlow.tscn")
const _scene_bullet_spark := preload("res://src/BulletSpark/BulletSpark.tscn")
const _scene_npc := preload("res://src/NPC/NPC.tscn")
const _scene_blood_spray := preload("res://src/BloodSpray/BloodSpray.tscn")

func create_bullet(start_pos : Vector3, target_pos : Vector3) -> void:
	var bullet = _scene_bullet.instance()
	Global._world.add_child(bullet)
	bullet.global_transform.origin = start_pos
	bullet.look_at(target_pos, Vector3.UP)
	bullet.start()

func create_bullet_spark(pos : Vector3) -> void:
	var spark = _scene_bullet_spark.instance()
	Global._world.add_child(spark)
	spark.global_transform.origin = pos

func create_bullet_glow(parent_bullet : Spatial) -> void:
	var glow = _scene_bullet_glow.instance()
	Global._world.add_child(glow)
	glow.global_transform.origin = parent_bullet.global_transform.origin
	glow.start(parent_bullet)

func create_npc() -> void:
	# Create NPC and add to world
	var npcs = Global._world.get_node("NPCs")
	var npc = _scene_npc.instance()
	npcs.add_child(npc)

	# Move the NPC to a random position near center
	var r := 5.0
	npc.transform.origin = Vector3(
		Global._rng.randf_range(-r, r),
		0.0,
		Global._rng.randf_range(-r, r)
	)

func create_blood_spray(parent : Node, pos : Vector3) -> void:
	var spray = _scene_blood_spray.instance()
	parent.add_child(spray)
	spray.global_transform.origin = pos
	spray.look_at(Global._player.global_transform.origin, Vector3.UP)
