#ifndef REF_COUNTED_STACK
#define REF_COUNTED_STACK

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/classes/ref.hpp>
#include <godot_cpp/variant/typed_array.hpp>
#include <generic_stack.h>

struct RefCountedHash
{
    size_t operator()(const Ref<RefCounted> &ref) const noexcept
    {
        return std::hash<const void *>()(ref.ptr());
    }
};

class RefCountedStack : public RefCounted,
                        protected GenericStack<Ref<RefCounted>, RefCountedHash>
{
    GDCLASS(RefCountedStack, RefCounted)

    using Base = GenericStack<Ref<RefCounted>, RefCountedHash>;

protected:
    static void _bind_methods()
    {
        bind_method(D_METHOD("addStack", "name"), &RefCountedStack::addStack);
        bind_method(D_METHOD("removeStack", "name"), &RefCountedStack::removeStack);
        bind_method(D_METHOD("topStack"), &RefCountedStack::topStack);
        bind_method(D_METHOD("count"), &RefCountedStack::count);
        bind_method(D_METHOD("isEmpty"), &RefCountedStack::isEmpty);
    }

public:
    void addStack(const Ref<RefCounted> &data) { Base::addStack(data); }
    void removeStack(const Ref<RefCounted> &data) { Base::removeStack(data); }
    Ref<RefCounted> topStack() { return Base::topStack(); }
    uint8_t count() { return Base::count(); }
    bool isEmpty() { return Base::isEmpty(); }
    void clear() { Base::clear(); }
};

#endif