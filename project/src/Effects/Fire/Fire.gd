# Copyright (c) 2021-2023 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
# All rights reserved. Proprietary and confidential
# Unauthorized copying of this file, via any medium is strictly prohibited
# https://github.com/workhorsy/ImmersiveRPG

extends Area3D

signal extinguish

func _on_area_entered(area : Area3D) -> void:
	# Put out fire if in liquid
	if area.is_in_group("liquid"):
		self.emit_signal("extinguish")
		self.queue_free()
