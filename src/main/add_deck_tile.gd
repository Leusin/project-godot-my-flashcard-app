class_name AddDeckTileView
extends Control

signal pressed

@onready var add_button: Button = %AddDeckButton


func _ready() -> void:
	add_button.pressed.connect(func() -> void: pressed.emit())
