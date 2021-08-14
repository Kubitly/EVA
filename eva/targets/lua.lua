return function(eva)
local scope      = {}
local value      = {}
local static     = {}
local subroutine = {}

-------------------------------------------------------------------------------

scope.level=function(block,target,output,stack)
	local level=0
	local coordinates=""
	
	for i,parent in ipairs(stack) do
		if (
			parent.block_type=="value_subroutine" or
			parent.block_type=="subroutine_do" or
			parent.block_type=="subroutine_loop"
		) then
			level=level+1
		end
		
		if parent.block_type=="static_group" then
			coordinates=coordinates..("_%d_%d"):format(
				parent.x,parent.y
			)
		end
	end
	
	output[#output+1]=("_%d"):format(level-block.level)
	output[#output+1]=coordinates
	
	if block.next_scope then
		eva.translate(block.next_scope,target,output,stack)
	end
end

scope.position=function(block,target,output,stack)
	output[#output+1]=("_%d_%d"):format(block.x,block.y)
	
	if block.next_scope then
		eva.translate(block.next_scope,target,output,stack)
	end
end

scope.index=function(block,target,output,stack)
	output[#output+1]="["
	eva.translate(block.index,target,output,stack)
	output[#output+1]="+1]"
	
	if block.next_scope then
		eva.translate(block.next_scope,target,output,stack)
	end
end

-------------------------------------------------------------------------------

value.null=function(block,target,output,stack)
	output[#output+1]="false"
end

value.literal=function(block,target,output,stack)
	output[#output+1]=block.value
end

value.variable=function(block,target,output,stack)
	eva.translate(block.scope,target,output,stack)
end

value.table=function(block,target,output,stack)
	output[#output+1]="{"
	
	for i,block_ in ipairs(block.contents) do
		eva.translate(block_,target,output,stack)
		
		if i<#block.contents then
			output[#output+1]=","
		end
	end
	
	output[#output+1]="}"
end

value.subroutine=function(block,target,output,stack)
	local level=0
	local coordinates=""
	
	for i,parent in ipairs(stack) do
		if (
			parent.block_type=="value_subroutine" or
			parent.block_type=="subroutine_do" or
			parent.block_type=="subroutine_loop"
		) then
			level=level+1
		end
		
		if parent.block_type=="static_group" then
			coordinates=coordinates..("_%d_%d"):format(
				parent.x,parent.y
			)
		end
	end
	
	table.sort(
		block.operations,
		function(a,b)
			return a.x^2+a.y^2<b.x^2+b.y^2
		end
	)
	
	do
		output[#output+1]="function("
		
		local arguments={}
		
		for _,block_ in ipairs(block.operations) do
			if block_.block_type=="subroutine_argument" then
				arguments[#arguments+1]=block_
			end
		end
		
		for i,block_ in ipairs(arguments) do
			output[#output+1]=("_%d"):format(level)
			output[#output+1]=coordinates
			output[#output+1]=("_%d_%d"):format(block_.x,block_.y)
			
			if i<#arguments then
				output[#output+1]=","
			end
		end
		
		output[#output+1]=")\n"
	end
	
	for _,block_ in ipairs(block.operations) do
		if block_.block_type~="subroutine_argument" then
			eva.translate(block_,target,output,stack)
		end
	end
	
	output[#output+1]="end"
end

-------------------------------------------------------------------------------

static.group=function(block,target,output,stack)
	table.sort(
		block.blocks,
		function(a,b)
			return a.x^2+a.y^2<b.x^2+b.y^2
		end
	)
	
	for _,block_ in ipairs(block.blocks) do
		eva.translate(block_,target,output,stack)
	end
end

static.variable=function(block,target,output,stack)
	local level=0
	local coordinates=""
	
	for i,parent in ipairs(stack) do
		if (
			parent.block_type=="value_subroutine" or
			parent.block_type=="subroutine_do" or
			parent.block_type=="subroutine_loop"
		) then
			level=level+1
		end
		
		if parent.block_type=="static_group" then
			coordinates=coordinates..("_%d_%d"):format(
				parent.x,parent.y
			)
		end
	end
	
	output[#output+1]=("local _%d"):format(level)
	output[#output+1]=coordinates
	output[#output+1]=("_%d_%d"):format(block.x,block.y)
	
	if block.value then
		output[#output+1]="="
		eva.translate(block.value,target,output,stack)
		output[#output+1]="\n"
	else
		output[#output+1]="\n"
	end
end

-------------------------------------------------------------------------------

subroutine.variable=function(block,target,output,stack)
	local level=0
	local coordinates=""
	
	for i,parent in ipairs(stack) do
		if (
			parent.block_type=="value_subroutine" or
			parent.block_type=="subroutine_do" or
			parent.block_type=="subroutine_loop"
		) then
			level=level+1
		end
		
		if parent.block_type=="static_group" then
			coordinates=coordinates..("_%d_%d"):format(
				parent.x,parent.y
			)
		end
	end
	
	output[#output+1]=("	"):rep(level)
	output[#output+1]=("local _%d"):format(level)
	output[#output+1]=coordinates
	output[#output+1]=("_%d_%d\n"):format(block.x,block.y)
end

subroutine.set=function(block,target,output,stack)
	local level=0
	
	for i,parent in ipairs(stack) do
		if (
			parent.block_type=="value_subroutine" or
			parent.block_type=="subroutine_do" or
			parent.block_type=="subroutine_loop"
		) then
			level=level+1
		end
	end
	
	output[#output+1]=("	"):rep(level)
	eva.translate(block.output,target,output,stack)
	output[#output+1]="="
	eva.translate(block.value,target,output,stack)
	output[#output+1]="\n"
end

subroutine.allocate=function(block,target,output,stack)
	local level=0
	
	for i,parent in ipairs(stack) do
		if (
			parent.block_type=="value_subroutine" or
			parent.block_type=="subroutine_do" or
			parent.block_type=="subroutine_loop"
		) then
			level=level+1
		end
	end
	
	output[#output+1]=("	"):rep(level)
	eva.translate(block.output,target,output,stack)
	output[#output+1]="={"
	
	do
		local size=#block.contents
		
		if block.size.block_type=="value_literal" then
			size=math.max(block.size.value,size)
		end
		
		for i=1,size do
			local block_=block.contents[i]
			
			if block_ then
				eva.translate(block_,target,output,stack)
			else
				output[#output+1]="false"
			end
			
			if i<size then
				output[#output+1]=","
			end
		end
	end
	
	output[#output+1]="}\n"
	
	if block.size.block_type=="value_variable" then
		output[#output+1]="}\n"
		output[#output+1]=("	"):rep(level).."for i="
		eva.translate(block.size,target,output,stack)
		output[#output+1]=",1,-1 do\n"
		output[#output+1]=("	"):rep(level+1)
		eva.translate(block.output,target,output,stack)
		output[#output+1]="[i]=false\n"
		output[#output+1]=("	"):rep(level).."end\n"
	end
end

subroutine.resize=function(block,target,output,stack)
	local level=0
	
	for i,parent in ipairs(stack) do
		if (
			parent.block_type=="value_subroutine" or
			parent.block_type=="subroutine_do" or
			parent.block_type=="subroutine_loop"
		) then
			level=level+1
		end
	end
	
	output[#output+1]=("	"):rep(level)
	output[#output+1]="for i="
	output[#output+1]="#"
	eva.translate(block.output,target,output,stack)
	output[#output+1]=","
	eva.translate(block.size,target,output,stack)
	output[#output+1]="+1,-1 do "
	eva.translate(block.output,target,output,stack)
	output[#output+1]="[i]=nil end\n"
	output[#output+1]=("	"):rep(level)
	output[#output+1]="for i=#"
	eva.translate(block.output,target,output,stack)
	output[#output+1]="+1,"
	eva.translate(block.size,target,output,stack)
	output[#output+1]=" do "
	eva.translate(block.output,target,output,stack)
	output[#output+1]="[i]=false end\n"
end

subroutine.measure=function(block,target,output,stack)
	local level=0
	
	for i,parent in ipairs(stack) do
		if (
			parent.block_type=="value_subroutine" or
			parent.block_type=="subroutine_do" or
			parent.block_type=="subroutine_loop"
		) then
			level=level+1
		end
	end
	
	output[#output+1]=("	"):rep(level)
	eva.translate(block.output,target,output,stack)
	output[#output+1]="=#"
	eva.translate(block.from,target,output,stack)
	output[#output+1]="\n"
end

subroutine.arithmetic=function(block,target,output,stack)
	local level=0
	
	for i,parent in ipairs(stack) do
		if (
			parent.block_type=="value_subroutine" or
			parent.block_type=="subroutine_do" or
			parent.block_type=="subroutine_loop"
		) then
			level=level+1
		end
	end
	
	output[#output+1]=("	"):rep(level)
	eva.translate(block.output,target,output,stack)
	output[#output+1]="="
	eva.translate(block.first,target,output,stack)
	output[#output+1]=block.operation
	eva.translate(block.second,target,output,stack)
	output[#output+1]="\n"
end

subroutine.compare=function(block,target,output,stack)
	local level=0
	
	for i,parent in ipairs(stack) do
		if (
			parent.block_type=="value_subroutine" or
			parent.block_type=="subroutine_do" or
			parent.block_type=="subroutine_loop"
		) then
			level=level+1
		end
	end
	
	output[#output+1]=("	"):rep(level)
	eva.translate(block.output,target,output,stack)
	output[#output+1]="="
	eva.translate(block.first,target,output,stack)
	output[#output+1]=block.operation
	eva.translate(block.second,target,output,stack)
	output[#output+1]="\n"
end

subroutine.type=function(block,target,output,stack)
	local level=0
	
	for i,parent in ipairs(stack) do
		if (
			parent.block_type=="value_subroutine" or
			parent.block_type=="subroutine_do" or
			parent.block_type=="subroutine_loop"
		) then
			level=level+1
		end
	end
	
	output[#output+1]=("	"):rep(level)
	eva.translate(block.output,target,output,stack)
	output[#output+1]="=(type("
	eva.translate(block.from,target,output,stack)
	output[#output+1]=[[)=="number" and 1) or ]]
	output[#output+1]="(type("
	eva.translate(block.from,target,output,stack)
	output[#output+1]=[[)=="table" and 2) or ]]
	output[#output+1]="(type("
	eva.translate(block.from,target,output,stack)
	output[#output+1]=[[)=="function" and 3) or 0]]
	output[#output+1]="\n"
end

subroutine.do_=function(block,target,output,stack)
	local level=0
	
	for i,parent in ipairs(stack) do
		if (
			parent.block_type=="value_subroutine" or
			parent.block_type=="subroutine_do" or
			parent.block_type=="subroutine_loop"
		) then
			level=level+1
		end
	end
	
	stack[#stack]=nil --Temporarily pop current block
	
	output[#output+1]=("	"):rep(level-1).."if "
	eva.translate(block.condition,target,output,stack)
	output[#output+1]="then\n"
	
	stack[#stack+1]=block
	
	table.sort(
		block.operations,
		function(a,b)
			return a.x^2+a.y^2<b.x^2+b.y^2
		end
	)
	
	for _,block_ in ipairs(block.operations) do
		eva.translate(block_,target,output,stack)
	end
	
	output[#output+1]=("	"):rep(level-1).."end\n"
end

subroutine.loop=function(block,target,output,stack)
	local level=0
	
	for i,parent in ipairs(stack) do
		if (
			parent.block_type=="value_subroutine" or
			parent.block_type=="subroutine_do" or
			parent.block_type=="subroutine_loop"
		) then
			level=level+1
		end
	end
	
	stack[#stack]=nil
	
	output[#output+1]=("	"):rep(level-1).."while "
	eva.translate(block.condition,target,output,stack)
	output[#output+1]=" and "
	eva.translate(block.condition,target,output,stack)
	output[#output+1]="~=0 "
	output[#output+1]="do\n"
	
	stack[#stack+1]=block
	
	table.sort(
		block.operations,
		function(a,b)
			return a.x^2+a.y^2<b.x^2+b.y^2
		end
	)
	
	for _,block_ in ipairs(block.operations) do
		eva.translate(block_,target,output,stack)
	end
	
	output[#output+1]=("	"):rep(level-1).."end\n"
end

subroutine.break_=function(block,target,output,stack)
	local level=0
	
	for i,parent in ipairs(stack) do
		if (
			parent.block_type=="value_subroutine" or
			parent.block_type=="subroutine_do" or
			parent.block_type=="subroutine_loop"
		) then
			level=level+1
		end
	end
	
	output[#output+1]=("	"):rep(level).."break\n"
end

subroutine.return_=function(block,target,output,stack)
	local level=0
	
	for i,parent in ipairs(stack) do
		if (
			parent.block_type=="value_subroutine" or
			parent.block_type=="subroutine_do" or
			parent.block_type=="subroutine_loop"
		) then
			level=level+1
		end
	end
	
	output[#output+1]=("	"):rep(level).."return "
	eva.translate(block.value,target,output,stack)
	output[#output+1]="\n"
end

subroutine.call=function(block,target,output,stack)
	local level=0
	
	for i,parent in ipairs(stack) do
		if (
			parent.block_type=="value_subroutine" or
			parent.block_type=="subroutine_do" or
			parent.block_type=="subroutine_loop"
		) then
			level=level+1
		end
	end
	
	output[#output+1]=("	"):rep(level)
	
	if block.output.block_type~="value_null" then
		eva.translate(block.output,target,output,stack)
		output[#output+1]="="
	end
	
	eva.translate(block.subroutine,target,output,stack)
	output[#output+1]="("
	
	for i,block_ in ipairs(block.arguments) do
		eva.translate(block_,target,output,stack)
		
		if i<#block.arguments then
			output[#output+1]=","
		end
	end
	
	output[#output+1]=")\n"
end

subroutine.inline=function(block,target,output,stack)
	local level=0
	
	for i,parent in ipairs(stack) do
		if (
			parent.block_type=="value_subroutine" or
			parent.block_type=="subroutine_do" or
			parent.block_type=="subroutine_loop"
		) then
			level=level+1
		end
	end
	
	output[#output+1]=("	"):rep(level).."do\n"
	output[#output+1]=("	"):rep(level+1)..block.code.."\n"
	output[#output+1]=("	"):rep(level).."end\n"
end

-------------------------------------------------------------------------------

return {
	blocks = {
		scope      = scope,
		value      = value,
		static     = static,
		subroutine = subroutine
	}
}
end