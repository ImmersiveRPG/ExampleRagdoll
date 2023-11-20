# Copyright (c) 2021-2023 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
# This file is licensed under the MIT License
# https://github.com/ImmersiveRPG/ExampleRagdoll

extends Area3D


func _on_timer_stop_emitting_timeout() -> void:
	$Flame.emitting = false
	$Smoke.emitting = false
	$OmniLight3D.visible = false


func _on_timer_die_timeout() -> void:
	self.queue_free()
