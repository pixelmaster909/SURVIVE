extends Control

onready var bar = $TextureRect/ProgressBar 
onready var label = $TextureRect/Label 

func _ready():
	var player = get_tree().get_nodes_in_group("player")[0]
	
	bar.max_value = player.max_stamina
	bar.value = player.stamina
	
	player.connect("stamina_changed", self, "_on_stamina_changed")
	_update_label(player.stamina)

func _on_stamina_changed(new_stamina):
	bar.value = new_stamina
	_update_label(new_stamina)

func _update_label(val):
	var percent = (float(val) / bar.max_value) * 100
	label.text = str(stepify(percent, 1)) + "%"
