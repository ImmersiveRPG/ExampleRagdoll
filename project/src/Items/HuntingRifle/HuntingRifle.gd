# Copyright (c) 2022 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
# This file is licensed under the MIT License
# https://github.com/ImmersiveRPG/ExampleRagdoll

extends RigidBody

func fire(target_pos : Vector3) -> void:
	var start_pos = $BulletStartPosition.global_transform.origin
	RuntimeInstancer.create_bullet(Global._root_node, start_pos, target_pos)
