extends Camera3D

@export var pan_sensitivity: float = 0.01   # world units per pixel of swipe
@export var min_x: float = -20.0
@export var max_x: float = 20.0

var startPos: Vector2 = Vector2.ZERO
var endPos: Vector2 = Vector2.ZERO
var lastFramePos: Vector2 = Vector2.ZERO
var swipeLength: float = 0.0

var mouseDown: bool = false
var mouseDownLastFrame: bool = false

func _ready() -> void:
	G_InputWrapper.on_press("mouse_pressed", set_mouse_down)
	G_InputWrapper.on_release("mouse_pressed", set_mouse_up)

func set_mouse_down(_name) -> void:
	mouseDown = true
	startPos = get_viewport().get_mouse_position()
	endPos = startPos
	lastFramePos = startPos
	swipeLength = 0.0

func set_mouse_up(_name) -> void:
	mouseDown = false

func _process(delta: float) -> void:
	if mouseDown:
		endPos = get_viewport().get_mouse_position()

		var frame_delta_x := endPos.x - lastFramePos.x
		lastFramePos = endPos

		# swipe right -> camera moves right; flip sign if you want the opposite feel
		var new_x := global_position.x + frame_delta_x * pan_sensitivity
		new_x = clamp(new_x, min_x, max_x)
		global_position.x = new_x

		swipeLength = (endPos - startPos).length()
		mouseDownLastFrame = true
	elif mouseDownLastFrame:
		mouseDownLastFrame = false
		startPos = Vector2()
		endPos = Vector2()
		swipeLength = 0.0
