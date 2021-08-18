--[[                                                    
Executable Visual Architecture

MIT License

Copyright (c) 2021 Kubitly

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]

local cd=(...):gsub("%.init$","")

local eva={
	version = "0.0.4",
	blocks  = {},
	targets = {}
}

-------------------------------------------------------------------------------

eva.blocks.scope      = require( cd..".blocks.scope"      )
eva.blocks.value      = require( cd..".blocks.value"      )
eva.blocks.static     = require( cd..".blocks.static"     )
eva.blocks.subroutine = require( cd..".blocks.subroutine" )

-------------------------------------------------------------------------------

eva.targets.eva = require( cd..".targets.eva" )(eva)
eva.targets.lua = require( cd..".targets.lua" )(eva)
eva.targets.c   = require( cd..".targets.c"   )(eva)

-------------------------------------------------------------------------------

eva.translate = require( cd..".translate" )(eva)
eva.compile   = require( cd..".compile"   )(eva)
eva.construct = require( cd..".construct" )(eva)
eva.parse     = require( cd..".parse"     )(eva)

-------------------------------------------------------------------------------

return eva