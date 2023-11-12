# Copyright (c) 2021-2023 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
# All rights reserved. Proprietary and confidential
# Unauthorized copying of this file, via any medium is strictly prohibited
# https://github.com/workhorsy/ImmersiveRPG

extends Node3D




func _on_timer_stop_emitting_timeout() -> void:
	$Smoke.emitting = false

func _on_timer_die_timeout() -> void:
	self.queue_free()
