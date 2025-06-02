extends HBoxContainer

@export var action: String = "Unassigned"

@onready var action_name = $Name
@onready var action_hotkey = $Hotkey

# Called when the node enters the scene tree for the first time.
func _ready():
	set_process_unhandled_key_input(false) # disable key monitoring, so that it turns on only when rebinding an action
	set_action_name()
	set_action_hotkey()

# set label of the action to the name of the action
func set_action_name():
	action_name.text = action

# set text of the rebind button to the hotkey
func set_action_hotkey():
	var action_event = InputMap.action_get_events(action)[0]
	var action_keycode = OS.get_keycode_string(action_event.physical_keycode)
	
	action_hotkey.text = "%s" % action_keycode

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_hotkey_rebind_toggled(toggled_on):
	if toggled_on:
		action_hotkey.text = "..."
		set_process_unhandled_key_input(toggled_on)
		
		for i in get_tree().get_nodes_in_group("RebindContainer"):
			if i.action != self.action:
				i.action_hotkey.toggle_mode = false
				i.set_process_unhandled_key_input(false)
	else:
		
		for i in get_tree().get_nodes_in_group("RebindContainer"):
			if i.action != self.action:
				i.action_hotkey.toggle_mode = true
				i.set_process_unhandled_key_input(false)
		
		set_action_hotkey()

func _unhandled_key_input(event):
	rebind_action_hotkey(event)
	action_hotkey.button_pressed = false
	
func rebind_action_hotkey(event):
	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, event)
	
	set_process_unhandled_key_input(false)
	set_action_name()
	set_action_hotkey()
