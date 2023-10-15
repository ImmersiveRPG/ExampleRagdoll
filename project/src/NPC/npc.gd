# Copyright (c) 2021-2023 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
# This file is licensed under the MIT License
# https://github.com/ImmersiveRPG/ExampleRagdoll

extends CharacterBody3D

const HP_MAX := 100.0
const SPEED := 5.0
const JUMP_IMPULSE := 20.0
const ROTATION_SPEED := 10.0
const SPEED_WALK := 1.9
const SPEED_RUN := 6.0
var GRAVITY : float = ProjectSettings.get_setting("physics/3d/default_gravity")

signal hit_body_part(collider : Node, body_part : Global.BodyPart, origin : Vector3, angle : Vector3, force : float, bullet_type : int)

@onready var _mannequin = $Pivot/Mannequin
@onready var _skeleton = $"Pivot/Mannequin/Armature/PhysicsSkeleton3D"
@onready var _skeleton_center = self.get_node("Pivot/Mannequin/Armature/PhysicsSkeleton3D/Physical Bone %s" % [Global.bone_names[Global.BodyPart.TorsoMiddle][0]])
@onready var _animation_player = $Pivot/Mannequin/AnimationPlayer

var _is_dead := false
var _hp := HP_MAX
var _speed := SPEED_WALK
var _path_marker := []
var _body_part_health := {}
var _velocity := Vector3.ZERO
var _velocity_gravity := Vector3.ZERO

func _ready() -> void:
	_animation_player.play("idle")

	for part in Global.BodyPart.values():
		_body_part_health[part] = 100.0

func _process(_delta : float) -> void:
	if _is_dead: return

	# Update the velocity
	var prev_velocity := _velocity
	if not _path_marker.is_empty():
		var direction : Vector3 = _path_marker[0] - self.global_transform.origin
		var direction_xz := Vector2(direction.x, direction.z)
		var distance_xz := absf(direction_xz.length())
		var distance_y := absf(direction.y)

		var threshold_xz := 1.0
		var threshold_y := 3.0
		if distance_xz < threshold_xz and distance_y < threshold_y:
			_path_marker.pop_front()
		else:
			_velocity = direction.normalized() * _speed
	else:
		# Stop moving
		_velocity = Vector3.ZERO

	# Update the animation
	if prev_velocity != _velocity:
		if _velocity.is_equal_approx(Vector3.ZERO):
			_animation_player.play("idle")
		else:
			if _speed > SPEED_WALK:
				_animation_player.play("run")
			else:
				_animation_player.play("walk")

func _physics_process(delta : float) -> void:
	# When ragdolling, move to skeleton location
	if _mannequin.is_ragdoll:
		self.global_transform.origin = _skeleton_center.global_transform.origin

	if _is_dead: return

	# Add the gravity
	if not self.is_on_floor():
		_velocity_gravity.y = clampf(_velocity_gravity.y - GRAVITY * delta, -GRAVITY, 0.0)
	else:
		_velocity_gravity.y = 0.0

	# Rotate to direction moving in
	self.rotation.y = lerp_angle(self.rotation.y, atan2(_velocity.x, _velocity.z), ROTATION_SPEED * delta)

	# Actually move
	self.velocity = _velocity + _velocity_gravity
	self.move_and_slide()

func _on_hit_body_part(collider : Node, body_part : Global.BodyPart, origin : Vector3, angle : Vector3, force : float, bullet_type : int) -> void:
	var can_break := true

	# Get power based on body part
	var power := 0.0
	var body_part_root : Global.BodyPart = -1
	match body_part:
		Global.BodyPart.Head:
			power = 100.0
			body_part_root = Global.BodyPart.Head
		Global.BodyPart.TorsoUpper, Global.BodyPart.TorsoMiddle, Global.BodyPart.TorsoLower:
			power = 20.0
			body_part_root = Global.BodyPart.TorsoUpper
			can_break = false
		Global.BodyPart.Pelvis:
			power = 20.0
			body_part_root = Global.BodyPart.Pelvis
			can_break = false
		Global.BodyPart.LowerArmR, Global.BodyPart.UpperArmR, Global.BodyPart.HandR:
			power = 20.0
			body_part_root = Global.BodyPart.UpperArmR
		Global.BodyPart.LowerArmL, Global.BodyPart.UpperArmL, Global.BodyPart.HandL:
			power = 20.0
			body_part_root = Global.BodyPart.UpperArmL
		Global.BodyPart.LowerLegR, Global.BodyPart.UpperLegR, Global.BodyPart.FootR:
			power = 20.0
			body_part_root = Global.BodyPart.UpperLegR
		Global.BodyPart.LowerLegL, Global.BodyPart.UpperLegL, Global.BodyPart.FootL:
			power = 20.0
			body_part_root = Global.BodyPart.UpperLegL
		_:
			push_error("Unexpected BodyPart: %s" % [body_part])
			return

	collider.apply_central_impulse(angle * force)

	var value = Global.enum_name_from_value(Global.BodyPart, body_part_root)

	if can_break:
		var health : float = _body_part_health[body_part_root]
		health = clampf(health - power, 0.0, 100.0)
		#var zz = Global.enum_name_from_value(Global.BodyPart, body_part_root)
		#print("!!! hit %s, %s, %s, %s" % [value, body_part_root, zz, health])
		if health > 60.0:
			_mannequin.set_body_part_status(body_part_root, Global.BodyPartStatus.Normal)
		elif health > 30.0:
			_mannequin.set_body_part_status(body_part_root, Global.BodyPartStatus.Crippled)
		else:
			_mannequin.set_body_part_status(body_part_root, Global.BodyPartStatus.Destroyed)
		_body_part_health[body_part_root] = health

func set_hp(value : float) -> void:
	_hp = clampf(value, 0, HP_MAX)

	# Die if has no health
	if _hp == 0.0:
		self.die()

func die() -> void:
	if _is_dead: return
	_is_dead = true

	$CollisionShape3D.disabled = true
	_mannequin._start_ragdoll()

func live() -> void:
	if not _is_dead: return
	_is_dead = false

	$CollisionShape3D.disabled = false
	_mannequin._stop_ragdoll()
