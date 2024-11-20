extends CharacterBody2D

const SPEED = 50.0
var direction: Vector2 = Vector2.ZERO
var is_alive = true
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	choose_random_direction()
	
func _physics_process(delta: float) -> void:
	if not is_alive:
		return

	# Move in the chosen direction
	velocity = direction * SPEED
	move_and_slide()

	# Play walking animation
	if sprite.animation != "default" and is_alive:
		sprite.play("default")
	
	# Change direction on collision or randomly
	if is_on_wall() or randi() % 100 < 5:
		choose_random_direction()
		

func choose_random_direction():
	# Possible movement directions
	var directions = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]
	var valid_directions = []
	var tile_size = 16  # Replace with your actual tile size

	for dir in directions:
		# Predict position after moving in this direct
		var new_position = global_position + dir * tile_size

		# Check for collisions
		if not is_collision_at_position(new_position):
			valid_directions.append(dir)

	# If no valid directions, stop movemen
	if valid_directions.size() > 0:
		direction = valid_directions[randi() % valid_directions.size()]
	else:
		direction = Vector2.ZERO  # Stop movement if stuck


func is_collision_at_position(position: Vector2) -> bool:
	# Create a query parameter for the position
	var query = PhysicsPointQueryParameters2D.new()
	query.position = position
	query.collision_mask = collision_layer  # Set the appropriate collision mask

	# Perform the query
	var space_state = get_world_2d().direct_space_state
	var result = space_state.intersect_point(query)

	# If there are any collisions, return true
	return result.size() > 0


func die():
	if not is_alive:
		return

	is_alive = false
	velocity = Vector2.ZERO  # Stop movement

	# Play death animation
	sprite.play("die")
	sprite.animation_finished.connect(func():
		queue_free())
