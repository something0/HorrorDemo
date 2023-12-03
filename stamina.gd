extends ProgressBar

@onready var player = get_node("/root/Node3D/CharacterBody3D")
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	if player.sprinting == false:
		await get_tree().create_timer(3).timeout
		player.stamina += 100 * delta
		
	if player.stamina > 100:
		player.stamina = 100
	if player.stamina < 0:
		player.stamina = 0
	
	print(player.stamina)
	self.value = player.stamina
