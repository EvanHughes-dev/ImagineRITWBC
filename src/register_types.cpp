#include "register_types.h"

#include <gdextension_interface.h>
#include <godot_cpp/core/defs.hpp>
#include <godot_cpp/godot.hpp>
#include <godot_cpp/classes/engine.hpp>

#include "input_manager.h"
#include "input_stack.h"
#include "node_stack.h"
#include "refcounted_stack.h"

#include "separate_window.h"

#include "definitions.h"

using namespace godot;

template <typename T>
void registerSingleton(Engine *engine, StringName name)
{
    T *_instance = memnew(T);
    engine->register_singleton(name, _instance);
}

template <typename T>
void unregisterSingleton(Engine *engine, StringName name)
{
    if ((engine)->has_singleton(name))
    {

        T *_instance = Object::cast_to<T>((engine)->get_singleton(name));
        (engine)->unregister_singleton(name);
        if (_instance)
        {
            memdelete(_instance);
        }
    }
}

void initialize_modules(ModuleInitializationLevel p_level)
{
    if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE)
    {
        return;
    }

    GDREGISTER_CLASS(InputStack);
    GDREGISTER_CLASS(Node2DStack);
    GDREGISTER_CLASS(RefCountedStack);

    GDREGISTER_CLASS(InputManager);
    GDREGISTER_CLASS(SeparateWindow);

    Engine *engine = Engine::get_singleton();

    // Register InputManager as a singleton
    registerSingleton<InputManager>(engine, "InputManager");
}

void uninitialize_modules(ModuleInitializationLevel p_level)
{
    if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE)
    {
        return;
    }

    Engine *engine = Engine::get_singleton();

    unregisterSingleton<InputManager>(engine, "InputManager");
}

extern "C"
{
    // Initialization.
    GDExtensionBool GDE_EXPORT imagine_ritwbc_library_init(GDExtensionInterfaceGetProcAddress p_get_proc_address, const GDExtensionClassLibraryPtr p_library, GDExtensionInitialization *r_initialization)
    {
        godot::GDExtensionBinding::InitObject init_obj(p_get_proc_address, p_library, r_initialization);

        init_obj.register_initializer(initialize_modules);
        init_obj.register_terminator(uninitialize_modules);
        init_obj.set_minimum_library_initialization_level(MODULE_INITIALIZATION_LEVEL_SCENE);

        return init_obj.init();
    }
}