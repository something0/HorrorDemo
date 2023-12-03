extends StaticBody3D

@onready var player = get_node("/root/Node3D/CharacterBody3D")

var target_position
var speed = 200
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	look_at(player.position)
	target_position = (player.position - position).normalized()
	move_and_collide(target_position / speed)
