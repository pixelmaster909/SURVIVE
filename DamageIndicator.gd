extends Label

func _ready():
	# Setup the animation
	var tween = $Tween
	var target_pos = rect_position + Vector2(rand_range(-20, 20), -50) # Float up and slightly random
	
	# Animate position (Floating up)
	tween.interpolate_property(self, "rect_position", rect_position, target_pos, 0.5, Tween.TRANS_QUART, Tween.EASE_OUT)
	# Animate transparency (Fading out)
	tween.interpolate_property(self, "modulate:a", 1.0, 0.0, 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN, 0.2)
	
	tween.start()
	yield(tween, "tween_all_completed")
	queue_free() # Delete itself when done
