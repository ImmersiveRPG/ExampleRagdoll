# Copyright (c) 2022 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
# This file is licensed under the MIT License
# https://github.com/ImmersiveRPG/ExampleRagdoll

extends Area


export var _name := "Name Tag"
export var _include_name_in_tag := true
export var _is_always_hidden := false

var _is_nametag_shown := false

signal show_nametag
signal hide_nametag

func _ready() -> void:
	$ColorRect/Label.text = "%s" % [_name]

func set_text(value : String) -> void:
	if _include_name_in_tag:
		$ColorRect/Label.text = "%s %s" % [_name, value]
	else:
		$ColorRect/Label.text = "%s" % [value]
	$ColorRect.rect_size = $ColorRect/Label.rect_size

func _process(_delta : float) -> void:
	pass


func _on_screen_exited() -> void:
	if not _is_always_hidden:
		$ColorRect.hide()

func _on_screen_entered() -> void:
	if _is_nametag_shown:
		if not _is_always_hidden:
			$ColorRect.show()

func _on_show_nametag() -> void:
	_is_nametag_shown = true
	if not _is_always_hidden:
		$ColorRect.show()


func _on_hide_nametag() -> void:
	_is_nametag_shown = false
	if not _is_always_hidden:
		$ColorRect.hide()
