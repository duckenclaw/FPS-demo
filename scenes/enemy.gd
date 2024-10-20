extends Area3D

const MAX_HP: int = 100
const DAMAGE: int = 25

var hp: int

@export var attack_time:float = 2.0

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var hitbox: Area3D = $Hitbox
@onready var attack_timer: Timer = $AttackTimer

# Called when the node enters the scene tree for the first time.
func _ready():
	hp = MAX_HP

func take_damage(damage):
	anim_player.play("Hit")
	attack_timer.wait_time = attack_time # reset attack
	print(self.name + " took " + str(damage) + " damage")
	print("HP: " + str(hp) + " - " + str(damage) + " = " + str(hp - damage))
	hp = hp - damage
	print("HP: " + str(MAX_HP) + "/" + str(hp))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_animation_finished(anim_name):
	if anim_name == "Hit" or anim_name == "Punch":
		anim_player.play("Idle")


func _on_attack_timer_timeout():
	anim_player.play("Punch")
	hitbox.monitoring = true


func _on_hitbox_body_entered(body):
	print(body)
	if body.is_in_group("player"):
		body.take_damage(DAMAGE)
