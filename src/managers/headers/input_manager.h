#ifndef INPUT_MANAGER_H
#define INPUT_MANAGER_H

#include <godot_cpp/classes/input_event_key.hpp>
#include <godot_cpp/variant/callable.hpp>
#include <godot_cpp/classes/input.hpp>

#include "definitions.h"

#include <unordered_map>
#include <vector>

constexpr int ImportantKeyCount = 4;

typedef std::unordered_map<StringName, bool, StringNameHash, StringNameEqual> KeyboardState;
typedef std::unordered_map<StringName, std::vector<Callable>, StringNameHash, StringNameEqual> CallbackFunctionsMap;
using Input = godot::Input;
#define InputEvent godot::InputEvent

class InputManager : public Object
{
    GDCLASS(InputManager, Object)
protected:
    static void _bind_methods()
    {
        bind_method(D_METHOD("_process"), &InputManager::_process);
        bind_method(D_METHOD("_input", "event"), &InputManager::_input);

        bind_method(D_METHOD("isActionPressed", "action"), &InputManager::isActionPressed);
        bind_method(D_METHOD("isActionJustPressed", "action"), &InputManager::isActionJustPressed);
        bind_method(D_METHOD("isActionJustReleased", "action"), &InputManager::isActionJustReleased);

        bind_method(D_METHOD("assignOnPress", "action", "callable"), &InputManager::assignOnPress);
        bind_method(D_METHOD("assignOnRelease", "action", "callable"), &InputManager::assignOnRelease);
        bind_method(D_METHOD("removeOnPress", "action", "callable"), &InputManager::removeOnPress);
        bind_method(D_METHOD("removeOnRelease", "action", "callable"), &InputManager::removeOnRelease);

        bind_method(D_METHOD("onWindowStopTarget"), &InputManager::onWindowStopTarget);
    }

private:
    StringName *m_pImportantActions;
    uint m_uImportantActionsCount;

    KeyboardState m_mCurrentPressedActions;
    KeyboardState m_mLastPressedActions;

    CallbackFunctionsMap m_mOnPress;
    CallbackFunctionsMap m_mOnRelease;

    CallbackFunctionsMap m_mOnPressAdd;
    CallbackFunctionsMap m_mOnReleaseAdd;

    std::vector<StringName> m_vChangedActions;

    Input *inputRef;

    /// @brief Check the provided vector to see if it already contains a function call
    /// @param searchVector Vector to search
    /// @param searchCall Function to search for
    /// @return true if function is found
    bool containsCallback(const std::vector<Callable> &searchVector, const Callable &searchCall);

    void clearKeyboardState(bool callFunction = false);

    void callFunctions(const StringName &action, bool isActionPressed);

public:
    InputManager();
    ~InputManager();

    // Update keyboard states
    void _input(const Ref<InputEvent> &event);
    void _process();

    // Access Functions

    /// @brief Check if an action is pressed
    /// @param action Action to check
    /// @return True if pressed
    bool isActionPressed(const StringName &action);

    /// @brief Check if an action was pressed this frame
    /// @param action Action to check
    /// @return True if pressed this frame
    bool isActionJustPressed(const StringName &action);

    /// @brief Check if an action was released this frame
    /// @param action Action to check
    /// @return True if released this frame
    bool isActionJustReleased(const StringName &action);

    /// @brief Assign callback function when action pressed
    /// @param action Action to assign to
    /// @param callbackFunc Function to callback to
    /// @param allowMult If callback function allows for multiple assignments (2 of the same function in callback)
    void assignOnPress(const StringName &action, const Callable &callbackFunc, bool allowMult = false);

    /// @brief Assign callback function when action released
    /// @param action Action to assign to
    /// @param callbackFunc Function to callback to
    /// @param allowMult If callback function allows for multiple assignments (2 of the same function in callback)
    void assignOnRelease(const StringName &action, const Callable &callbackFunc, bool allowMult = false);

    /// @brief Remove all functions from callback vector on press
    /// @param action Action to remove from
    /// @param callbackFunc Function to remove
    void removeOnPress(const StringName &action, const Callable &callbackFunc);

    /// @brief Remove all functions from callback vector on release
    /// @param action Action to remove from
    /// @param callbackFunc Function to remove
    void removeOnRelease(const StringName &action, const Callable &callbackFunc);

    /// @brief Set all press states to false
    void onWindowStopTarget();
};

#endif