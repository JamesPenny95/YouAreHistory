extends Control

# Connects all UI scenes to StoryController signals and routes
# VideoStreamPlayer events back to the controller.
#
# DEBUG FALLBACK: when a video file is missing, a coloured placeholder panel
# is shown with the state id as a label. For non-looping states (SCENE,
# CONSEQUENCE) a 5-second timer fires on_video_finished() automatically so
# the state machine keeps running without real video assets.

@onready var video_player: VideoStreamPlayer = $VideoStreamPlayer
@onready var skip_button: Button = $SkipButton
@onready var decision_background: TextureRect = $DecisionBackground
@onready var decision_bar = $DecisionBar
@onready var advisor_sidebar = $AdvisorSidebar
@onready var score_screen = $ScoreScreen
@onready var start_overlay: Control = $StartOverlay
@onready var debug_placeholder: ColorRect = $DebugPlaceholder
@onready var debug_label: Label = $DebugPlaceholder/DebugLabel
@onready var debug_timer: Timer = $DebugTimer
@onready var replay_timer: Timer = $ReplayTimer

const DEBUG_TIMEOUT := 5.0
const VIDEO_ASPECT := 16.0 / 9.0
const PAUSE_ON_UNFOCUS := false

var _resume_video_on_focus: bool = false
var _resume_debug_timer_on_focus: bool = false
var _resume_tree_on_focus: bool = false
var _last_focus_state: bool = true
var _story_started: bool = false
var _awaiting_start_click: bool = true
var _on_final_screen: bool = false


func _set_decision_background(image_path: String) -> bool:
	if image_path == "":
		decision_background.texture = null
		decision_background.visible = false
		return false

	if not ResourceLoader.exists(image_path):
		decision_background.texture = null
		decision_background.visible = false
		return false

	decision_background.texture = load(image_path) as Texture2D
	decision_background.visible = (decision_background.texture != null)
	return decision_background.visible

func _ready() -> void:
	StoryController.state_changed.connect(_on_state_changed)
	StoryController.decision_required.connect(_on_decision_required)
	StoryController.story_finished.connect(_on_story_finished)
	video_player.finished.connect(StoryController.on_video_finished)
	debug_timer.wait_time = DEBUG_TIMEOUT
	debug_timer.one_shot = true
	debug_timer.timeout.connect(StoryController.on_video_finished)
	replay_timer.timeout.connect(_return_to_start_screen)
	skip_button.pressed.connect(_on_skip_pressed)

	advisor_sidebar.visible = false
	score_screen.visible = false
	start_overlay.visible = true
	debug_placeholder.visible = false
	decision_background.visible = false
	decision_bar.set_idle()
	advisor_sidebar.set_idle()
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)
	_last_focus_state = _is_app_focused()
	_layout_overlays()
	_layout_video_area()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout_overlays()
		_layout_video_area()
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_on_app_focus_out()
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_on_app_focus_in()


func _process(_delta: float) -> void:
	if _on_final_screen and score_screen.visible:
		score_screen.update_countdown(replay_timer.time_left, replay_timer.wait_time)

	if not PAUSE_ON_UNFOCUS:
		return

	var focused := _is_app_focused()

	if focused != _last_focus_state:
		if focused:
			_on_app_focus_in()
		else:
			_on_app_focus_out()
		_last_focus_state = focused


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if _awaiting_start_click:
			_begin_story_from_start_screen()
			return
		if _on_final_screen:
			_return_to_start_screen()
			return

	if event is InputEventKey and event.pressed and not event.echo:
		if _awaiting_start_click:
			_begin_story_from_start_screen()
			return
		if _on_final_screen:
			_return_to_start_screen()
			return


func _begin_story_from_start_screen() -> void:
	_awaiting_start_click = false
	_on_final_screen = false
	_story_started = true
	replay_timer.stop()
	start_overlay.visible = false
	score_screen.visible = false
	score_screen.update_countdown(0.0, replay_timer.wait_time)
	StoryController.load_story("healer")


func _return_to_start_screen() -> void:
	replay_timer.stop()
	_on_final_screen = false
	_awaiting_start_click = true
	_story_started = false

	video_player.stop()
	video_player.visible = false
	debug_timer.stop()
	debug_placeholder.visible = false
	decision_background.visible = false
	skip_button.visible = false
	decision_bar.set_idle()
	advisor_sidebar.set_idle()
	score_screen.visible = false
	score_screen.update_countdown(0.0, replay_timer.wait_time)
	start_overlay.visible = true


func _is_app_focused() -> bool:
	var focused := true
	var wnd := get_window()
	if wnd != null:
		focused = wnd.has_focus()

	if OS.has_feature("web"):
		var visibility_state = JavaScriptBridge.eval("document.visibilityState", true)
		var document_has_focus = JavaScriptBridge.eval("document.hasFocus()", true)
		focused = (str(visibility_state) == "visible") and bool(document_has_focus)

	return focused


func _on_app_focus_out() -> void:
	if not PAUSE_ON_UNFOCUS:
		return

	_resume_video_on_focus = false
	_resume_debug_timer_on_focus = false
	_resume_tree_on_focus = false

	if get_tree() != null and not get_tree().paused:
		_resume_tree_on_focus = true
		get_tree().paused = true

	if video_player != null and video_player.visible and video_player.is_playing():
		_resume_video_on_focus = true
		video_player.paused = true

	if debug_timer != null and not debug_timer.is_stopped() and not debug_timer.paused:
		_resume_debug_timer_on_focus = true
		debug_timer.paused = true


