extends Area2D

export var speed = 600
var direction = Vector2.RIGHT

func _physics_process(delta):
	position += direction * speed * delta

func _on_VisibilityNotifier2D_screen_exited():
	queue_free() # Deletes bullet when it leaves screen

func _on_Arrow_body_entered(body):
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.take_damage(10)
		print("meow")
	queue_free() # Destroy bullet on impact
