# Copyright (c) 2022 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
# This file is licensed under the MIT License
# https://github.com/ImmersiveRPG/ExampleRagdoll

extends Spatial

signal npc_died()

func _ready() -> void:
	Global._root_node = self

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	$Player.set_process_input(true)
	$Player.set_process(true)

func _input(_event) -> void:
	if Input.is_action_just_pressed("Quit"):
		Global._is_quitting = true
		self.get_tree().notification(MainLoop.NOTIFICATION_WM_QUIT_REQUEST)
	elif Input.is_action_just_released("ToggleFullScreen"):
		OS.window_fullscreen = not OS.window_fullscreen
	elif Input.is_action_just_pressed("MoveNPC"):
		# Pick random destination
		var destinations := $Positions.get_children()
		var destination = Global.array_random_value(destinations)

		# Give the NPC the destination
		var npcs := $NPCs.get_children()
		if not npcs.empty():
			npcs[0]._destination = destination

func _on_world_npc_died() -> void:
	RuntimeInstancer.create_npc()
