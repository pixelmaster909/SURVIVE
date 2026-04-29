extends KinematicBody2D

# --- EXPORT VARIABLES ---
export var attack_max_speed = 50
export var attack_cooldown_time = 0.2

# --- NODES ---
onready var attack_cooldown_timer = $AttackCooldownTimer
onready var jump_particles = $JumpParticles
onready var roll_timer = $RollTimer
onready var dash_duration_timer = $DashDurationTimer
onready var animated_sprite = $AnimatedSprite
onready var stamina_regen_timer = $StaminaRegenTimer
onready var sword_shape = $SwordDashArea/CollisionShape2D
onready var basic_attack_area = $BasicAttackArea
onready var basic_attack_shape = $BasicAttackArea/CollisionShape2D
onready var health_regen_timer = $HealthRegenTimer

# --- VARIABLES ---
var health = 100
var max_health = 100
var health_regen = 1.0
var stamina = 100.0
var max_stamina = 100.0
var stamina_regen = 3.0
var regen_timer = 0.0 # Idrk what this does but might as well keep it just in case it's important
var extra_jumps = 1
var velocity = Vector2.ZERO

var is_rolling = false
var is_blocking = false
var is_dead = false
var is_attacking = false
var can_air_dash = true

var hit_during_this_dash = []

var ui

# --- CONSTANTS --- 
const HEALTH_REGEN_DELAY = 5.0
const REGEN_DELAY = 2.0 # How many seconds to wait before regen starts (this is for stamina cuz im too lazy to rename every thing which has this constant)
const SPEED = 200
const ROLL_SPEED = 400
const ROLL_COOLDOWN = 1.0
const GRAVITY = 800
const JUMP_FORCE = -400

func _ready():
	# This finds the first node in the "interface" group
	ui = get_tree().get_nodes_in_group("interface")[0]
	
func _physics_process(delta):
	# 1. ALWAYS APPLY GRAVITY (Unless we are rolling/dashing)
	if not is_rolling:
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0 # This keeps the dash perfectly horizontal

	# 2. STAMINA REGEN
	if stamina_regen_timer.is_stopped() and stamina < max_stamina and not is_rolling:
		stamina += stamina_regen * delta
		stamina = clamp(stamina, 0, max_stamina)
		
	# 2.5 HEALTH REGEN
	if health_regen_timer.is_stopped() and health < max_health:
		health += health_regen * delta
		health = clamp(health, 0, max_health)
	
	
	# 3. MOVEMENT & INPUT GATE
	var input_dir = 0
	
	if not is_rolling and not is_blocking and not is_attacking:
		if Input.is_action_pressed("right"):
			input_dir += 1
		if Input.is_action_pressed("left"):
			input_dir -= 1
		
		velocity.x = input_dir * SPEED

		if is_on_floor():
			extra_jumps = 1
			can_air_dash = true
			if Input.is_action_just_pressed("jump"):
				velocity.y = JUMP_FORCE
		elif Input.is_action_just_pressed("jump") and extra_jumps > 0:
			if stamina >= 15: # Cost of a double jump
				stamina -= 15
				stamina_regen_timer.start(REGEN_DELAY) 
			
				# MOVE THESE INSIDE THE IF BLOCK:
				velocity.y = JUMP_FORCE
				extra_jumps -= 1
				if jump_particles:
					jump_particles.restart()
				else:
					 print("Not enough stamina to double jump!")

		if Input.is_action_just_pressed("roll") and roll_timer.is_stopped():
			if is_on_floor():
				start_roll()
			elif can_air_dash: # Check if we have an air dash available
				can_air_dash = false
				start_roll()
			
		# Attack input trigger!
		# NEW: Added attack_cooldown_timer.is_stopped()
		if Input.is_action_just_pressed("use") and is_on_floor() and not is_attacking and attack_cooldown_timer.is_stopped():
			start_attack()
		
	# 4. BLOCKING LOGIC
	if Input.is_action_pressed("block") and is_on_floor() and not is_rolling:
		is_blocking = true
		velocity.x = 0 
	else:
		is_blocking = false

	# 5. APPLY EVERYTHING
	# NEW: Hard clamp the x velocity right before applying movement if attacking!
	
	if is_attacking:
		# This uses your new variable for both left and right!
		velocity.x = clamp(velocity.x, -attack_max_speed, attack_max_speed) 
		
	velocity = move_and_slide(velocity, Vector2.UP)
	
	#print("Stamina: ", stepify(stamina, 0.1))
	print("Health: ", stepify(health, 0.1))


	
	# 6. UPDATE VISUALS
	update_animations()

