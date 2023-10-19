# Copyright (c) 2021-2023 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
# This file is licensed under the MIT License
# https://github.com/ImmersiveRPG/ExampleRagdoll

extends Node3D

# TODO:
#. rename branch v1 and v2 to part1_godot3 and part2_godot3
#. Add 2 NPCs to make sure they are separate.
#. _duplicate_body_part_into_own_skeleton calls BrokenBodyPart.start. Combine both into one function.
#. Make broken off limbs so they can be grabbed, thrown, and used as a melee weapon
#. Fix gaps between floppy limb joints
#. Blood splatter and decals
#. Add animation for NPC:
#	. Getting up off ground
#	. Walking with injured leg
#	. Holding injured arm
# Add dragging bodies like in Deus Ex


func _init() -> void:
	Global._world = self

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event : InputEvent) -> void:
	# Just return if it is a keypress release or echo
	var key_event := event as InputEventKey
	if key_event and (not key_event.pressed or key_event.echo):
		return

	# Just return if it is a mouse button release
	var mouse_event := event as InputEventMouseButton
	if mouse_event and not mouse_event.pressed:
		return

	# Get the action name for the input pressed
	var man = $NPC._mannequin
	var force := 5.0
	match Global.get_input_action_name(event):
		"ThrowCola":
			#Engine.time_scale = 0.1
			var cb := func(org : Vector3, angle : Vector3, force : float):
				var rock_scene : PackedScene = ResourceLoader.load("res://src/Rock/Rock.tscn")
				var rock := rock_scene.instantiate()
				Global._world.add_child(rock)
				rock.start(org, angle * force)

			var org : Vector3 = $Player/HandLocation.global_transform.origin
			var angle : Vector3 = -$Player/Pivot/CameraMountFirstPerson/z.global_transform.basis.z
			for i in 10:
				cb.call(org, angle, 5.0)
		"ShootBullet":
			var cb := func(start_pos : Vector3, target_pos : Vector3):
				# Create bullet
				var spread := 0.0
				var bullet_type := Global.BulletType._308
				Global.create_bullet(Global._world, start_pos, target_pos, bullet_type, spread)

			var start_pos = $Player/Pivot/RShoulder/Arm/BulletStart.global_transform.origin
			var target_pos = $Player._target_pos
			for i in 1:
				cb.call(start_pos, target_pos)
		"ThrowNPC":
			$NPC.die()
			var angle = -$Player/ThrowAngle.global_transform.basis.z
			man.push_at_angle(angle, 500.0)
		"NpcDie":
			if not $NPC._is_dead:
				$NPC.die()
			else:
				$NPC.live()
		"NPCMove":
			$NPC._path_marker = [Vector3(0, 0, 10), Vector3(10, 0, 0), Vector3(0, 0, -10), Vector3(-10, 0, 0)]
		"BreakEverything":
			var breaks := [
				Global.BodyPart.UpperArmR,
				Global.BodyPart.UpperArmL,
				Global.BodyPart.UpperLegR,
				Global.BodyPart.UpperLegL,
				Global.BodyPart.Head,
			]
			for body_part in breaks:
				var status = man._body_part_status[body_part]
				status = clampi(status + 1, 0, Global.enum_max_value(Global.BodyPartStatus))
				man.set_body_part_status(body_part, status)
		"BreakRightArm":
			var status = man._body_part_status[Global.BodyPart.UpperArmR]
			status = clampi(status + 1, 0, Global.enum_max_value(Global.BodyPartStatus))
			man.set_body_part_status(Global.BodyPart.UpperArmR, status)
		"BreakLeftArm":
			var status = man._body_part_status[Global.BodyPart.UpperArmL]
			status = clampi(status + 1, 0, Global.enum_max_value(Global.BodyPartStatus))
			man.set_body_part_status(Global.BodyPart.UpperArmL, status)
		"BreakRightLeg":
			var status = man._body_part_status[Global.BodyPart.UpperLegR]
			status = clampi(status + 1, 0, Global.enum_max_value(Global.BodyPartStatus))
			man.set_body_part_status(Global.BodyPart.UpperLegR, status)
		"BreakLeftLeg":
			var status = man._body_part_status[Global.BodyPart.UpperLegL]
			status = clampi(status + 1, 0, Global.enum_max_value(Global.BodyPartStatus))
			man.set_body_part_status(Global.BodyPart.UpperLegL, status)
		"BreakHead":
			var status = man._body_part_status[Global.BodyPart.Head]
			status = clampi(status + 1, 0, Global.enum_max_value(Global.BodyPartStatus))
			man.set_body_part_status(Global.BodyPart.Head, status)
		"ToggleMouseCapture":
			if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			else:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		"ToggleFullScreen":
			if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			else:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		"Quit":
			self.get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
			self.get_tree().quit()

func _on_timer_fps_timeout() -> void:
	$LabelFPS.text = "FPS: %s" % [Engine.get_frames_per_second()]
