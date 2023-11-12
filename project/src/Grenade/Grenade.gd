# Copyright (c) 2021-2023 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
# This file is licensed under the MIT License
# https://github.com/ImmersiveRPG/ExampleRagdoll

extends RigidBody3D


@onready var _ray : ShapeCast3D = $ShapeCast3D
var _prev_origin := Vector3.INF
var _is_shape_casting := true
var _is_started := false
var _is_red := false

func start(origin : Vector3, impulse : Vector3) -> void:
	self.global_transform.origin = origin
	_prev_origin = origin
	self.set_is_shape_casting(true)
	self.apply_central_impulse(impulse)
	_is_started = true

func _physics_process(delta : float) -> void:
	if not _is_started: return

	var dis := self.global_transform.origin.distance_to(_prev_origin)
	#print([dis, self.global_transform.origin.length(), _prev_origin.length()])
	#if dis >= 0.5 and _ray.enabled:
	if _ray.enabled:
		_ray.global_transform.origin = _prev_origin
		_ray.target_position = Vector3(0, 0, -dis)
		Global.safe_look_at(_ray, self.global_transform.origin)
		_ray.force_shapecast_update()
		if _ray.is_colliding():
			for i in _ray.get_collision_count():
				var coll := _ray.get_collider(i)
				var point := _ray.get_collision_point(i)
				var direction := point - self.global_transform.origin
				self.emit_signal("body_entered", coll, direction)
				self.global_transform.origin = point
				#self.freeze = true
				#print(coll)

		_prev_origin = self.global_transform.origin

func set_is_shape_casting(value : bool) -> void:
	_is_shape_casting = value

	$CollisionShape3D.disabled = _is_shape_casting
	$ShapeCast3D.enabled = _is_shape_casting

func _on_body_entered(body, direction := Vector3.INF) -> void:
	#print(["_on_body_entered", body, direction])
	if direction != Vector3.INF and _is_shape_casting and body.has_method("apply_central_impulse"):
		#print(body)
		var mass := self.mass
		var vel := self.linear_velocity.length()
		var angle := -direction
		var force := mass * vel
		body.apply_central_impulse(force * angle)

	self.set_is_shape_casting(false)


func _on_timer_boom_timeout() -> void:
	# Add explosion
	var explosion_scene : PackedScene = ResourceLoader.load("res://src/Explosion/Explosion.tscn")
	var explosion := explosion_scene.instantiate()
	Global._world.add_child(explosion)
	explosion.global_transform.origin = self.global_transform.origin
	explosion.start()

	# Add fire
	var fire_scene : PackedScene = ResourceLoader.load("res://src/Effects/Fire/Fire.tscn")
	var fire := fire_scene.instantiate()
	Global._world.add_child(fire)
	fire.global_transform.origin = self.global_transform.origin

	self.queue_free()


func _on_timer_flash_timeout() -> void:
	_is_red = not _is_red

	$OmniLight3D.visible = _is_red
	$CollisionShape3D/MeshInstanceNormal.visible = not _is_red
	$CollisionShape3D/MeshInstanceRed.visible = _is_red
