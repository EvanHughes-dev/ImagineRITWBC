#ifndef INPUT_STACK_H
#define INPUT_STACK_H

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/variant/typed_array.hpp>
#include <generic_stack.h>

using Base = GenericStack<StringName, StringNameHash>;

class InputStack : public RefCounted, protected Base
{
    GDCLASS(InputStack, RefCounted)

protected:
    static void _bind_methods()
    {
        bind_method(D_METHOD("addStack", "name"), &InputStack::addStack);
        bind_method(D_METHOD("removeStack", "name"), &InputStack::removeStack);
        bind_method(D_METHOD("topStack"), &InputStack::topStack);
        bind_method(D_METHOD("firstInArray", "names"), &InputStack::firstInArray);
        bind_method(D_METHOD("count"), &InputStack::count);
        bind_method(D_METHOD("isEmpty"), &InputStack::isEmpty);
        bind_method(D_METHOD("clear"), &InputStack::clear);
    }

public:
    void addStack(const StringName &name) { Base::addStack(name); };
    void removeStack(const StringName &name) { Base::removeStack(name); };
    String topStack() { return Base::topStack(); };
    String firstInArray(GDArray<StringName> checkNames)
    {
        uint firstIndex = 0;
        uint firstStackValue = 0;
        for (uint i = 0; i < checkNames.size(); i++)
        {
            if (m_mStackOrder[checkNames[i]] > firstStackValue)
            {
                firstStackValue = m_mStackOrder[checkNames[i]];
                firstIndex = i;
            }
        }
        // All values in array are not on the stack
        if (firstStackValue == 0)
            return "";

        return checkNames[firstIndex];
    };
    uint_8 count() { return Base::count(); }
    bool isEmpty() { return Base::isEmpty(); }
    void clear() { Base::clear(); }
};

#endif