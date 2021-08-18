# EVA
Executable Visual Architecture

# Description
Eva is a dynamically typed visual programming language that transpiles down to other language implementations such as C or Lua.

Every part of the code is defined by blocks. The goal is to emphasize the editor itself and allow seamless coding whether using a mouse and keyboard or using a touchscreen device such as a tablet or phone.

In order to provide interoperability, macros and inline code is supported. This means raw C or Lua code can be used in order to interface with the rest of the language. This however puts a lot of trust to the programmers and therefor must be carefully written.

This language also provides garbage collection. When it is transpiled into Lua it will use Lua's GC. When it is transpiled into C it will use explicit reference counting.

# License
This software is free to use. You can modify it and redistribute it under the terms of the MIT license. Check [LICENSE](LICENSE) for further details.
