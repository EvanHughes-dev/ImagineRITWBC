#include "input_manager.h"
#include <godot_cpp/variant/utility_functions.hpp>
#include <godot_cpp/classes/input_map.hpp>
#include <algorithm>

void InputManager::_bind_methods()
{
    bind_method(D_METHOD("_process", "mousePos", "delta"), &InputManager::_process);
    bind_method(D_METHOD("_input", "event"), &InputManager::_input);

    bind_method(D_METHOD("isActionPressed", "action"), &InputManager::isActionPressed);
    bind_method(D_METHOD("isActionJustPressed", "action"), &InputManager::isActionJustPressed);
    bind_method(D_METHOD("isActionJustReleased", "action"), &InputManager::isActionJustReleased);

    bind_method(D_METHOD("assignOnPress", "action", "callable", "allowMult"), &InputManager::assignOnPress, DEFVAL(false));
    bind_method(D_METHOD("assignOnRelease", "action", "callable", "allowMult"), &InputManager::assignOnRelease, DEFVAL(false));
    bind_method(D_METHOD("assignOnMouseMove", "callable", "allowMult"), &InputManager::assignOnMouseMove, DEFVAL(false));

    bind_method(D_METHOD("removeOnPress", "action", "callable"), &InputManager::removeOnPress);
    bind_method(D_METHOD("removeOnRelease", "action", "callable"), &InputManager::removeOnRelease);
    bind_method(D_METHOD("removeOnMouseMove", "callable"), &InputManager::removeOnMouseMove);

    bind_method(D_METHOD("onWindowStopTarget"), &InputManager::onWindowStopTarget);
}

InputManager::InputManager()
{
    godot::UtilityFunctions::print("Creating Input Manager");

    godot::InputMap *inputMap = godot::InputMap::get_singleton();
    if (!inputMap)
        return;

    GDArray<StringName> actions = inputMap->get_actions();

    // Cache non-default actions into vector and initialize map buckets
    for (int i = 0; i < actions.size(); i++)
    {
        const StringName &action = actions[i];

        if (!action.begins_with("ui_"))
        {
            m_mOnPress[action] = std::vector<Callable>();
            m_mOnRelease[action] = std::vector<Callable>();
            m_vImportantActions.push_back(action);
        }
    }
}

InputManager::~InputManager()
{
}

bool InputManager::containsCallback(const std::vector<Callable> &searchVector, const Callable &searchCall) const
{
    return std::find(searchVector.begin(), searchVector.end(), searchCall) != searchVector.end();
}

void InputManager::clearKeyboardState(bool callFunction)
{
    for (const StringName &action : m_vImportantActions)
    {
        // Safe lookup without mutating map
        auto it = m_mCurrentPressedActions.find(action);
        bool wasPressed = (it != m_mCurrentPressedActions.end()) ? it->second : false;

        m_mCurrentPressedActions[action] = false;
        m_mLastPressedActions[action] = false;

        if (callFunction && wasPressed)
        {
            callFunctions(action, false);
        }
    }
}

void InputManager::callFunctions(const StringName &actionKey, bool isActionPressed)
{
    const auto &map = isActionPressed ? m_mOnPress : m_mOnRelease;
    auto it = map.find(actionKey);
    if (it == map.end())
        return;

    // Create a local copy during invocation to prevent crash/invalidation
    // if a callback registers/unregisters callbacks during its call.
    const std::vector<Callable> callbackFunctions = it->second;

    for (const Callable &functionCall : callbackFunctions)
    {
        if (functionCall.is_valid())
        {
            functionCall.call(actionKey);
        }
    }
}

void InputManager::eraseCallback(const Callable &callbackFunc, std::vector<Callable> &vec)
{
    vec.erase(std::remove(vec.begin(), vec.end(), callbackFunc), vec.end());
}

void InputManager::_input(const Ref<InputEvent> &event)
{
    // Early exit non-action input events (e.g. raw mouse movement) to avoid looping actions needlessly
    if (event.is_null() || !event->is_action_type())
    {
        return;
    }

    for (const StringName &actionKey : m_vImportantActions)
    {
        if (event->is_action(actionKey))
        {
            bool isActionPressed = event->is_action_pressed(actionKey);
            bool isActionReleased = event->is_action_released(actionKey);

            // Skip echo or non-state-change events
            if (!isActionPressed && !isActionReleased)
            {
                continue;
            }

            m_mCurrentPressedActions[actionKey] = isActionPressed;
            callFunctions(actionKey, isActionPressed);

            m_vChangedActions.push_back(actionKey);
        }
    }
}

