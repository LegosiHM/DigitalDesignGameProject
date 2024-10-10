extends Sprite2D

# Variables
var dragging = false
var of = Vector2(0, 0)  # Offset
var original_position = Vector2(0, 0)
var returning = false
var return_speed = 200.0
@export var player_node_path: NodePath  # Path to the player node
@onready var player = get_node(player_node_path)  # Reference to the player node
var velocity = Vector2.ZERO  # Velocity of the platform

func _ready() -> void:
	original_position = global_position

func _process(delta: float) -> void:
	if dragging:
		var new_position = get_global_mouse_position() - of
		velocity = new_position - global_position  # Calculate velocity
		global_position = new_position
		
		# Move player if standing on platform
		if is_player_on_platform():
			player.global_position += velocity  # Move player along with platform

	elif returning:
		global_position = global_position.move_toward(original_position, return_speed * delta)
		if global_position.distance_to(original_position) < 1.0:
			returning = false
			global_position = original_position

func _on_button_button_down() -> void:
	dragging = true
	returning = false
	of = get_global_mouse_position() - global_position

func _on_button_button_up() -> void:
	dragging = false
	returning = true

# Helper function to check if the player is standing on the platform
func is_player_on_platform() -> bool:
	# Assuming the player has a CollisionShape2D and is a CharacterBody2D or similar
	if player and player.is_on_floor():
		var floor_normal = player.get_floor_normal()
		if floor_normal == Vector2.UP:
			var platform_rect = get_rect()
			if platform_rect.has_point(player.global_position):
				return true
	return false
