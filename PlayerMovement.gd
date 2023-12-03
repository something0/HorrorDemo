extends CharacterBody3D

@onready var anim_player = $AnimationPlayer
@onready var raycast = $Camera3D/RayCast3D
@onready var crosshair = $Camera3D/weapon/Crosshair
@onready var NormalCamera = $Camera3D
@onready var scopedCamera = $Camera3D/weapon/Camera3D
@onready var currentCamera = $Camera3D
@onready var redHighlight = preload("res://Assets/red.tres")
var beforeRed = []
var sprinting = false
var stamina = 100
var canShoot = true
var speed = 5.0
var jump_velocity = 4.5

var animJustChanged = false

var CameraMove: Vector3
## Increase this value to give a slower turn speed
const CAMERA_TURN_SPEED = 200

var canStand = true
var isCrouching = false
var debug = false
# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = 9.6

var canSprint

func _physics_process(delta):
	var my_group_members = get_tree().get_nodes_in_group("Highlightable")
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if is_on_floor() and Input.is_action_pressed("Sprint") and canSprint == true and stamina > 1:
		Sprint()
		stamina -= 100 * delta
	elif Input.is_action_just_released("Sprint"):
		speed = 5
		jump_velocity = 4.5
		sprinting = false
	
	if stamina == 0:
		canSprint = false
	else:
		canSprint = true
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
	
	if Input.is_action_pressed("Crouch"):
		$CollisionShape3D.shape.height = 1
		self.position.y -= .5
		speed = 2
		isCrouching = true
	elif canStand == true:
		$CollisionShape3D.shape.height = 2
		speed = 5
	else:
		isCrouching = false
	
	if Input.is_action_just_pressed("Debug"):
		debug = true
	if debug == true:
		if Input.is_action_just_released("exitDebug"):
			debug = false
			gravity = 9.6
			speed = 5
		gravity = 0
		speed = 50
		jump_velocity = 0
		if Input.is_action_pressed("jump"):
			position.y += 0.4
		
		if Input.is_action_pressed("CameraZoomOut"):
			$Camera3D.position += Vector3(0,2,3)
		if Input.is_action_pressed("CameraZoomIn"):
			$Camera3D.position -= Vector3(0,2,3)
	
	#plays the aiming version of shoot
	if Input.is_action_just_pressed("Aim") and not anim_player.current_animation == "AimShoot" and not anim_player.current_animation == "shoot":
		canSprint = false
		speed = 2.5
		jump_velocity = 3
		anim_player.play("Aim")
		canShoot = false
		await get_tree().create_timer(2.5).timeout
		canShoot = true
		scopedCamera.make_current()
		currentCamera = scopedCamera
		for i in range(0,my_group_members.size()):
			#my_group_members[i].setredHighlight.albedo_color = Color.RED
			if my_group_members:
				beforeRed.resize(my_group_members.size())
				beforeRed.append(my_group_members[i].get_surface_override_material(0))
				my_group_members[i].set_surface_override_material(0, redHighlight)
	if Input.is_action_just_pressed("shoot") and canShoot == true and currentCamera == scopedCamera:
		anim_player.play("AimShoot")
		shoot()
	
	#plays the idle aninmation when releasing aim
	if not Input.is_action_pressed("Aim")\
		 and not anim_player.current_animation == "shoot" \
			and not anim_player.current_animation == "AimShoot":
		anim_player.play("RESET")
		NormalCamera.make_current()
		currentCamera = NormalCamera
		for i in range(0, my_group_members.size()):
			if beforeRed:
				my_group_members[i].set_surface_override_material(0, beforeRed[i])
				print(beforeRed)
	
	#plays normal shoot animation when not aiming
	if Input.is_action_just_pressed("shoot") and \
		not Input.is_action_pressed("Aim") and \
			not anim_player.current_animation == "AimShoot" and \
				not anim_player.current_animation == "shoot":
		anim_player.play("shoot")
		shoot()
		
	if anim_player.current_animation == "AimShoot":
		crosshair.set_visible(false)
	else:
		crosshair.set_visible(true)
		
	move_and_slide()
	

func look_updown_rotation(rotation = 0):
	"""
	Returns a new Vector3 which contains only the x direction
	We'll use this vector to compute the final 3D rotation later
	"""
	var toReturn = currentCamera.get_rotation() + Vector3(rotation, 0, 0)

	##
	## We don't want the player to be able to bend over backwards
	## neither to be able to look under their arse.
	## Here we'll clamp the vertical look to 90° up and down
	toReturn.x = clamp(toReturn.x, PI / -2, PI / 2)

	return toReturn

func look_leftright_rotation(rotation = 0):
	
	
	"""
	Returns a new Vector3 which contains only the y direction
	We'll use this vector to compute the final 3D rotation later
	"""
	return self.get_rotation() + Vector3(0, rotation, 0)
	
	
	
func _input(event):
	"""
	First person camera controls
	"""
	##
	## We'll only process mouse motion events
	if not event is InputEventMouseMotion:
		return

	##
	## We'll use the parent node "Player" to set our left-right rotation
	## This prevents us from adding the x-rotation to the y-rotation
	## which would result in a kind of flight-simulator camera
	self.set_rotation(look_leftright_rotation(event.relative.x / -CAMERA_TURN_SPEED))

	##
	## Now we can simply set our y-rotation for the camera, and let godot
	## handle the transformation of both together
	currentCamera.set_rotation(look_updown_rotation(event.relative.y / -CAMERA_TURN_SPEED))



func _on_area_3d_body_shape_entered(body_rid, body, body_shape_index, local_shape_index):
	canStand = false


func _on_area_3d_body_shape_exited(body_rid, body, body_shape_index, local_shape_index):
	canStand = true
	if isCrouching == false:
		$CollisionShape3D.shape.height = 2
		speed = 5

func shoot():
	var hit_player = raycast.get_collider()
	if hit_player and hit_player.is_in_group("canDestroy"):
		hit_player.queue_free()


func _on_animation_player_animation_changed(old_name, new_name):
	animJustChanged = true


func Sprint():
	speed = 7
	jump_velocity = 5
	sprinting = true
