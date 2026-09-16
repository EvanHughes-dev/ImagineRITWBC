Writing Your First C++ GDExtension
==================================

With Godot and SCons set up, you can write your first C++ class to extend Godot. This guide covers building a minimal ``Node`` class that prints a message to the Godot console every frame.


Creating the Header File
------------------------

Create a file named ``my_node.h`` inside your C++ source directory:

.. code-block:: cpp

   #ifndef MY_NODE_H
   #define MY_NODE_H

   #include <godot_cpp/classes/node.hpp>

   namespace godot {

   class MyNode : public Node {
       GDCLASS(MyNode, Node)

   protected:
       static void _bind_methods();

   public:
       MyNode();
       ~MyNode();

       void _process(double delta) override;
   };

   } // namespace godot

   #endif // MY_NODE_H


Creating the Source File
------------------------

Create a file named ``my_node.cpp`` in the same directory:

.. code-block:: cpp

   #include "my_node.h"
   #include <godot_cpp/variant/utility_functions.hpp>

   using namespace godot;

   void MyNode::_bind_methods() {
       // Expose C++ methods, properties, and signals to GDScript here
   }

   MyNode::MyNode() {
       // Initialize variables here
   }

   MyNode::~MyNode() {
       // Cleanup resources here
   }

   void MyNode::_process(double delta) {
       UtilityFunctions::print("Hello from C++ GDExtension!");
   }


Key Concepts
------------

* **``GDCLASS(MyNode, Node)``**: A required macro for every custom Godot C++ class. It handles object inheritance and metadata.
* **``_bind_methods()``**: The static registration function used to expose C++ functions and variables to GDScript and the Godot inspector.
* **``UtilityFunctions::print(...)``**: The C++ wrapper for GDScript's built-in ``print()`` function.


Building the Code
-----------------

Compile the updated source files into your dynamic library using SCons:

.. code-block:: bash

   scons target=template_debug