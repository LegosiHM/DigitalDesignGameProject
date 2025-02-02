extends Node

var platform: Node = null

func set_platform(platform_node: Node) -> void:
	platform = platform_node
	print("Platform set to: ", platform)

func get_platform() -> Node:
	if platform:
		print("Platform retrieved: ", platform)
	else:
		print("Platform is null!")
	return platform
