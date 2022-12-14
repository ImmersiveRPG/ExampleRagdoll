# Copyright (c) 2022 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
# This file is licensed under the MIT License
# https://github.com/ImmersiveRPG/ExampleRagdoll

extends KinematicBody

const HP_MAX := 100.0
const VELOCITY_MAX := 10.0
const JUMP_IMPULSE := 20.0
const ROTATION_SPEED := 10.0

signal hit_body_part(body_part, origin, angle, force, bullet_type)
var _is_dead := false

onready var _mannequiny = $Pivot/Mannequiny
onready var _animation_player = $Pivot/Mannequiny/AnimationPlayer

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
	_mannequiny.start_ragdoll()
	$TimerDie.start()

func set_hp(value : float) -> void:
	_hp = clamp(value, 0, HP_MAX)

	# Die if has no health
	if _hp == 0.0:
		self.die()

func _input(event : InputEvent) -> void:
	if _is_dead: return

	# Check for pressing key to pop off parts
	if Input.is_action_just_released("BreakEverything"):
		var basis = _mannequiny.global_transform.basis
		var breaks := {
			Global.BodyPart.UpperArmR : -basis.x,
			Global.BodyPart.UpperArmL : basis.x,
			Global.BodyPart.UpperLegR : -basis.x,
			Global.BodyPart.UpperLegL : basis.x,
			Global.BodyPart.Head : basis.y,
		}
		for body_part in breaks:
			var angle = breaks[body_part]
			_mannequiny.break_off_body_part(body_part, Vector3.ZERO, angle, 5.0)
	elif Input.is_action_just_released("BreakRightArm"):
		var angle = -_mannequiny.global_transform.basis.x
		_mannequiny.break_off_body_part(Global.BodyPart.UpperArmR, Vector3.ZERO, angle, 5.0)
	elif Input.is_action_just_released("BreakLeftArm"):
		var angle = _mannequiny.global_transform.basis.x
		_mannequiny.break_off_body_part(Global.BodyPart.UpperArmL, Vector3.ZERO, angle, 5.0)
	elif Input.is_action_just_released("BreakRightLeg"):
		var angle = -_mannequiny.global_transform.basis.x
		_mannequiny.break_off_body_part(Global.BodyPart.UpperLegR, Vector3.ZERO, angle, 5.0)
	elif Input.is_action_just_released("BreakLeftLeg"):
		var angle = _mannequiny.global_transform.basis.x
		_mannequiny.break_off_body_part(Global.BodyPart.UpperLegL, Vector3.ZERO, angle, 5.0)
	elif Input.is_action_just_released("BreakHead"):
		var angle = _mannequiny.global_transform.basis.y
		_mannequiny.break_off_body_part(Global.BodyPart.Head, Vector3.ZERO, angle, 5.0)
	elif Input.is_action_just_pressed("MoveNPC"):
		# Get all the destinations
		var destinations := Global._world.get_node("Positions").get_children()

		# Get the NPC a random destination that is not the previous destination
		while true:
			var destination = Global.array_random_value(destinations)
			if _destination != destination:
				_destination = destination
				break

func _process(_delta : float) -> void:
	if _is_dead: return

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
		self.rotation.y = lerp_angle(self.rotation.y, atan2(_velocity.x, _velocity.z), ROTATION_SPEED * delta)

	# Actually move
	_velocity = move_and_slide_with_snap(_velocity, _snap_vector, Vector3.UP, true, 4, Global.FLOOR_SLOPE_MAX_THRESHOLD, false)


func _on_hit_body_part(body_part : int, origin : Vector3, angle : Vector3, force : float, bullet_type : int) -> void:
	var can_break := true

	# Get power based on body part
	var power := 0.0
	match body_part:
		Global.BodyPart.Head:
			power = 100.0
		Global.BodyPart.Torso:
			power = 20.0
			can_break = false
		Global.BodyPart.Pelvis:
			power = 20.0
			can_break = false
		Global.BodyPart.LowerArmR, Global.BodyPart.UpperArmR, Global.BodyPart.HandR:
			power = 20.0
		Global.BodyPart.LowerArmL, Global.BodyPart.UpperArmL, Global.BodyPart.HandL:
			power = 20.0
		Global.BodyPart.LowerLegR, Global.BodyPart.UpperLegR, Global.BodyPart.FootR:
			power = 20.0
		Global.BodyPart.LowerLegL, Global.BodyPart.UpperLegL, Global.BodyPart.FootL:
			power = 20.0
		_:
			push_error("Unexpected BodyPart: %s" % [body_part])
			return

	# Remove health
	self.set_hp(_hp - power)
	for name in Global.BodyPart:
		var value = Global.BodyPart[name]
		if value == body_part:
			print("!!! hit %s" % [name])

	# If dead, add force to the location hit for ragdoll
	if _is_dead:
		_mannequiny.apply_force_to_body_part(body_part, angle, force)

	# Add blood spray
	RuntimeInstancer.create_blood_spray(self, origin, angle)

	# if the bullet is powerfull, break off the hit body part
	if can_break and bullet_type == Global.BulletType._308:
		_mannequiny.break_off_body_part(body_part, origin, angle, force)

func _on_timer_die_timeout() -> void:
	self.queue_free()
