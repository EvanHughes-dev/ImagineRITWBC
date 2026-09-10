#ifndef NODE_STACK_H
#define NODE_STACK_H

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/classes/node2d.hpp>
#include <generic_stack.h>

using godot::Node2D;

class Node2DStack : public RefCounted, protected GenericStack<Node2D *>
{
    GDCLASS(Node2DStack, RefCounted)

protected:
    static void _bind_methods()
    {
        bind_method(D_METHOD("addStack", "node"), &Node2DStack::addStack);
        bind_method(D_METHOD("removeStack", "node"), &Node2DStack::removeStack);
        bind_method(D_METHOD("topStack"), &Node2DStack::topStack);
        bind_method(D_METHOD("count"), &Node2DStack::count);
        bind_method(D_METHOD("isEmpty"), &Node2DStack::isEmpty);
        bind_method(D_METHOD("clar"), &Node2DStack::clear);
    }

public:
    void addStack(Node2D *node) { GenericStack<Node2D *>::addStack(node); }
    void removeStack(Node2D *node) { GenericStack<Node2D *>::removeStack(node); }
    Node2D *topStack() { return GenericStack<Node2D *>::topStack(); }
    uint_8 count() { return GenericStack<Node2D *>::count(); }
    bool isEmpty() { return GenericStack<Node2D *>::isEmpty(); }
    void clear() { GenericStack<Node2D *>::clear(); }
};

#endif