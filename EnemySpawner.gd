extends Node2D

# 1. Drag your orc scene file from your file system into this slot in the Inspector!
export(PackedScene) var enemy_scene

onready var floor_finder = $RayCast2D
onready var spawn_timer = $SpawnTimer
onready var player = get_tree().get_nodes_in_group("player")[0] if get_tree().get_nodes_in_group("player").size() > 0 else null

export var spawn_radius = 600 # This distance places them safely off-camera

func _ready():
	spawn_timer.connect("timeout", self, "_on_SpawnTimer_timeout")

func _on_SpawnTimer_timeout():
	if player == null: return
	
	# 1. Pick a random X position to the left or right
	var spawn_x = player.global_position.x + (spawn_radius * (1 if randf() > 0.5 else -1))
	
	# 2. Position Raycast way above that X point
	floor_finder.global_position = Vector2(spawn_x, player.global_position.y - 300)
	floor_finder.cast_to = Vector2(0, 600) # Point straight down
	floor_finder.force_raycast_update() # Update math immediately
	
	if floor_finder.is_colliding():
		var spawn_pos = floor_finder.get_collision_point()
		
		var new_enemy = enemy_scene.instance()
		# Offset the Y slightly so the enemy's feet aren't *inside* the collision point
		new_enemy.global_position = spawn_pos - Vector2(0, 10) 
		get_tree().current_scene.add_child(new_enemy)
