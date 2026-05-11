extends CanvasLayer

var survival_time = 0.0 # This is our stopwatch

func _process(delta):
	# Only count time if the game is actually running
	if not get_tree().paused:
		survival_time += delta

func show_death_screen(kills):
	self.show()
	get_tree().paused = true
	
	# 1. Find the Time Label (Make sure name matches exactly!)
	var time_label = find_node("FinalTimeLabel", true, false)
	if time_label:
		time_label.text = "Time Survived: " + str(int(survival_time)) + "s"
	
	# 2. Find the Kills Label
	var kill_label = find_node("FinalKillsLabel", true, false)
	if kill_label:
		kill_label.text = "Enemies Defeated: " + str(kills)

func _on_restart_pressed():
	#get_tree().paused = false
	#get_tree().reload_current_scene()
	pass


func _on_RestartButton_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()
