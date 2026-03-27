extends Node

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------
signal state_changed(state: Dictionary)
signal decision_required(prompt: String, options: Array, advisors: Array)
signal story_finished(score: int, total: int)

# ---------------------------------------------------------------------------
# State type enum
# ---------------------------------------------------------------------------
enum StateType { SCENE, LOOP, DECISION, CONSEQUENCE, FINAL }

# ---------------------------------------------------------------------------
# Private state
# ---------------------------------------------------------------------------
# States stored as an OrderedDict-style Array so iteration order is preserved,
# plus a Dictionary for O(1) lookup by name.
var _states_ordered: Array = []       # Array of state Dictionaries in story order
var _states_by_id: Dictionary = {}    # id -> Dictionary
var _advisors: Array = []
var _current_id: String = ""
var _last_decision_id: String = ""

var _score: int = 0
var _total_decisions: int = 0
# Tracks whether the player's first choice at each decision was correct.
# Key: decision state id (String), Value: bool
var _first_choice_correct: Dictionary = {}

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

func load_story(story_id: String) -> void:
	var path := "res://data/stories/%s/story.json" % story_id
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("StoryController: could not open story file at %s" % path)
		return

	var json_text := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(json_text)
	if parsed == null:
		push_error("StoryController: failed to parse story JSON at %s" % path)
		return

	_states_ordered = parsed.get("states", [])
	_states_by_id = {}
	for state in _states_ordered:
		var id: String = state.get("id", "")
		if id == "":
			push_error("StoryController: a state is missing an 'id' field")
			return
		if _states_by_id.has(id):
			push_error("StoryController: duplicate state id '%s'" % id)
			return
		_states_by_id[id] = state

	_advisors = parsed.get("advisors", [])
	_current_id = ""
	_last_decision_id = ""
	_score = 0
	_total_decisions = 0
	_first_choice_correct = {}

	if _states_ordered.is_empty():
		push_error("StoryController: story has no states")
		return
	_advance_to(_states_ordered[0].get("id", ""))


func submit_choice(choice_index: int) -> void:
	# Only valid during a DECISION state.
	var state: Dictionary = _states_by_id.get(_current_id, {})
	if _type_of(state) != StateType.DECISION:
		push_warning("StoryController: submit_choice called outside a DECISION state")
		return

	var is_first_attempt: bool = not _first_choice_correct.has(_current_id)
	var correct_index: int = state.get("correct_option", 0)
	var is_correct: bool = (choice_index == correct_index)

	if is_first_attempt:
		_total_decisions += 1
		_first_choice_correct[_current_id] = is_correct
		if is_correct:
			_score += 1

	if is_correct:
		_advance_to(state.get("next_state", ""))
	else:
		_advance_to(state.get("consequence_state", ""))


func on_video_finished() -> void:
	# Called by main.gd when VideoStreamPlayer emits 'finished'.
	var state: Dictionary = _states_by_id.get(_current_id, {})
	match _type_of(state):
		StateType.SCENE:
			_advance_to(state.get("next_state", ""))
		StateType.CONSEQUENCE:
			_advance_to(state.get("rewind_to", _last_decision_id))
		_:
			pass  # LOOP and DECISION do not auto-advance on video end.


# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

func _advance_to(id: String) -> void:
	if id == "":
		push_error("StoryController: _advance_to called with empty id")
		return
	_current_id = id
	_enter_state(id)


func _enter_state(id: String) -> void:
	if not _states_by_id.has(id):
		push_error("StoryController: unknown state id '%s'" % id)
		return

	var state: Dictionary = _states_by_id[id]
	emit_signal("state_changed", state)

	match _type_of(state):
		StateType.LOOP:
			# The loop video plays while the player decides. Immediately advance
			# to the DECISION state so the decision bar becomes visible.
			# _on_state_changed in main.gd preserves the looping video for DECISION.
			_advance_to(state.get("next_state", ""))
		StateType.DECISION:
			_last_decision_id = id
			emit_signal("decision_required", state.get("prompt", ""), state.get("options", []), _advisors)
		StateType.FINAL:
			emit_signal("story_finished", _score, _total_decisions)


func _type_of(state: Dictionary) -> StateType:
	var type_str: String = state.get("type", "").to_upper()
	match type_str:
		"SCENE":      return StateType.SCENE
		"LOOP":       return StateType.LOOP
		"DECISION":   return StateType.DECISION
		"CONSEQUENCE":return StateType.CONSEQUENCE
		"FINAL":      return StateType.FINAL
		_:
			push_warning("StoryController: unknown state type '%s'" % type_str)
			return StateType.SCENE
