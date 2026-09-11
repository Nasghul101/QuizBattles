# uid://cpageclipm3c4
class_name PageClipContainer
extends Control
## Handles horizontal page dragging and animated page navigation.

## Minimum horizontal drag distance required to change pages.
@export var swipe_threshold: float = 100.0
## Delay before a press can begin moving the page container.
@export var swipe_start_delay: float = 0.1
## Duration used when snapping the pages container to a page.
@export var animation_duration: float = 0.3
## Transition curve used by page animations.
@export var animation_transition: Tween.TransitionType = Tween.TRANS_CUBIC
## Easing direction used by page animations.
@export var animation_ease: Tween.EaseType = Tween.EASE_OUT

## Emitted after page layout has been measured and initialized.
signal initialized
## Emitted when a completed swipe selects a target page.
signal swipe_requested(target_page: int)

@onready var pages_container: HBoxContainer = $PagesContainer

var current_page: int = 0
var page_width: float = 0.0
var page_separation: float = 0.0
var swipe_start_pos: Vector2 = Vector2.ZERO
var drag_start_container_pos: float = 0.0
var swipe_start_time: float = 0.0
var is_swipe_pending: bool = false
var is_swiping: bool = false
var is_animating: bool = false


func _ready() -> void:
	# Wait for the control layout before measuring page width and sizing children.
	await get_tree().process_frame
	page_width = size.x
	page_separation = pages_container.get_theme_constant("separation")

	for page: Node in pages_container.get_children():
		if page is Control:
			(page as Control).custom_minimum_size.x = page_width

	pages_container.queue_sort()
	await get_tree().process_frame
	initialized.emit()


func _input(event: InputEvent) -> void:
	# Observe input globally so child buttons can still receive ordinary clicks.
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		if event.pressed:
			if is_animating or not get_global_rect().has_point(event.position):
				return
			swipe_start_pos = event.position
			drag_start_container_pos = pages_container.position.x
			swipe_start_time = Time.get_ticks_msec() / 1000.0
			is_swipe_pending = true
			is_swiping = false
		elif is_swipe_pending:
			var swipe_distance: float = event.position.x - swipe_start_pos.x
			if is_swiping or (_is_swipe_delay_elapsed() and abs(swipe_distance) >= swipe_threshold):
				_handle_swipe_end(event.position)
			is_swipe_pending = false
			is_swiping = false
	elif event is InputEventScreenDrag:
		if is_swipe_pending and not is_animating and _is_swipe_delay_elapsed():
			is_swiping = true
			_update_drag_position(event.position.x - swipe_start_pos.x)
	elif event is InputEventMouseMotion:
		if is_swipe_pending and not is_animating and event.button_mask != 0 and _is_swipe_delay_elapsed():
			is_swiping = true
			_update_drag_position(event.position.x - swipe_start_pos.x)


func _is_swipe_delay_elapsed() -> bool:
	return Time.get_ticks_msec() / 1000.0 - swipe_start_time >= swipe_start_delay


func _update_drag_position(drag_offset: float) -> void:
	var target_pos: float = drag_start_container_pos + drag_offset
	# Keep the first and last pages aligned with the viewport while dragging.
	var min_pos: float = -((page_width + page_separation) * (_get_total_pages() - 1))
	pages_container.position.x = clampf(target_pos, min_pos, 0.0)


func _handle_swipe_end(end_pos: Vector2) -> void:
	var swipe_distance: float = end_pos.x - swipe_start_pos.x
	var target_page: int = current_page

	# A short drag returns to the current page; a qualifying drag changes page.
	if abs(swipe_distance) >= swipe_threshold:
		if swipe_distance > 0:
			target_page -= 1
		else:
			target_page += 1

	target_page = clampi(target_page, 0, _get_total_pages() - 1)
	swipe_requested.emit(target_page)
	animate_to_page(target_page)


func animate_to_page(page_index: int) -> void:
	page_index = clampi(page_index, 0, _get_total_pages() - 1)
	var target_x: float = -(page_width + page_separation) * page_index
	_animate_pages_to(target_x)


func _animate_pages_to(target_x: float) -> void:
	# Keep tween configuration isolated from gesture and page-selection logic.
	is_animating = true
	var tween: Tween = create_tween()
	tween.set_trans(animation_transition)
	tween.set_ease(animation_ease)
	tween.tween_property(pages_container, "position:x", target_x, animation_duration)
	tween.finished.connect(func() -> void: is_animating = false)


func _get_total_pages() -> int:
	return pages_container.get_child_count()
