#ifndef SEPARATE_WINDOW_H
#define SEPARATE_WINDOW_H

#include <godot_cpp/classes/node.hpp>
#include "definitions.h"
#include <thread>
#include <atomic>

namespace godot
{

    class SeparateWindow : public Node
    {
        GDCLASS(SeparateWindow, Node)

    private:
        std::thread m_window_thread;
        std::atomic<bool> m_is_running{false};

        void window_thread_loop(String title, int width, int height);

    protected:
        static void _bind_methods();

    public:
        SeparateWindow();
        ~SeparateWindow();

        void open_window(const String &title, int width, int height);
        void close_window();
        bool is_window_running() const;
    };

} // namespace godot

#endif