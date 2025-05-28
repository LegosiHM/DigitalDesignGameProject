extends Control

# ------------------------------------------------------------------------------
# NODE REFERENCES
# ------------------------------------------------------------------------------

# Reference to the player node in the current scene
@onready var player = get_tree().current_scene.get_node("Player")

# Reference to the energy UI bar
@onready var energy_bar = $TextureProgressBar

# ------------------------------------------------------------------------------
# READY FUNCTION: Initialize energy bar when the scene is ready
# ------------------------------------------------------------------------------

func _ready():
	if player:
		# Set energy bar's maximum value based on player's max energy
		energy_bar.max_value = player.max_energy
		# Set current value to player's current energy
		energy_bar.value = player.current_energy

# ------------------------------------------------------------------------------
# PROCESS FUNCTION: Update the bar's value every frame
# ------------------------------------------------------------------------------

func _process(_delta):
	if player:
		# Continuously update energy bar to match player's current energy
		energy_bar.value = player.current_energy
