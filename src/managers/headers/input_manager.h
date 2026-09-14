/**
 * Evan Hughes
 *
 * Goal:
 *  Develop an input callback manager for scripts to subscribe to action events.
 */
#ifndef INPUT_MANAGER_H
#define INPUT_MANAGER_H

#include <godot_cpp/classes/input_event_key.hpp>
#include <godot_cpp/variant/callable.hpp>
#include <godot_cpp/classes/input.hpp>

#include "definitions.h"

#include <unordered_map>
#include <vector>

using InputEvent = godot::InputEvent;
using Input = godot::Input;

typedef std::unordered_map<StringName, bool, StringNameHash, StringNameEqual> KeyboardState;
typedef std::unordered_map<StringName, std::vector<Callable>, StringNameHash, StringNameEqual> CallbackFunctionsMap;

class InputManager : public Object
{
    GDCLASS(InputManager, Object)

protected:
    static void _bind_methods();

private:
    // Replaced manual raw dynamic array with std::vector to guarantee exception safety and zero memory leaks
    std::vector<StringName> m_vImportantActions;

    KeyboardState m_mCurrentPressedActions;
    KeyboardState m_mLastPressedActions;

    CallbackFunctionsMap m_mOnPress;
    CallbackFunctionsMap m_mOnRelease;
    std::vector<Callable> m_vOnMouseMove;

    // Staging maps for deferring additions mid-frame safely
    CallbackFunctionsMap m_mOnPressAdd;
    CallbackFunctionsMap m_mOnReleaseAdd;
    std::vector<Callable> m_vOnMouseMoveAdd;

    std::vector<StringName> m_vChangedActions;
    godot::Vector2 m_vMousePosLastFrame;

    bool m_bfirstFramePast = false;

    /// @brief Check if a callback is already present in a vector
    bool containsCallback(const std::vector<Callable> &searchVector, const Callable &searchCall) const;

    /// @brief Reset all tracked inputs to non-pressed state
    void clearKeyboardState(bool callFunction = false);

    /// @brief Safely dispatch callback functions for a specific action name
    void callFunctions(const StringName &action, bool isActionPressed);

    void eraseCallback(const Callable &callbackFunc, std::vector<Callable> &vec);

public:
    InputManager();
    ~InputManager();

    // Frame updates
    void _input(const Ref<InputEvent> &event);
    void _process(const godot::Vector2 &mousePos, const float &delta);

    // State Accessors (marked const to prevent unintended mutations during query)
    bool isActionPressed(const StringName &action) const;
    bool isActionJustPressed(const StringName &action) const;
    bool isActionJustReleased(const StringName &action) const;

    // Subscription controls
    void assignOnPress(const StringName &action, const Callable &callbackFunc, bool allowMult = false);
    void assignOnRelease(const StringName &action, const Callable &callbackFunc, bool allowMult = false);
    void assignOnMouseMove(const Callable &callbackFunc, bool allowMult = false);
    void removeOnPress(const StringName &action, const Callable &callbackFunc);
    void removeOnRelease(const StringName &action, const Callable &callbackFunc);
    void removeOnMouseMove(const Callable &callbackFunc);

    void onWindowStopTarget();
};

#endif // INPUT_MANAGER_H