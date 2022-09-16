# Copyright (c) 2022 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
# This file is licensed under the MIT License
# https://github.com/ImmersiveRPG/ExampleRagdoll

extends Particles




func _on_timer_stop_timeout() -> void:
	self.emitting = false


func _on_timer_die_timeout() -> void:
	self.queue_free()