func _on_app_focus_in() -> void:
	if not PAUSE_ON_UNFOCUS:
		return

	if get_tree() != null and _resume_tree_on_focus:
		get_tree().paused = false

	if video_player != null and _resume_video_on_focus:
		video_player.paused = false

	if debug_timer != null and _resume_debug_timer_on_focus:
		debug_timer.paused = false

	_resume_video_on_focus = false
	_resume_debug_timer_on_focus = false
	_resume_tree_on_focus = false


func _layout_overlays() -> void:
	if decision_bar != null:
		decision_bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		decision_bar.offset_left = 0.0
		decision_bar.offset_top = 0.0
		decision_bar.offset_right = 0.0
		decision_bar.offset_bottom = 0.0

	if score_screen != null:
		score_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		score_screen.offset_left = 0.0
		score_screen.offset_top = 0.0
		score_screen.offset_right = 0.0
		score_screen.offset_bottom = 0.0

	if start_overlay != null:
		start_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		start_overlay.offset_left = 0.0
		start_overlay.offset_top = 0.0
		start_overlay.offset_right = 0.0
		start_overlay.offset_bottom = 0.0


func _layout_video_area() -> void:
	if video_player == null or debug_placeholder == null:
		return

	var viewport_size: Vector2 = size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return

	var target_size := viewport_size
	if viewport_size.x / viewport_size.y > VIDEO_ASPECT:
		target_size.x = viewport_size.y * VIDEO_ASPECT
	else:
		target_size.y = viewport_size.x / VIDEO_ASPECT

	var pos := (viewport_size - target_size) * 0.5
	video_player.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	video_player.position = pos
	video_player.size = target_size

	debug_placeholder.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	debug_placeholder.position = pos
	debug_placeholder.size = target_size


func _on_state_changed(state: Dictionary) -> void:
	var type_str: String = state.get("type", "").to_upper()
	var preserve_media: bool = (type_str == "DECISION")

	# Stop and hide video if not preserving it for this state.
	if not preserve_media:
		_resume_video_on_focus = false
		_resume_debug_timer_on_focus = false
		_resume_tree_on_focus = false
		replay_timer.stop()
		video_player.stop()
		video_player.visible = false
		debug_placeholder.visible = false
		_set_decision_background("")
		debug_timer.stop()

	advisor_sidebar.visible = false
	score_screen.visible = (type_str == "FINAL")
	_on_final_screen = (type_str == "FINAL")

	if type_str != "DECISION":
		decision_bar.set_idle()
		advisor_sidebar.set_idle()

	skip_button.visible = (type_str == "SCENE")

	if type_str in ["SCENE", "LOOP", "CONSEQUENCE"]:
		if type_str == "LOOP":
			var background_file: String = state.get("background", "")
			if _set_decision_background(background_file):
				video_player.stop()
				video_player.visible = false
				debug_placeholder.visible = false
				return

			video_player.stop()
			video_player.visible = false
			debug_placeholder.visible = false
			_set_decision_background("")

		var video_file: String = state.get("video", "")
		var stream: VideoStream = null
		if video_file != "":
			if ResourceLoader.exists(video_file):
				stream = load(video_file) as VideoStream

		if stream:
			_set_decision_background("")
			video_player.stop()
			video_player.visible = true
			video_player.stream = stream
			video_player.loop = (type_str == "LOOP")
			video_player.play()
		else:
			_set_decision_background("")
			# --- Debug fallback ---
			_show_debug_placeholder(state)
			if type_str != "LOOP":
				debug_timer.start()
			# LOOP states wait indefinitely; the decision bar drives the advance.

	elif type_str == "DECISION":
		decision_background.visible = (decision_background.texture != null)
		pass  # Keep the decision background visible while choices are shown.
	elif type_str != "FINAL":
		video_player.visible = false


func _show_debug_placeholder(state: Dictionary) -> void:
	debug_placeholder.visible = true
	debug_label.text = "[%s]  %s" % [state.get("type", "?"), state.get("id", "?")]
	# Tint by state type so it is easy to tell states apart at a glance.
	match state.get("type", "").to_upper():
		"SCENE":       debug_placeholder.color = Color(0.15, 0.25, 0.45)
		"LOOP":        debug_placeholder.color = Color(0.20, 0.40, 0.20)
		"CONSEQUENCE": debug_placeholder.color = Color(0.45, 0.20, 0.15)
		_:             debug_placeholder.color = Color(0.30, 0.30, 0.30)


func _on_decision_required(prompt: String, options: Array, advisors: Array) -> void:
	decision_bar.setup(prompt, options)
	advisor_sidebar.setup(advisors)


func _on_skip_pressed() -> void:
	# Skip to end of the current SCENE by immediately firing the finished signal.
	# Stop audio first so it doesn't bleed into the next state.
	video_player.stop()
	StoryController.on_video_finished()


func _on_story_finished(score: int, total: int) -> void:
	score_screen.show_score(score, total)
	_on_final_screen = true
	replay_timer.start()
	score_screen.update_countdown(replay_timer.wait_time, replay_timer.wait_time)
