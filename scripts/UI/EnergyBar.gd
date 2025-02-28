extends Control

@export var player_node_path: NodePath  # Set this in the inspector to the Player node
@onready var player = get_node(player_node_path) if player_node_path else null

@onready var energy_bar = $TextureProgressBar

func _ready():
	if player:
		energy_bar.max_value = player.max_energy
		energy_bar.value = player.current_energy

func _process(_delta):
	if player:
		energy_bar.value = player.current_energy
