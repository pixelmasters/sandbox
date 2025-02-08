extends Node2D

@onready var qte_sprite: AnimatedSprite2D = $"qte-sprite"  # Reference to QTE animation sprite
@onready var player: CharacterBody2D = get_tree().get_first_node_in_group("player")

var radius: float = 100  # Starting radius
var target_radius: float = 10  # Minimum radius before stopping
var shrinking_speed: float = 50  # Speed of shrinking per second
var is_shrinking: bool = false  # Controls whether the circle is active

var hit_radius_range: float = 15  # Acceptable range for a "good hit"
var hit_registered: bool = false  # Prevents duplicate hit registrations

var correct_input: String = ""  # Stores the correct input
var start_radius: float = 100  # To keep track of full range for scaling
var total_frames: int = 1  # Number of frames in the animation

func start_qte():
    if is_shrinking:
        return  # Prevents multiple QTEs from triggering at the same time

    is_shrinking = true
    hit_registered = false  # Reset hit detection
    radius = start_radius  # Reset circle size

    # Freeze player
    player.velocity = Vector2.ZERO
    player.set_physics_process(false)
    player.set_idle_anim()  # Ensure player doesn't get stuck in walking anim

    # Choose a random correct input (UP, DOWN, LEFT, RIGHT)
    var directions = ["UP", "DOWN", "LEFT", "RIGHT"]
    correct_input = directions[randi() % directions.size()]
    print("Correct Input:", correct_input)

    # Set the QTE sprite to match the correct input
    qte_sprite.animation = correct_input
    qte_sprite.visible = true
    qte_sprite.frame = 0
    qte_sprite.play()

    # Get total frames in animation
    total_frames = qte_sprite.sprite_frames.get_frame_count(qte_sprite.animation)

    set_process(true)  # Enable _process() loop

func _process(delta):
    if is_shrinking and radius > target_radius:
        radius -= shrinking_speed * delta  # Reduce circle size over time

        # 🔥 Sync QTE animation frame with circle size
        var progress = (radius - target_radius) / (start_radius - target_radius)
        qte_sprite.frame = int(lerp(0, total_frames - 1, progress))

        # 🔥 Check for player input
        if Input.is_action_just_pressed("ui_" + correct_input.to_lower()):
            check_hit()

        # 🔥 Stop shrinking and trigger fail if player doesn't press in time
        if radius <= target_radius:
            radius = target_radius
            is_shrinking = false
            if not hit_registered:
                qte_fail()  # Player missed the input window

        update()  # Redraw the circle

func check_hit():
    if abs(radius - target_radius) <= hit_radius_range:
        qte_success()  # Player hit within the right range
    else:
        qte_fail()  # Hit outside the acceptable range

func qte_success():
    print("✅ QTE Success!")  # Debugging message
    is_shrinking = false
    hit_registered = true  # Prevent multiple hits
    qte_sprite.visible = false  # Hide QTE sprite
    player.set_physics_process(true)  # Re-enable movement

func qte_fail():
    print("❌ QTE Failed!")  # Debugging message
    is_shrinking = false
    qte_sprite.visible = false  # Hide QTE sprite
    player.set_physics_process(true)  # Re-enable movement

func _draw():
    # Draw the shrinking circle
    draw_circle(Vector2.ZERO, radius, Color(1, 0, 0, 0.5))
