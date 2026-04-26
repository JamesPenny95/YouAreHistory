extends PanelContainer

# Displays a list of advisors for the current decision. Selecting one shows
# their static response text in a scrollable area below.

@onready var advisor_list: VBoxContainer = $Margin/VBox/AdvisorList
@onready var response_scroll: ScrollContainer = $Margin/VBox/ResponseScroll
@onready var response_label: Label = $Margin/VBox/ResponseScroll/ResponseLabel

var _advisors: Array = []
var _current_decision_id: String = ""


func _ready() -> void:
	StoryController.decision_required.connect(_on_decision_required)
	set_idle()


func setup(advisors: Array) -> void:
	_advisors = advisors
	_current_decision_id = StoryController._last_decision_id
	_rebuild_advisor_buttons()
	# Clear any previously shown response.
	response_scroll.visible = false
	response_label.text = ""


func set_idle() -> void:
	_advisors = []
	_current_decision_id = ""
	for child in advisor_list.get_children():
		child.queue_free()
	response_scroll.visible = false
	response_label.text = ""


func _rebuild_advisor_buttons() -> void:
	# Remove any existing advisor buttons.
	for child in advisor_list.get_children():
		child.queue_free()

	for i in _advisors.size():
		var advisor: Dictionary = _advisors[i]
		var btn := Button.new()
		btn.text = "%s — %s" % [advisor.get("name", ""), advisor.get("role", "")]
		btn.custom_minimum_size = Vector2(0, 52)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(_on_advisor_selected.bind(i))
		advisor_list.add_child(btn)


func _on_advisor_selected(index: int) -> void:
	var advisor: Dictionary = _advisors[index]
	var responses: Dictionary = advisor.get("responses", {})
	response_label.text = responses.get(_current_decision_id, "")
	response_scroll.visible = true


func _on_decision_required(_prompt: String, _options: Array, advisors: Array) -> void:
	setup(advisors)
