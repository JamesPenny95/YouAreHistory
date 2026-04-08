extends Control

# Populated via setup(). Displays floating image buttons for the current DECISION state.

@onready var prompt_label: Label = $PromptMargin/PromptLabel
@onready var button_a: TextureButton = $ButtonA
@onready var button_b: TextureButton = $ButtonB
@onready var label_a: Label = $LabelA
@onready var label_b: Label = $LabelB
@onready var label_image_a: TextureRect = $LabelImageA
@onready var label_image_b: TextureRect = $LabelImageB

const BOB_AMPLITUDE := 8.0
const BOB_SPEED := 1.6

var _bob_time: float = 0.0
var _base_button_a_pos: Vector2
var _base_button_b_pos: Vector2


func _ready() -> void:
	button_a.pivot_offset = button_a.custom_minimum_size / 2.0
	button_b.pivot_offset = button_b.custom_minimum_size / 2.0
	button_a.mouse_entered.connect(_on_hover.bind(button_a, true))
	button_a.mouse_exited.connect(_on_hover.bind(button_a, false))
	button_b.mouse_entered.connect(_on_hover.bind(button_b, true))
	button_b.mouse_exited.connect(_on_hover.bind(button_b, false))
	button_a.pressed.connect(_on_choice.bind(0))
	button_b.pressed.connect(_on_choice.bind(1))
	_base_button_a_pos = button_a.position
	_base_button_b_pos = button_b.position
	set_process(true)
	set_idle()


func _process(delta: float) -> void:
	_bob_time += delta
	var a_offset := sin(_bob_time * BOB_SPEED) * BOB_AMPLITUDE
	var b_offset := sin(_bob_time * BOB_SPEED + PI) * BOB_AMPLITUDE
	button_a.position = _base_button_a_pos + Vector2(0.0, a_offset)
	button_b.position = _base_button_b_pos + Vector2(0.0, b_offset)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		var a_offset := sin(_bob_time * BOB_SPEED) * BOB_AMPLITUDE
		var b_offset := sin(_bob_time * BOB_SPEED + PI) * BOB_AMPLITUDE
		_base_button_a_pos = button_a.position - Vector2(0.0, a_offset)
		_base_button_b_pos = button_b.position - Vector2(0.0, b_offset)


func setup(prompt: String, options: Array) -> void:
	prompt_label.text = prompt
	_setup_option_label(0, options[0])
	_setup_option_label(1, options[1])
	_apply_texture(button_a, options[0].get("image", ""))
	_apply_texture(button_b, options[1].get("image", ""))
	button_a.disabled = false
	button_b.disabled = false
	visible = true


func set_idle() -> void:
	prompt_label.text = ""
	label_a.text = ""
	label_b.text = ""
	label_image_a.texture = null
	label_image_b.texture = null
	button_a.texture_normal = null
	button_b.texture_normal = null
	button_a.disabled = true
	button_b.disabled = true
	visible = false


func _apply_texture(btn: TextureButton, image_path: String) -> void:
	if image_path != "" and ResourceLoader.exists(image_path):
		btn.texture_normal = load(image_path)
	else:
		btn.texture_normal = null


func _setup_option_label(index: int, option: Dictionary) -> void:
	var label_node: Label = label_a if index == 0 else label_b
	var label_image_node: TextureRect = label_image_a if index == 0 else label_image_b
	var label_image_path: String = option.get("label_image", "")
	
	if label_image_path != "" and ResourceLoader.exists(label_image_path):
		# Show image, hide text
		label_image_node.texture = load(label_image_path)
		label_image_node.visible = true
		label_node.text = ""
		label_node.visible = false
	else:
		# Show text, hide image
		label_node.text = option.get("label", "")
		label_node.visible = true
		label_image_node.texture = null
		label_image_node.visible = false


func _on_hover(btn: TextureButton, enter: bool) -> void:
	var tween := create_tween()
	tween.tween_property(btn, "scale", Vector2(1.06, 1.06) if enter else Vector2.ONE, 0.12)


func _on_choice(index: int) -> void:
	StoryController.submit_choice(index)
