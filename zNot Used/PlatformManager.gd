extends Node

# ------------------------------------------------------------------------------
# PLATFORM HOLDER / REFERENCE MANAGER
# ------------------------------------------------------------------------------

# This variable stores a reference to the currently assigned platform node.
var platform: Node = null


# ------------------------------------------------------------------------------
# PUBLIC FUNCTION: Set Platform Reference
# ------------------------------------------------------------------------------

# Called to assign a platform node to this object.
# This can be used to track what platform a player or object is standing on.
func set_platform(platform_node: Node) -> void:
	platform = platform_node
	print("Platform set to: ", platform)


# ------------------------------------------------------------------------------
# PUBLIC FUNCTION: Get Platform Reference
# ------------------------------------------------------------------------------

# Returns the currently stored platform node.
# Logs the platform for debugging. Warns if it's null.
func get_platform() -> Node:
	if platform:
		print("Platform retrieved: ", platform)
	else:
		print("Platform is null!")
	return platform
