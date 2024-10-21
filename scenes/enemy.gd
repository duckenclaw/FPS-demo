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
	anim_player.speed_scale = 1
	attack_timer.stop()
	if anim_player.current_animation == "Hit" or anim_player.current_animation == "Punch":
		anim_player.stop()
		hitbox.monitoring = false
	anim_player.play("Hit")
	print(self.name + " took " + str(damage) + " damage")
	print("HP: " + str(hp) + " - " + str(damage) + " = " + str(hp - damage))
	hp = hp - damage
	print("HP: " + str(hp) + "/" + str(MAX_HP))
	if hp <= 0:
		print("Died")
		hp = 0


func _on_animation_finished(anim_name):
	if anim_name == "Hit" or anim_name == "Punch":
		attack_timer.start()
		attack_timer.wait_time = attack_time # reset attack
		anim_player.play("Idle")
		anim_player.speed_scale = 1


func _on_attack_timer_timeout():
	anim_player.play("Punch")


func _on_hitbox_body_entered(body):
	print(body)
	if body.is_in_group("player"):
		if body.is_blocking:
			anim_player.speed_scale = 0.25
			print("Blocked")
		else:
			body.take_damage(DAMAGE)
