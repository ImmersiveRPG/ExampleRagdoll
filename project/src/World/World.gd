# Copyright (c) 2022 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
# This file is licensed under the MIT License
# https://github.com/ImmersiveRPG/ExampleRagdoll

extends Spatial

signal npc_died()

func _init() -> void:
	Global._world = self

func _ready() -> void:
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
		# Get a NPC
		var npcs := $NPCs.get_children()
		var npc = null
		if npcs.empty():
			return
		npc = npcs[0]

		# Get all the destinations
		var destinations := $Positions.get_children()

		# Get the NPC a random destination that is not the previous destination
		while true:
			var destination = Global.array_random_value(destinations)
			if npc._destination != destination:
				npc._destination = destination
				break

func _on_world_npc_died() -> void:
	RuntimeInstancer.create_npc()
