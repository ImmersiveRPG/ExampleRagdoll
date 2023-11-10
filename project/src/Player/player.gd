# Copyright (c) 2021-2023 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
# This file is licensed under the MIT License
# https://github.com/ImmersiveRPG/ExampleRagdoll

extends CharacterBody3D


const ACCELERATION_SPRINT := 100.0
const ACCELERATION_WALK := 70.0
const VELOCITY_SPRINT := 20.0
const VELOCITY_WALK := 10.0
const JUMP_IMPULSE := 20.0
const ROTATION_SPEED := 10.0
var GRAVITY : float = ProjectSettings.get_setting("physics/3d/default_gravity")

# Get the gravity from the project settings to be synced with RigidBody nodes
#var gravity : float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _camera_x := 0.0
var _camera_y := 0.0
var _camera_x_new := 0.0
var _camera_y_new := 0.0
var _latest_mouse_pos := Vector2.ZERO
var _target_pos := Vector3.ZERO

var _input_vector := Vector3.ZERO

func _input(event : InputEvent) -> void:
	# Rotate camera with mouse
	if event is InputEventMouseMotion:
		_camera_x -= event.relative.x * Global.MOUSE_SENSITIVITY
		_camera_y = clampf(_camera_y - event.relative.y * Global.MOUSE_SENSITIVITY, Global.MOUSE_Y_MIN, Global.MOUSE_Y_MAX)

	# Update the latest mouse position
	if event is InputEventMouse:
		_latest_mouse_pos = event.position

	# Just return if it is a keypress release or echo
	var key_event := event as InputEventKey
	if key_event and (not key_event.pressed or key_event.echo):
		return

	# Just return if it is a mouse button release
	var mouse_event := event as InputEventMouseButton
	if mouse_event and not mouse_event.pressed:
		return

	match Global.get_input_action_name(event):
		"ThrowCola":
			var force := 5.0
			#Engine.time_scale = 0.1
			var cb := func(org : Vector3, angle : Vector3, force : float):
				var rock_scene : PackedScene = ResourceLoader.load("res://src/Rock/Rock.tscn")
				var rock := rock_scene.instantiate()
				Global._world.add_child(rock)
				rock.start(org, angle * force)

			var org : Vector3 = $HandLocation.global_transform.origin
			var angle : Vector3 = -$Pivot/CameraMountFirstPerson/z.global_transform.basis.z
			for i in 10:
				cb.call(org, angle, 5.0)
		"ShootBullet":
			var cb := func(start_pos : Vector3, target_pos : Vector3):
				# Create bullet
				var spread := 0.0
				var bullet_type := Global.BulletType._308
				Global.create_bullet(Global._world, start_pos, target_pos, bullet_type, spread)

			var start_pos = $Pivot/RShoulder/Arm/BulletStart.global_transform.origin
			var target_pos = _target_pos
			for i in 1:
				cb.call(start_pos, target_pos)

func _process(delta : float) -> void:
	var camera : Camera3D = $Pivot/CameraMountFirstPerson/z/Camera3D

	# Get new camera angles
	_camera_x_new = lerp(_camera_x_new, _camera_x, delta * Global.MOUSE_ACCELERATION_X)
	_camera_y_new = lerp(_camera_y_new, _camera_y, delta * Global.MOUSE_ACCELERATION_Y)
	self.rotation_degrees.y = _camera_x_new

	# Update camera angles
	#camera = $Pivot/CameraMountFirstPerson/z/Camera3D
	var z = $Pivot/CameraMountFirstPerson/z
	z.rotation_degrees.x = lerp(z.rotation_degrees.x, _camera_y, delta * Global.MOUSE_ACCELERATION_Y)

	# Check keyboard input
	_input_vector = Vector3.ZERO
	_input_vector.x = Input.get_action_strength("MoveRight") - Input.get_action_strength("MoveLeft")
	var input_y = Input.get_action_strength("MoveBack") - Input.get_action_strength("MoveForward")
	_input_vector.z = input_y
	_input_vector = _input_vector.normalized()

	# Get ray where camera is pointing
	var target := Vector3.INF
	var ray_length := 300
	var from := camera.project_ray_origin(_latest_mouse_pos)
	var to := from + camera.project_ray_normal(_latest_mouse_pos) * ray_length
	var space_state := get_world_3d().direct_space_state
	var collision_mask := 0
	collision_mask |= Global.Layers.terrain | Global.Layers.item | Global.Layers.furniture | Global.Layers.structure | Global.Layers.body_part
	var query := PhysicsRayQueryParameters3D.create(from, to, collision_mask)
	var result := space_state.intersect_ray(query)
	target = result.position if result else to

	# Make player aim where ray is pointing
	if target != Vector3.INF:
		var arm := $Pivot/RShoulder
		Global.safe_look_at(arm, target)
		_target_pos = target

func _physics_process(delta : float) -> void:
	# Check if moving
	var input_direction : Vector3 = (_input_vector.x * transform.basis.x) + (_input_vector.z * transform.basis.z)
	var is_moving : bool = input_direction != Vector3.ZERO
	var is_sprinting : bool = Input.is_action_pressed("Sprint") and is_moving

	# Velocity
	var max_velocity := 0.0
	if is_sprinting:
		max_velocity = VELOCITY_SPRINT
	else:
		max_velocity = VELOCITY_WALK

	# Acceleration
	var acceleration := ACCELERATION_SPRINT if is_sprinting else ACCELERATION_WALK
	if is_moving:
		self.velocity.x = self.velocity.move_toward(input_direction * max_velocity, acceleration * delta).x
		self.velocity.z = self.velocity.move_toward(input_direction * max_velocity, acceleration * delta).z

	# Body rotation
	$Pivot.rotation.y = 0.0

	# Ground and air friction
	if not is_moving:
		if is_on_floor():
			self.velocity = self.velocity.move_toward(Vector3.ZERO, Global.FLOOR_FRICTION * delta)
		else:
			self.velocity.x = self.velocity.move_toward(input_direction * max_velocity, Global.AIR_FRICTION * delta).x
			self.velocity.z = self.velocity.move_toward(input_direction * max_velocity, Global.AIR_FRICTION * delta).z

	# Gravity
	if not self.is_on_floor():
		self.velocity.y = clampf(self.velocity.y - GRAVITY * delta, -GRAVITY, JUMP_IMPULSE)

	self.move_and_slide()
