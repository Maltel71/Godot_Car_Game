extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

# Use project settings for gravity so it feels like a standard platformer
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
	# If the name is "12345", this sets authority to 12345
	set_multiplayer_authority(name.to_int())

func _physics_process(delta):
	# MULTIPLAYER SAFETY: Stops us from controlling other players' characters
	if not is_multiplayer_authority():
		return

	# Apply Gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Handle horizontal movement with your custom Input Map actions
	var direction = Input.get_axis("walk_left", "walk_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
