# Copyright (c) 2021-2023 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
# This file is licensed under the MIT License
# https://github.com/workhorsy/PatreonRagdolls1

extends Node3D
class_name Bullet

var _bullet_type := -1
var _mass := -1.0
var _max_distance := -1.0
var _glow = null
var _speed := 0.0
var _velocity : Vector3
var _is_setup := false

var _total_distance := 0.0
@onready var _ray : RayCast3D = $RayCast3D

# NOTE: Make sure min bounce distance is greater than max raycast distance
const MIN_BOUNCE_DISTANCE := 0.1
const MIN_RAYCAST_DISTANCE := 0.05

func _physics_process(delta : float) -> void:
	if not _is_setup: return
	var is_destroyed := false

	_glow.update(self.global_transform.origin)

	# Move the bullet
	var distance := _velocity.length() * delta
	self.transform.origin -= _velocity * delta

	# Change the ray start position to the bullets's previous position
	# NOTE: The ray is backwards, so if it is hitting multiple targets, we
	# get the target closest to the bullet start position.
	# Also make the ray at least the min length
	if distance > MIN_RAYCAST_DISTANCE:
		_ray.target_position.z = -distance
		_ray.transform.origin.z = distance
	else:
		_ray.target_position.z = -MIN_RAYCAST_DISTANCE
		_ray.transform.origin.z = MIN_RAYCAST_DISTANCE

	# Check if hit something
	_ray.force_raycast_update()
	if _ray.is_colliding():
		var collider := _ray.get_collider()
		print("Bullet hit %s" % [collider.name])

		# Move the bullet back to the position of the collision
		self.global_transform.origin = _ray.get_collision_point()

		if collider.is_in_group("body_part"):
			var force := _mass * _velocity.length()
			collider.owner.emit_signal("hit", collider, self.global_transform.origin, -self.global_transform.basis.z, force, _bullet_type)
			is_destroyed = true
		# Hit object
		elif collider.is_in_group("item"):
			# Nudge the object
			var force := _mass * _velocity.length()
			collider.apply_central_impulse(-self.transform.basis.z * force)
			is_destroyed = true
		# Hit something unexpected
		else:
			is_destroyed = true

		# Add bullet spark
		Global.create_bullet_spark(self.global_transform.origin)

	# Update glow
	_glow.update(self.global_transform.origin)

	# Delete the bullet if it is slow
	if distance < 1.0:
		is_destroyed = true

	# Delete the bullet if it has gone its max distance
	_total_distance += distance
	if _total_distance > _max_distance:
		is_destroyed = true

	if is_destroyed:
		self.queue_free()
		_glow._is_parent_bullet_destroyed = true

func start(bullet_type : Global.BulletType) -> void:
	# Get the bullet info from the database
	_bullet_type = bullet_type
	var entry : Dictionary = Global.DB["Bullets"][_bullet_type]
	_mass = entry["mass"]
	_max_distance = entry["max_distance"]
	_speed = entry["speed"]
	_velocity = self.transform.basis.z * _speed

	# Add bullet glow
	_glow = Global._scene_bullet_glow.instantiate()
	Global._world.add_child(_glow)
	_glow.global_transform.origin = self.global_transform.origin
	_glow.start(self)

	_is_setup = true
