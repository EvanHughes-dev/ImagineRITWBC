#include "input_manager.h"
#include <godot_cpp/variant/utility_functions.hpp>
#include <godot_cpp/classes/input_map.hpp>
#include <algorithm>

InputManager::InputManager()
    : m_pImportantActions(nullptr), m_uImportantActionsCount(0)
{
    godot::UtilityFunctions::print("Creating Input Manager");

    godot::InputMap *input = godot::InputMap::get_singleton();
    inputRef = Input::get_singleton();

    GDArray<StringName> actions = input->get_actions();

    std::vector<StringName> userActions;

    // Loop over all action names
    for (int i = 0; i < actions.size(); i++)
    {
        const StringName &action = actions[i];

        // Any action starting with ui_ us part of the default map
        // We only want our defined ones
        if (!action.begins_with("ui_"))
        {

            m_mOnPress[action] = std::vector<Callable>();
            m_mOnRelease[action] = std::vector<Callable>();

            userActions.push_back(action);
        }
    }

    m_uImportantActionsCount = userActions.size();
    m_pImportantActions = new StringName[m_uImportantActionsCount];

    std::copy(userActions.begin(), userActions.end(), m_pImportantActions);
}

InputManager::~InputManager()
{
    SafeDeleteArray(m_pImportantActions);
}

bool InputManager::containsCallback(const std::vector<Callable> &searchVector, const Callable &searchCall)
{
    for (uint i = 0; i < searchVector.size(); i++)
        if (searchVector[i] == searchCall)
            return true;

    return false;
}

void InputManager::clearKeyboardState(bool callFunction)
{
    for (uint i = 0; i < m_uImportantActionsCount; i++)
    {
        StringName &action = m_pImportantActions[i];
        bool wasPressed = m_mCurrentPressedActions[action];

        m_mCurrentPressedActions[action] = false;
        m_mLastPressedActions[action] = false;

        if (callFunction && wasPressed)
            callFunctions(action, false);
    }
}

void InputManager::callFunctions(const StringName &actionKey, bool isActionPressed)
{
    std::vector<Callable> callbackFunctions = isActionPressed
                                                  ? m_mOnPress[actionKey]
                                                  : m_mOnRelease[actionKey];

    for (const Callable &functionCall : callbackFunctions)
    {
        if (functionCall.is_valid())
        {
            functionCall.call(actionKey);
        }
    }
}

void InputManager::_input(const Ref<InputEvent> &event)
{

    for (uint i = 0; i < m_uImportantActionsCount; i++)
    {
        StringName &actionKey = m_pImportantActions[i];

        if (event->is_action(actionKey))
        {

            bool isActionPressed = event->is_action_pressed(actionKey);
            bool isActionReleased = event->is_action_released(actionKey);

            if (!isActionPressed && !isActionReleased)
            {

                continue;
                ;
            }
            m_mCurrentPressedActions[actionKey] = isActionPressed;

            callFunctions(actionKey, isActionPressed);

            m_vChangedActions.push_back(actionKey); // cache changed actions
        }
    }
}

void InputManager::_process()
{

    // Swap the current and last frame's keyboard
    // Only swap changed actions
    for (const StringName &key : m_vChangedActions)
    {
        m_mLastPressedActions[key] = m_mCurrentPressedActions[key];
    }
    m_vChangedActions.clear();

    for (const auto &pair : m_mOnPressAdd)
    {
        for (Callable call : pair.second)
            m_mOnPress[pair.first].push_back(call);
    }

    for (const auto &pair : m_mOnReleaseAdd)
    {
        for (Callable call : pair.second)
            m_mOnRelease[pair.first].push_back(call);
    }

    m_mOnPressAdd.clear();
    m_mOnReleaseAdd.clear();
}

/***** Access Functions *****/

bool InputManager::isActionPressed(const StringName &key)
{
    return m_mCurrentPressedActions[key];
}

bool InputManager::isActionJustPressed(const StringName &key)
{
    return m_mCurrentPressedActions[key] && !m_mLastPressedActions[key];
}

bool InputManager::isActionJustReleased(const StringName &key)
{
    return !m_mCurrentPressedActions[key] && m_mLastPressedActions[key];
}

void InputManager::assignOnPress(const StringName &action, const Callable &callbackFunc, bool allowMult)
{
    if (!allowMult && containsCallback(m_mOnPress[action], callbackFunc))
        return;
    m_mOnPressAdd[action].push_back(callbackFunc);
}

void InputManager::assignOnRelease(const StringName &action, const Callable &callbackFunc, bool allowMult)
{
    if (!allowMult && containsCallback(m_mOnRelease[action], callbackFunc))
        return;
    m_mOnReleaseAdd[action].push_back(callbackFunc);
}

void InputManager::removeOnPress(const StringName &action, const Callable &callbackFunc)
{
    std::vector<Callable> &currentVector = m_mOnPress[action];

    // loop over all elements of the iterator
    // remove any that match the callback function passed
    // O(n) removal

    for (std::vector<Callable>::iterator iterator = currentVector.begin(); iterator != currentVector.end();)
    {
        if (*iterator == callbackFunc)
        {
            iterator = currentVector.erase(iterator); // erase returns next valid iterator
        }
        else
        {
            ++iterator;
        }
    }
}

void InputManager::removeOnRelease(const StringName &action, const Callable &callbackFunc)
{

    std::vector<Callable> &currentVector = m_mOnRelease[action];

    // loop over all elements of the iterator
    // remove any that match the callback function passed

    // O(n) removal
    for (std::vector<Callable>::iterator iterator = currentVector.begin(); iterator != currentVector.end();)
    {

        if (*iterator == callbackFunc)
        {
            iterator = currentVector.erase(iterator); // erase returns next valid iterator
        }
        else
        {
            ++iterator;
        }
    }
}

void InputManager::onWindowStopTarget()
{
    m_vChangedActions.clear();
    clearKeyboardState(true);
}
