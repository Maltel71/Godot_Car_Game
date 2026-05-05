extends "res://scripts/shop_menu.gd"

@onready var security_badge_button: Button = $Panel/GridContainer/SecurityBadge
@onready var security_badge_locked: TextureRect = $Panel/GridContainer/SecurityBadge/Locked

func _ready():
	super._ready()
	security_badge_button.pressed.connect(_on_security_badge_pressed)
	_update_badge_state()

func _update_badge_state():
	var manager = get_node("/root/ScoreAndTimeManager")
	security_badge_locked.visible = manager.get_star_rating() < 5 and not manager.has_special_badge
	security_badge_button.disabled = manager.has_special_badge

func _on_security_badge_pressed():
	var manager = get_node("/root/ScoreAndTimeManager")
	if manager.get_star_rating() >= 5:
		manager.has_special_badge = true
		_update_badge_state()