void InputManager::_process(const godot::Vector2 &mousePos, const float &delta)
{
    // Synchronize current state to last frame state for changed actions only
    for (const StringName &key : m_vChangedActions)
    {
        m_mLastPressedActions[key] = m_mCurrentPressedActions[key];
    }
    m_vChangedActions.clear();

    // Flush staged callback additions
    for (const auto &[action, callables] : m_mOnPressAdd)
    {
        auto &targetVec = m_mOnPress[action];
        targetVec.insert(targetVec.end(), callables.begin(), callables.end());
    }

    for (const auto &[action, callables] : m_mOnReleaseAdd)
    {
        auto &targetVec = m_mOnRelease[action];
        targetVec.insert(targetVec.end(), callables.begin(), callables.end());
    }

    for (const Callable &callable : m_vOnMouseMoveAdd)
    {
        m_vOnMouseMove.push_back(callable);
    }

    // Update any mouse movement
    if (m_bfirstFramePast)
    {

        float mouseDistanceSquared = mousePos.distance_squared_to(m_vMousePosLastFrame);

        // Has to at least have moved 1 unit. Sqrt of x when x>1 is >1
        if (mouseDistanceSquared >= 1.0f)
        {
            for (const Callable &callable : m_vOnMouseMove)
            {
                if (callable.is_valid() && !callable.is_null())
                    callable.call(mouseDistanceSquared, mousePos - m_vMousePosLastFrame);
            }
        }
        // godot::UtilityFunctions::print(godot::vformat("Mouse moved %.2f units", mouseDistanceSquared));
    }
    else
        m_bfirstFramePast = true;

    m_vMousePosLastFrame = mousePos;

    m_mOnPressAdd.clear();
    m_mOnReleaseAdd.clear();
    m_vOnMouseMoveAdd.clear();
}

/***** Access Functions *****/

bool InputManager::isActionPressed(const StringName &key) const
{
    auto it = m_mCurrentPressedActions.find(key);
    return (it != m_mCurrentPressedActions.end()) ? it->second : false;
}

bool InputManager::isActionJustPressed(const StringName &key) const
{
    auto currIt = m_mCurrentPressedActions.find(key);
    auto lastIt = m_mLastPressedActions.find(key);

    bool curr = (currIt != m_mCurrentPressedActions.end()) ? currIt->second : false;
    bool last = (lastIt != m_mLastPressedActions.end()) ? lastIt->second : false;

    return curr && !last;
}

bool InputManager::isActionJustReleased(const StringName &key) const
{
    auto currIt = m_mCurrentPressedActions.find(key);
    auto lastIt = m_mLastPressedActions.find(key);

    bool curr = (currIt != m_mCurrentPressedActions.end()) ? currIt->second : false;
    bool last = (lastIt != m_mLastPressedActions.end()) ? lastIt->second : false;

    return !curr && last;
}

void InputManager::assignOnPress(const StringName &action, const Callable &callbackFunc, bool allowMult)
{
    // Check both active and pending buffers to avoid duplicate queueing in the same frame
    if (!allowMult)
    {
        if (containsCallback(m_mOnPress[action], callbackFunc) ||
            containsCallback(m_mOnPressAdd[action], callbackFunc))
        {
            return;
        }
    }
    m_mOnPressAdd[action].push_back(callbackFunc);
}

void InputManager::assignOnRelease(const StringName &action, const Callable &callbackFunc, bool allowMult)
{
    if (!allowMult)
    {
        if (containsCallback(m_mOnRelease[action], callbackFunc) ||
            containsCallback(m_mOnReleaseAdd[action], callbackFunc))
        {
            return;
        }
    }
    m_mOnReleaseAdd[action].push_back(callbackFunc);
}

void InputManager::assignOnMouseMove(const Callable &callbackFunc, bool allowMult)
{
    if (!allowMult && (containsCallback(m_vOnMouseMove, callbackFunc) || containsCallback(m_vOnMouseMoveAdd, callbackFunc)))
        return;

    m_vOnMouseMove.push_back(callbackFunc);
}

void InputManager::removeOnPress(const StringName &action, const Callable &callbackFunc)
{
    eraseCallback(callbackFunc, m_mOnPress[action]);
    eraseCallback(callbackFunc, m_mOnPressAdd[action]);
}

void InputManager::removeOnRelease(const StringName &action, const Callable &callbackFunc)
{
    eraseCallback(callbackFunc, m_mOnRelease[action]);
    eraseCallback(callbackFunc, m_mOnReleaseAdd[action]);
}

void InputManager::removeOnMouseMove(const Callable &callbackFunc)
{
    eraseCallback(callbackFunc, m_vOnMouseMove);
    eraseCallback(callbackFunc, m_vOnMouseMoveAdd);
}

void InputManager::onWindowStopTarget()
{
    m_vChangedActions.clear();
    clearKeyboardState(true);
}