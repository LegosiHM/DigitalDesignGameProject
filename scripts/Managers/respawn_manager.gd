extends Node2D

# ------------------------------------------------------------------------------
# RESPAWN SYSTEM CONFIGURATION
# ------------------------------------------------------------------------------

# Stores the position the player should respawn at
var respawn_position: Vector2

# Stores the scene to which the player should be respawned
var respawn_scene: PackedScene

# ------------------------------------------------------------------------------
# SET RESPAWN DATA
# ------------------------------------------------------------------------------

# This function allows setting the respawn location and target scene
# Typically called by a checkpoint or trigger volume
func set_respawn_position(pos: Vector2, scene: PackedScene) -> void:
	respawn_position = pos  # Set the target position for the respawn
	respawn_scene = scene  # Set the target scene the player should be respawned to

# ------------------------------------------------------------------------------
# PERFORM RESPAWN 
# ------------------------------------------------------------------------------

# Handles the actual scene change and moves the player to the desired position
func respawn_player() -> void:
	if respawn_scene:
		# Change the scene to the stored PackedScene
		get_tree().change_scene_to(respawn_scene)

		# Once the scene has loaded, update the player's position
		# NOTE: This will only work correctly if the Player node is named exactly "Player"
		get_tree().current_scene.get_node("Player").global_position = respawn_position
