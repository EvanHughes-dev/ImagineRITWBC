#ifndef GENERIC_STACK_H
#define GENERIC_STACK_H

#include <unordered_map>
#include <vector>
#include <definitions.h>
#include <godot_cpp/variant/utility_functions.hpp>

template <typename T, typename Hash = std::hash<T>>
class GenericStack
{
protected:
    std::unordered_map<T, uint_8, Hash> m_mStackOrder;
    std::unordered_map<uint_8, T> m_mStackOrderLookup;

private:
    uint_8 m_ubHighestValue = 0;

public:
    virtual ~GenericStack() = default;

    /// @brief Add to the top of the stack
    /// @param item Item to add
    void addStack(const T &item);
    /// @brief Remove from the top of the stack
    /// @param item Name to remove if it exists
    void removeStack(const T &item);
    /// @brief Get the value from the top of the stack
    /// @return Top value of the stack. "" If there is no value
    T topStack();
    /// @brief Get the size of the stack
    /// @return The number of elements in the stack
    uint_8 count() { return m_ubHighestValue; };
    /// @brief Check if the stack is empty
    /// @return True if stack is empty
    bool isEmpty() { return m_ubHighestValue == 0; }

    /// @brief Clear all items from this stack
    void clear();
};

template <typename T, typename Hash>
inline void GenericStack<T, Hash>::addStack(const T &item)
{
    m_mStackOrder[item] = ++m_ubHighestValue;
    m_mStackOrderLookup[m_ubHighestValue] = item;
}

template <typename T, typename Hash>
inline void GenericStack<T, Hash>::removeStack(const T &item)
{
    if (m_mStackOrder.find(item) == m_mStackOrder.end())
        return;
    uint_8 current = m_mStackOrder[item];

    if (current != m_ubHighestValue)
    {
        for (uint_8 i = current + 1; i <= m_ubHighestValue; i++)
        {
            T &entry = m_mStackOrderLookup[i];
            m_mStackOrder[entry] = i - 1;
            m_mStackOrderLookup[i - 1] = entry;
        }
    }

    m_mStackOrderLookup.erase(m_ubHighestValue);
    if (m_ubHighestValue != 0)
        m_ubHighestValue--;
    m_mStackOrder.erase(item);
}

template <typename T, typename Hash>
inline T GenericStack<T, Hash>::topStack()
{
    if (isEmpty())
        return T{};
    return m_mStackOrderLookup[m_ubHighestValue];
}

template <typename T, typename Hash>
inline void GenericStack<T, Hash>::clear()
{
    for (uint_8 i = 0; i <= m_ubHighestValue; i++)
    {
        m_mStackOrder.erase(m_mStackOrderLookup[i]);
        m_mStackOrderLookup.erase(m_ubHighestValue);
    }

    m_ubHighestValue = 0;
}

#endif
