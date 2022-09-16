# Copyright (c) 2022 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
# This file is licensed under the MIT License
# https://github.com/ImmersiveRPG/ExampleRagdoll

extends Spatial


func _ready() -> void:
	Global._root_node = self

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	$Player.set_process_input(true)
	$Player.set_process(true)

func _input(_event) -> void:
	if Input.is_action_just_pressed("Quit"):
		self.get_tree().quit()
	elif Input.is_action_just_released("ToggleFullScreen"):
		OS.window_fullscreen = not OS.window_fullscreen
	elif Input.is_action_just_pressed("MoveNPC"):
		var positions := []
		for child in Global._root_node.get_children():
			if child is Position3D:
				positions.append(child)
		var position = Global.array_random_value(positions)
		$NPC._position = position
