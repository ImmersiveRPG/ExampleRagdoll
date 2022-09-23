# Copyright (c) 2022 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
# This file is licensed under the MIT License
# https://github.com/ImmersiveRPG/ExampleRagdoll

extends KinematicBody

const HP_MAX := 100.0
const VELOCITY_MAX := 10.0
const JUMP_IMPULSE := 20.0
const ROTATION_SPEED := 10.0

signal hit_body_part(origin, body_part)
var _is_dead := false

onready var _animation_player = self.get_node("Pivot/Mannequiny/AnimationPlayer")

var _hp := HP_MAX
var _velocity := Vector3.ZERO
var _snap_vector := Vector3.ZERO
var _destination : Position3D = null

func _notification(what : int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if Global._is_quitting: return
		Global._world.emit_signal("npc_died")

func _ready() -> void:
	_animation_player.play("idle")

func die() -> void:
	if _is_dead: return
	_is_dead = true

	$CollisionShape.disabled = true
	self._start_ragdoll()
	$TimerDie.start()


func set_hp(value : float) -> void:
	_hp = clamp(value, 0, HP_MAX)

	# Die if has no health
	if _hp == 0.0:
		self.die()

func _process(_delta : float) -> void:
	if _is_dead: return

	if Input.is_action_just_released("BreakRightArm"):
		$Pivot/Mannequiny.break_arm(Global.BrokenPart.RightArm)
	elif Input.is_action_just_released("BreakLeftArm"):
		$Pivot/Mannequiny.break_arm(Global.BrokenPart.LeftArm)
	elif Input.is_action_just_released("BreakRightLeg"):
		$Pivot/Mannequiny.break_arm(Global.BrokenPart.RightLeg)
	elif Input.is_action_just_released("BreakLeftLeg"):
		$Pivot/Mannequiny.break_arm(Global.BrokenPart.LeftLeg)

	# Update the velocity
	var prev_velocity = _velocity
	if _destination != null:
		var direction = _destination.global_transform.origin - self.transform.origin
		var threshold := 2.0
		if abs(direction.length()) < threshold:
			_destination = null
			_velocity = Vector3.ZERO
		else:
			_velocity = direction.normalized() * 2.0
	else:
		_velocity = Vector3.ZERO

	# Update the animation
	if prev_velocity != _velocity:
		if _velocity.is_equal_approx(Vector3.ZERO):
			_animation_player.play("idle")
		else:
			_animation_player.play("walk")

func _physics_process(delta : float) -> void:
	if _is_dead: return

	# Gravity
	_velocity.y = clamp(_velocity.y + Global.GRAVITY * delta, Global.GRAVITY, JUMP_IMPULSE)

	# Snap to floor plane if close enough
	_snap_vector = -get_floor_normal() if is_on_floor() else Vector3.DOWN

	# Face direction moving in
	if not is_equal_approx(_velocity.x, 0.0) and not is_equal_approx(_velocity.y, 0.0):
		self.rotation.y = lerp_angle(self.rotation.y, atan2(-_velocity.x, -_velocity.z), ROTATION_SPEED * delta)

	# Actually move
	_velocity = move_and_slide_with_snap(_velocity, _snap_vector, Vector3.UP, true, 4, Global.FLOOR_SLOPE_MAX_THRESHOLD, false)

func _start_ragdoll() -> void:
	_animation_player.stop()
	$Pivot/Mannequiny/root/Skeleton.physical_bones_start_simulation()
	$Pivot/Mannequiny.is_ragdoll = true

func _on_hit_body_part(origin : Vector3, body_part : int) -> void:
	# Get power based on body part
	var power := 0.0
	match body_part:
		Global.BodyPart.Head:
			power = 100.0
		Global.BodyPart.Torso:
			power = 20.0
		Global.BodyPart.Pelvis:
			power = 20.0
		Global.BodyPart.UpperArm:
			power = 20.0
		Global.BodyPart.LowerArm:
			power = 20.0
		Global.BodyPart.UpperLeg:
			power = 20.0
		Global.BodyPart.LowerLeg:
			power = 20.0
		_:
			push_error("Unexpected BodyPart: %s" % [body_part])
			return

	# Remove health
	self.set_hp(_hp - power)
	var name = Global.BodyPart.keys()[body_part]
	print("!!! hit %s" % [name])

	# Add blood spray
	RuntimeInstancer.create_blood_spray(self, origin)

func _on_timer_die_timeout() -> void:
	self.queue_free()
