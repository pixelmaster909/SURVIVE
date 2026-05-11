extends Label

var score = 0.0

func _process(delta):
	# Only increase score if the player is still alive (not paused)
	if not get_tree().paused:
		score += delta
		text = "Time Survived: " + str(int(score))
