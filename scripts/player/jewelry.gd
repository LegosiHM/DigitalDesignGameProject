extends Area2D

func _on_body_entered(body):
	body.apply_hj_power()
	queue_free()
