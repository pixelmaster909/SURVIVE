extends Control

onready var bar = $TextureRect/ProgressBar
onready var label = $TextureRect/Label

func _ready():
	var player = get_tree().get_nodes_in_group("player")[0]
	
	# Use the variables we defined in Player.gd
	bar.max_value = player.max_health
	bar.value = player.health
	
	player.connect("health_changed", self, "_on_health_changed")
	_update_label(player.health)

func _on_health_changed(new_health):
	bar.value = new_health
	_update_label(new_health)

func _update_label(val):
	var percent = (float(val) / bar.max_value) * 100
	label.text = str(stepify(percent, 1)) + "%"
