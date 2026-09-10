#ifndef NPC_STATS_H
#define NPC_STATS_H

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/classes/ref.hpp>
#include <godot_cpp/variant/string.hpp>

#include "definitions.h"

class NPCStats : public RefCounted {
protected:
    static void _bind_methods() {
        bind_method( D_METHOD( "getSpeed" ), &NPCStats::getSpeed );
        bind_method( D_METHOD( "getNiceness" ), &NPCStats::getNiceness );
        bind_method( D_METHOD( "getMotivation" ), &NPCStats::getMotivation );
        bind_method( D_METHOD( "getName" ), &NPCStats::getName );
    };
    GDCLASS( NPCStats, RefCounted );

private:
    uint_8 m_uiSpeed;
    uint_8 m_uiNiceness;
    uint_8 m_uiMotivation;

    String m_sName;

public:
    NPCStats() :m_uiSpeed( 0 ), m_uiNiceness( 0 ), m_uiMotivation( 0 ), m_sName( "" ) { }

    void setSpeed( uint_8 speed ) { m_uiSpeed = speed; }
    void setNiceness( uint_8 niceness ) { m_uiNiceness = niceness; }
    void setMotivation( uint_8 motivation ) { m_uiMotivation = motivation; }
    void setName( const String& name ) { m_sName = name; }

    uint_8 getSpeed() { return m_uiSpeed; };
    uint_8 getNiceness() { return m_uiNiceness; };
    uint_8 getMotivation() { return m_uiMotivation; };
    String getName() { return m_sName; };

};

#endif