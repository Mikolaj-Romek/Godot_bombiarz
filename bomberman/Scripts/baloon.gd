extends CharacterBody2D

const SPEED = 50.0
var direction: Vector2 = Vector2.ZERO
var is_alive = true
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
var change_direction_timer = 0.0
const DIRECTION_CHANGE_TIME = 3.0  # Change direction every 3 seconds

func _ready():
	add_to_group("player")
	choose_random_direction()
	
func _physics_process(delta: float) -> void:
	if not is_alive:
		return

	# Timer for direction changes
	change_direction_timer += delta
	if change_direction_timer >= DIRECTION_CHANGE_TIME:
		choose_random_direction()
		change_direction_timer = 0.0

	# Move in the chosen direction
	velocity = direction * SPEED
	
	# Test movement before applying it
	var collision = move_and_collide(velocity * delta, true) # Test only
	if collision:
		# If we would collide, try to find a new valid direction
		choose_random_direction_avoiding_collision()
	else:
		# Actually move if no collision would occur
		move_and_slide()

	# Play walking animation
	if sprite.animation != "default" and is_alive:
		sprite.play("default")

func choose_random_direction():
	var directions = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]
	direction = directions[randi() % directions.size()]

func choose_random_direction_avoiding_collision():
	var directions = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]
	directions.shuffle()  # Randomize the order
	
	for dir in directions:
		# Test each direction
		var test_velocity = dir * SPEED
		var collision = move_and_collide(test_velocity * 0.1, true)  # Test with a small movement
		if not collision:
			direction = dir
			return
			
	# If no direction is free, stop
	direction = Vector2.ZERO

func die():
	if not is_alive:
		return

	is_alive = false
	velocity = Vector2.ZERO

	sprite.play("die")
	sprite.animation_finished.connect(func():
		queue_free())
