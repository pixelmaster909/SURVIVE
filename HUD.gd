extends CanvasLayer

# Adjust paths to match your node names
onready var health_bar = $"%HealthBar"
onready var stamina_bar = $"%StaminaBar"

func _ready():
	# Set the max values based on player stats
	health_bar.max_value = 100
	stamina_bar.max_value = 100
	
	# Initialize the bars at full
	health_bar.value = 100
	stamina_bar.value = 100

# Call this from your player script
func update_ui(current_hp, current_stamina):
	health_bar.value = current_hp
	stamina_bar.value = current_stamina
