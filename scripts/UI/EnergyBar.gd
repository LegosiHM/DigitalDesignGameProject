extends Control

@onready var player = get_tree().current_scene.get_node("Player")
@onready var energy_bar = $TextureProgressBar

func _ready():
	if player:
		energy_bar.max_value = player.max_energy
		energy_bar.value = player.current_energy

func _process(_delta):
	if player:
		energy_bar.value = player.current_energy
