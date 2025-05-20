extends Area2D

func _on_body_entered(body):
	if body.name == "Player":  # Make sure your player node is named "Player"
		# Swap sprites
		##var sprite1 = body.get_node("AnimatedSprite2D_1")
		##var sprite2 = body.get_node("AnimatedSprite2D_2")
		
		##sprite1.visible = false
		##sprite2.visible = true

		# Optionally reset animation
		##sprite2.play("idle")  # Or whatever your default animation is

		# Remove the item from the scene
		queue_free()
