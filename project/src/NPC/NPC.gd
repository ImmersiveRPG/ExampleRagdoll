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

var _scene_blood_spray := preload("res://src/BloodSpray/BloodSpray.tscn")
onready var _animation_player = self.get_node("Pivot/Mannequiny/AnimationPlayer")

var _hp := HP_MAX
var _velocity := Vector3.ZERO
var _extra_velocity := Vector3.ZERO
var _snap_vector := Vector3.ZERO
var _destination : Position3D = null

func _notification(what : int) -> void:
	if what == NOTIFICATION_PREDELETE:
		Global._root_node.emit_signal("npc_died")

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

	# Update the velocity
	var prev_velocity = _velocity
	#print(_destination)
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
	_velocity = move_and_slide_with_snap(_velocity + _extra_velocity, _snap_vector, Vector3.UP, true, 4, Global.FLOOR_SLOPE_MAX_THRESHOLD, false)
	_extra_velocity = lerp(_extra_velocity, Vector3.ZERO, 0.1 * delta)

func _start_ragdoll() -> void:
	_animation_player.stop()
	$Pivot/Mannequiny/root/Skeleton.physical_bones_start_simulation()
	$Pivot/Mannequiny.is_ragdoll = true

func _stop_ragdoll() -> void:
	#_animation_player.stop()
	$Pivot/Mannequiny/root/Skeleton.physical_bones_stop_simulation()
	$Pivot/Mannequiny.is_ragdoll = false


func _on_hit_body_part(origin : Vector3, body_part : int) -> void:
	var power := 20.0

	match body_part:
		Global.BodyPart.Head:
			self.set_hp(0.0)
		Global.BodyPart.Torso:
			self.set_hp(_hp - power)
		Global.BodyPart.Pelvis:
			self.set_hp(_hp - power)
		Global.BodyPart.UpperArm:
			self.set_hp(_hp - power)
		Global.BodyPart.LowerArm:
			self.set_hp(_hp - power)
		Global.BodyPart.UpperLeg:
			self.set_hp(_hp - power)
		Global.BodyPart.LowerLeg:
			self.set_hp(_hp - power)
		_:
			push_error("Unexpected BodyPart: %s" % [body_part])
			return

	var name = Global.BodyPart.keys()[body_part]
	print("!!! hit %s" % [name])

	var spray = _scene_blood_spray.instance()
	self.add_child(spray)
	spray.global_transform.origin = origin
	spray.look_at(Global._player.global_transform.origin, Vector3.UP)

func _on_timer_die_timeout() -> void:
	self.queue_free()
