## InputManagerWrapper.gd
## GDScript wrapper around the InputManager C++ Node2D class.
## or directly extend/compose it in your scene tree.
## 
class_name InputManagerWrapper
extends Node


# ---------------------------------------------------------------------------
# Internal reference to the InputManager cpp Singleton 
# ---------------------------------------------------------------------------

## The underlying C++ InputManager node.
var _inputInstance: Object = null

func _ready() -> void:
	process_priority = 100
	process_mode = Node.PROCESS_MODE_ALWAYS

	_inputInstance = Engine.get_singleton("InputManager")
	

func validate_inputInstance()->void:
	if _inputInstance == null:
			_inputInstance =  Engine.get_singleton("InputManager")
			
func _process(_delta: float) -> void:
	_inputInstance._process();

func _input(event: InputEvent) -> void:
	_inputInstance._input(event);
	
func _notification(what):
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_inputInstance.onWindowStopTarget();


# ---------------------------------------------------------------------------
# State queries
# ---------------------------------------------------------------------------

## Returns true while [param action] is held down.
func is_pressed(action: StringName) -> bool:
	validate_inputInstance();
	return _inputInstance.isActionPressed(action);


## Returns true only on the frame [param action] was first pressed.
func is_just_pressed(action: StringName) -> bool:
	validate_inputInstance();
	return _inputInstance.isActionJustPressed(action)


## Returns true only on the frame [param action] was released.
func is_just_released(action: StringName) -> bool:
	validate_inputInstance();
	return _inputInstance.isActionJustReleased(action)


# ---------------------------------------------------------------------------
# Callback registration
# ---------------------------------------------------------------------------

## Register [param callback] to fire every time [param action] is pressed.
## The callable receives no arguments.
func on_press(action: StringName, callback: Callable, allowDuplicate: bool = false) -> void:
	validate_inputInstance();
	_inputInstance.assignOnPress(action, callback, allowDuplicate)


## Register [param callback] to fire every time [param action] is released.
func on_release(action: StringName, callback: Callable, allowDuplicate: bool = false) -> void:
	validate_inputInstance();
	_inputInstance.assignOnRelease(action, callback, allowDuplicate)


## Remove a previously registered press [param callback] for [param action].
func remove_press(action: StringName, callback: Callable) -> void:
	validate_inputInstance();
	_inputInstance.removeOnPress(action, callback)


## Remove a previously registered release [param callback] for [param action].
func remove_release(action: StringName, callback: Callable) -> void:
	validate_inputInstance();
	_inputInstance.removeOnRelease(action, callback)


# ---------------------------------------------------------------------------
# Convenience helpers
# ---------------------------------------------------------------------------

## Register callbacks for both press and release in one call.
## Pass null for either callable to skip it.
func listen(
	action: StringName,
	press_callback: Callable,
	release_callback: Callable
) -> void:
	if press_callback.is_valid():
		on_press(action, press_callback)
	if release_callback.is_valid():
		on_release(action, release_callback)


## Unregister both press and release callbacks in one call.
func unlisten(
	action: StringName,
	press_callback: Callable,
	release_callback: Callable
) -> void:
	if press_callback.is_valid():
		remove_press(action, press_callback)
	if release_callback.is_valid():
		remove_release(action, release_callback)


## Returns a dictionary snapshot of the current press state for
func state_snapshot(actions: Array[StringName]) -> Dictionary:
	var snapshot := {}
	for action in actions:
		snapshot[action] = {
			"pressed":       is_pressed(action),
			"just_pressed":  is_just_pressed(action),
			"just_released": is_just_released(action),
		}
	return snapshot
