#!/usr/bin/env python
import os

# You can find documentation for SCons and SConstruct files at:
# https://scons.org/documentation.html

# This lets SCons know that we're using godot-cpp, from the godot-cpp folder.
env = SConscript("godot-cpp/SConstruct")  # type: ignore
sources = []
target = env["target"]  # "template_debug" or "template_release"
print(target)

# Common usage — conditional logic based on target
if target == "template_release":
    env.Append(CPPDEFINES=["NDEBUG"])
elif target == "template_debug":
    env.Append(CPPDEFINES=["DEBUG_ENABLED"])


def add_src_subdirs(sources, env):
    for root, dirs, files in os.walk("src"):
        has_cpp = any(f.endswith(".cpp") for f in files)
        has_h = any(f.endswith(".h") for f in files)

        if has_cpp or has_h:
            env.Append(CPPPATH=[root + "/"])
            if has_cpp:
                sources += Glob(root + "/*.cpp")


add_src_subdirs(sources, env)
# The filename for the dynamic library for this GDExtension.
# $SHLIBPREFIX is a platform specific prefix for the dynamic library ('lib' on Unix, '' on Windows).
# $SHLIBSUFFIX is the platform specific suffix for the dynamic library (for example '.dll' on Windows).
# env["suffix"] includes the build's feature tags (e.g. '.windows.template_debug.x86_64')
# (see https://docs.godotengine.org/en/stable/tutorials/export/feature_tags.html).
# The final path should match a path in the '.gdextension' file.
lib_filename = "{}imagine-ritwbc{}{}".format(
    env.subst("$SHLIBPREFIX"), env["suffix"], env.subst("$SHLIBSUFFIX")
)

# Creates a SCons target for the path with our sources.
library = env.SharedLibrary(
    "imagine-ritwbc-godot/bin/{}".format(lib_filename),
    source=sources,
)

# Selects the shared library as the default target.
Default(library)  # pyright: ignore[reportUndefinedVariable]
