extends KinematicBody2D

export var speed = 250
export var jump_force = -400
export var gravity = 800
export var max_health = 100

# Add the exact names of your animations here!
var attack_animations = ["attack", "attack2"]
var health = max_health
var velocity = Vector2.ZERO
var knockback = Vector2.ZERO # knockback velocity thing

var is_attacking = false
var is_dead = false
var is_hurt = false

onready var flip_container = $FlipContainer
onready var sprite = $FlipContainer/AnimatedSprite
onready var wall_sensor = $FlipContainer/WallSensor
onready var player = get_tree().get_nodes_in_group("player")[0] if get_tree().get_nodes_in_group("player").size() > 0 else null
onready var axe_area = $FlipContainer/AxeAttackArea

func _ready():
	randomize() 

func _physics_process(delta):
	if player == null:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0: player = players[0]
		return
		
	if is_dead or is_hurt:
		return

	# 1. Gravity
	velocity.y += gravity * delta
	
	# 2. Movement Logic
	var direction_x = sign(player.global_position.x - global_position.x)
	var distance_to_player = global_position.distance_to(player.global_position)

	# Stop moving if attacking or close to the player
	if distance_to_player > 40 and not is_attacking:
		 velocity.x = direction_x * speed
	else:
		 velocity.x = 0 
	
	# 3. Continuous Attack Check
	if not is_attacking:
		var bodies = axe_area.get_overlapping_bodies()
		for body in bodies:
			if body.is_in_group("player"):
				trigger_attack(body, direction_x) # Pass direction to fix flipping
				break 
	
	# 4. Jumping
	wall_sensor.cast_to = Vector2(direction_x * 50, 0)
	if is_on_floor() and wall_sensor.is_colliding():
		velocity.y = jump_force
	
		if abs(velocity.x) < 5:
			velocity.x = 0

	velocity = move_and_slide(velocity, Vector2.UP)
	update_animations(direction_x)
	
func update_animations(direction_x):
	if is_attacking:
		return 

	# Flip the entire container (Sprite, Sensor, and Attack Area at once!)
	if direction_x > 0:
		flip_container.scale.x = 1
	elif direction_x < 0:
		flip_container.scale.x = -1

	# Play animations normally
	if not is_on_floor():
		sprite.play("jump")
	elif abs(velocity.x) > 0:
		sprite.play("run")
	else:
		sprite.play("idle")

# Updated attack logic
func trigger_attack(target_body, direction_x):
	#print("IT WAS THE PLAYER!")
	is_attacking = true
	
	# FIX 2: Lock his looking direction immediately to prevent getting stuck in "run"
	if direction_x > 0:
		flip_container.scale.x = 1
	elif direction_x < 0:
		flip_container.scale.x = -1
	
	# FIX 1: True randomization by shuffling the array!
	attack_animations.shuffle()
	var chosen_attack = attack_animations[0]
	
	sprite.play(chosen_attack)
	
	if target_body.has_method("take_damage"):
		target_body.take_damage(5)

# This resets the attack so the orc can move or attack again
func _on_AnimatedSprite_animation_finished():
	if sprite.animation in attack_animations:
		is_attacking = false 
	
# Keep the signal as a backup in case the player dashes inside quickly
func _on_AxeAttackArea_body_entered(body):
	if player:
		var direction_x = sign(player.global_position.x - global_position.x)
		if body.is_in_group("player") and not is_attacking:
			trigger_attack(body, direction_x)
			
func apply_knockback(hit_dir):
	# Sends player flying: hit_dir (1 or -1) * strength, and a little upwards (-300)
	knockback = Vector2(hit_dir * 1180, -30)
	# We add (velocity + knockback) so both movement and hit force happen at once
	velocity = move_and_slide(velocity + knockback, Vector2.UP)

	# This friction line slowly brings the knockback force back to zero
	knockback = lerp(knockback, Vector2.ZERO, 0.2)
	pass

func take_damage(amount):
	if is_dead: 
		return
		
	print("Enemy took damage! Amount: ", amount)
	health -= amount
	
	if health > 0:
		is_hurt = true
		is_attacking = false 
		sprite.play("hurt") 
		
		yield(get_tree().create_timer(0.2), "timeout")
		is_hurt = false
	else:
		die()

func die():
	is_dead = true
	set_physics_process(false) 
	
	collision_layer = 0
	collision_mask = 0
	
	sprite.play("death") 
	
	yield(sprite, "animation_finished")
	queue_free()