func start_roll():
	if stamina >= 25:
		hit_during_this_dash = [] # Clear the list so we can hit enemies again
		stamina -= 25
		stamina_regen_timer.start(REGEN_DELAY)
		is_rolling = true
		
		# Enable the dash hitbox
		if sword_shape: 
			sword_shape.disabled = false 
		
		dash_duration_timer.start(0.4) 
		roll_timer.start(ROLL_COOLDOWN)
		
		if animated_sprite.flip_h:
			velocity.x = -ROLL_SPEED
		else:
			velocity.x = ROLL_SPEED
		#else:
			#print("Not enough stamina!")

func update_animations():
	# NEW: Stop updating animations if the player is currently attacking!
	if is_attacking:
		animated_sprite.play("attack")
		return
	#print("Current Stamina: ", stamina)
	if not is_blocking: 
		if velocity.x > 0:
			animated_sprite.flip_h = false
			# Move the center just a tiny bit to the right
			$BasicAttackArea/CollisionShape2D.position.x = 20
			$SwordDashArea/CollisionShape2D.position.x = 20
			
		elif velocity.x < 0:
			animated_sprite.flip_h = true
			# Move the center just a tiny bit to the left
			$BasicAttackArea/CollisionShape2D.position.x = -20
			$SwordDashArea/CollisionShape2D.position.x = -20

	if is_rolling:
		animated_sprite.play("roll")
	elif is_blocking:
		animated_sprite.play("block")
	elif not is_on_floor():
		animated_sprite.play("jump")
	elif velocity.x != 0:
		animated_sprite.play("run")
	else:
		animated_sprite.play("idle")

# --- SIGNALS ---

func _on_DashDurationTimer_timeout():
	is_rolling = false
	# Disable the hitbox immediately
	if sword_shape: 
		sword_shape.set_deferred("disabled", true) 
	velocity.x = 0
	hit_during_this_dash = [] # Clear it out for safety
	
func _process(delta):
	# Press 'H' to take 10 damage
	if Input.is_key_pressed(KEY_H):
		take_damage(10)
	
	# Press 'J' to recover 10 health
	if Input.is_key_pressed(KEY_J):
		health += 10
		health = clamp(health, 0, 100)
		ui.update_ui(health, stamina)
	
# Inside Player.gd
func take_damage(amount):
	if is_dead: 
		return
		
	if is_blocking:
		print("Blocked! No damage taken.")
		# Optional: play a "parry" sound or spark effect here
		return 

	health -= amount
	print("Player health: ", health)
	
	if health >= 0:
		health_regen_timer.start(HEALTH_REGEN_DELAY)
	
	if health <= 0:
		is_dead = true
		die()

func die():
	# Stop the player from moving or taking more damage
	set_physics_process(false) 
	animated_sprite.play("death")
	
	# We wait for the signal 'animation_finished' before moving to the next line
	yield(animated_sprite, "animation_finished")
	
	# NOW we reload
	get_tree().reload_current_scene()
	
func start_attack():
	is_attacking = true
	animated_sprite.play("attack")
	
	if basic_attack_shape: 
		basic_attack_shape.disabled = false 
		
	# ⏳ Wait exactly 1 physics frame for the collision to register!
	yield(get_tree(), "physics_frame")
		
	var bodies = basic_attack_area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("enemies") and body.has_method("take_damage"):
			body.take_damage(15) 

	# Wait for the animation to finish
	yield(get_tree().create_timer(0.35), "timeout")
	
	is_attacking = false
	if basic_attack_shape: 
		basic_attack_shape.disabled = true
		
	# Start the cooldown timer so they can't spam instantly!s
	attack_cooldown_timer.start(attack_cooldown_time)


func _on_SwordDashArea_body_entered(body):
# Only do damage if we are actually rolling/dashing
	if is_rolling:
		if body.is_in_group("enemies") and not body in hit_during_this_dash:
			if body.has_method("take_damage"):
				body.take_damage(10) # Your dash damage
				hit_during_this_dash.append(body)
				
				# Optional: Add a little "hit" freeze or screenshake here!
				print("Dashed through enemy!")
			
func _on_hit(damage):
	health -= damage
	ui.update_ui(health, stamina)
