#include "separate_window.h"
#include <GLFW/glfw3.h>
#include <godot_cpp/core/class_db.hpp>

using namespace godot;

void SeparateWindow::_bind_methods()
{
    bind_method(D_METHOD("open_window", "title", "width", "height"), &SeparateWindow::open_window);
    bind_method(D_METHOD("close_window"), &SeparateWindow::close_window);
    bind_method(D_METHOD("is_window_running"), &SeparateWindow::is_window_running);
}

SeparateWindow::SeparateWindow() {}

SeparateWindow::~SeparateWindow()
{
    close_window();
}

void SeparateWindow::open_window(const String &title, int width, int height)
{
    if (m_is_running)
        return;

    m_is_running = true;
    m_window_thread = std::thread(&SeparateWindow::window_thread_loop, this, title, width, height);
}

void SeparateWindow::close_window()
{
    m_is_running = false;
    if (m_window_thread.joinable())
    {
        m_window_thread.join();
    }
}

bool SeparateWindow::is_window_running() const
{
    return m_is_running;
}

void SeparateWindow::window_thread_loop(String title, int width, int height)
{
    if (!glfwInit())
    {
        m_is_running = false;
        return;
    }

    GLFWwindow *window = glfwCreateWindow(width, height, title.utf8().get_data(), nullptr, nullptr);
    if (!window)
    {
        glfwTerminate();
        m_is_running = false;
        return;
    }

    glfwMakeContextCurrent(window);

    // Event loop independent of Godot
    while (m_is_running && !glfwWindowShouldClose(window))
    {
        // Render/Draw calls here
        glfwSwapBuffers(window);
        glfwPollEvents();
    }

    glfwDestroyWindow(window);
    glfwTerminate();
    m_is_running = false;
}