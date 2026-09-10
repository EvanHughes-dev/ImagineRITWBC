#pragma once
#include <godot_cpp/variant/string_name.hpp>
#include <godot_cpp/variant/typed_array.hpp>

/* -------------------------------------------------------------------------- */
/*                             Default Data Types                             */
/* -------------------------------------------------------------------------- */

typedef unsigned int uint;
typedef unsigned char uint_8;

/* -------------------------------------------------------------------------- */
/*                             Godot Type Aliasing                            */
/* -------------------------------------------------------------------------- */

// These work as defines
#define RefCounted  godot::RefCounted
#define bind_method godot::ClassDB::bind_method
#define D_METHOD    godot::D_METHOD
#define Object      godot::Object
#define RefCount    godot::RefCount
#define Ref         godot::Ref

using StringName = godot::StringName;
using String = godot::String;
using Callable = godot::Callable;
template<typename T>
using GDArray = godot::TypedArray<T>;

/* -------------------------------------------------------------------------- */
/*                       Utile Functions and Definition                       */
/* -------------------------------------------------------------------------- */

#define SafeDelete(p){ if(p) { delete p; p = nullptr; } }
#define SafeDeleteArray(p){ if(p) { delete[] p; p = nullptr; } }

struct StringNameHash {
    size_t operator()( const StringName& name ) const {
        return name.hash();
    }
};

struct StringNameEqual {
    bool operator()( const StringName& a, const StringName& b ) const {
        return a == b;
    }
};

inline void copy( const char a[ ], char*& b, uint* len ) {
    *len = static_cast< uint >( strlen( a ) );
    b = new char[ *len + 1 ];
    std::copy( a, a + *len + 1, b );
}