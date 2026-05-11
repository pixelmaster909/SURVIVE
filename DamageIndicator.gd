extends Label

onready var tween = $Tween

func _ready():
	# Final position is current position + up 50 pixels
	var target_pos = rect_position + Vector2(0, -50)
	
	# 1. Float up
	tween.interpolate_property(self, "rect_position", rect_position, target_pos, 0.4, Tween.TRANS_QUART, Tween.EASE_OUT)
	# 2. Fade out
	tween.interpolate_property(self, "modulate:a", 1.0, 0.0, 0.4, Tween.TRANS_LINEAR, Tween.EASE_IN, 0.2)
	
	tween.start()
	yield(tween, "tween_all_completed")
	queue_free()
