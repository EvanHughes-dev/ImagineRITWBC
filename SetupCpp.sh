#!/bin/bash

set -e

echo "Checking system requirements..."
echo ""

# Ensure python exists
if command -v python3 &>/dev/null; then
    echo "python is installed!"
else
    echo "ERROR: python is not installed. Please install python3."
    echo "https://www.python.org/downloads/"
    exit 1
fi

# Ensure pip is installed
if command -v pip3 &>/dev/null; then
    echo "pip is installed!"
else
    echo "pip is NOT installed. Attempting to install..."
    curl -sS https://bootstrap.pypa.io/get-pip.py | python3
fi

# Ensure scons is installed
if command -v scons &>/dev/null; then
    echo "scons is installed!"
else
    echo "scons is not installed. Attempting to install now."
    pip3 install scons
fi

COMPILER_FOUND=false

if command -v g++ &>/dev/null; then
    echo "g++ found: $(g++ --version | head -1)"
    COMPILER_FOUND=true
fi

if command -v clang++ &>/dev/null; then
    echo "clang++ found: $(clang++ --version | head -1)"
    COMPILER_FOUND=true
fi

if [ "$COMPILER_FOUND" = false ]; then
    echo "ERROR: No C++ compiler found (g++ or clang++)."
    echo "Please install one of the following:"
    echo "  - g++:     sudo apt install g++        (Debian/Ubuntu)"
    echo "  - clang++: sudo apt install clang      (Debian/Ubuntu)"
    echo "  - g++:     sudo dnf install gcc-c++    (Fedora)"
    echo "  - clang++: brew install llvm           (macOS)"
    exit 1
fi

echo ""

echo "Updating submodules..."
git submodule update --init --recursive --quiet

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GODOT_CPP_DIR="$SCRIPT_DIR/godot-cpp"

if [ -d "$GODOT_CPP_DIR/gen/include" ]; then
    echo "godot-cpp bindings already built, skipping scons."
else
    echo "Building godot-cpp bindings..."
    pushd "$GODOT_CPP_DIR" > /dev/null
    scons api_version=4.6 --quiet
    popd > /dev/null
    echo "godot-cpp bindings built successfully."
fi