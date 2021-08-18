return function(eva)

-------------------------------------------------------------------------------

local syntax_table={}

local function get_address_block(block,address)
	local current_block = block
	
	for i=1,#address,2 do
		local x = address[i].value
		local y = address[i+1].value
		
		if current_block.block_type=="static_group" then
			for _,block_ in ipairs(current_block.blocks) do
				if block_.x==x and block_.y==y then
					current_block=block_
					break
				end
			end
		elseif (
			current_block.block_type=="static_variable" and 
			current_block.value and
			current_block.value.block_type=="value_subroutine" 
		) then
			for _,block_ in ipairs(current_block.value.operations) do
				if block_.x==x and block_.y==y then
					current_block=block_
					break
				end
			end
		elseif (
			current_block.block_type=="subroutine_do_" or 
			current_block.block_type=="subroutine_loop" or
			current_block.block_type=="subroutine_for_"
		) then
			for _,block_ in ipairs(current_block.operations) do
				if block_.x==x and block_.y==y then
					current_block=block_
					break
				end
			end
		end
	end
	
	return current_block
end

local function get_address_scope(block,address)
	local scope = eva.blocks.scope.address({
		block.x,block.y
	})
	
	local next_scope=scope
	
	for _,token in ipairs(address.value) do
		if token.token_type=="number" then
			next_scope.address[#next_scope.address+1]=token.value
		elseif token.token_type=="index" then
			if token.value.token_type=="number" then
				next_scope.next_scope=eva.blocks.scope.index(
					eva.blocks.value.literal(token.value.value)
				)
				next_scope=next_scope.next_scope
			elseif token.value.token_type=="address" then
				next_scope.next_scope=eva.blocks.scope.index(
					get_address_scope(block,token.value)
				)
				next_scope=next_scope.next_scope
			end
		end
	end
	
	return scope
end

local function get_value_block(block,value)
	if not value then
		return
	end
	
	if value.token_type=="null" then
		return eva.blocks.value.null()
	elseif value.token_type=="number" then
		return eva.blocks.value.literal(value.value)
	elseif value.token_type=="table" then
		local table_block=eva.blocks.value.table()
		
		for i,token in ipairs(value.value) do
			table_block.contents[i]=get_value_block(block,token)
		end
		
		return table_block
	elseif value.token_type=="address" then
		return eva.blocks.value.variable(
			get_address_scope(block,value)
		)
	end
end

-------------------------------------------------------------------------------

syntax_table["group"]=function(block,statement)
	local address = statement[1]
	
	local parent = get_address_block(
		block,address.value
	)
	
	parent.blocks[#parent.blocks+1]=eva.blocks.static.group(
		address.value[#address.value-1].value,
		address.value[#address.value].value
	)
end

syntax_table["subroutine"]=function(block,statement)
	local address = statement[1]
	
	local parent = get_address_block(
		block,address.value
	)
	
	parent.blocks[#parent.blocks+1]=eva.blocks.static.variable(
		address.value[#address.value-1].value,
		address.value[#address.value].value,
		eva.blocks.value.subroutine()
	)
end

syntax_table["do"]=function(block,statement)
	local address   = statement[1]
	local condition = statement[3]
	
	local parent = get_address_block(
		block,address.value
	)
	
	if parent.block_type=="static_variable" then
		parent=parent.value
	end
	
	parent.operations[#parent.operations+1]=eva.blocks.subroutine.do_(
		address.value[#address.value-1].value,
		address.value[#address.value].value,
		get_value_block(block,condition)
	)
end

syntax_table["loop"]=function(block,statement)
	local address   = statement[1]
	local condition = statement[3]
	
	local parent = get_address_block(
		block,address.value
	)
	
	if parent.block_type=="static_variable" then
		parent=parent.value
	end
	
	parent.operations[#parent.operations+1]=eva.blocks.subroutine.loop(
		address.value[#address.value-1].value,
		address.value[#address.value].value,
		get_value_block(block,condition)
	)
end

syntax_table["for"]=function(block,statement)
	local address = statement[1]
	local target  = statement[3]
	local start   = statement[4]
	local end_    = statement[5]
	local step    = statement[6]
	
	local parent = get_address_block(
		block,address.value
	)
	
	if parent.block_type=="static_variable" then
		parent=parent.value
	end
	
	parent.operations[#parent.operations+1]=eva.blocks.subroutine.for_(
		address.value[#address.value-1].value,
		address.value[#address.value].value,
		get_value_block(block,target),
		get_value_block(block,start),
		get_value_block(block,end_),
		get_value_block(block,step)
	)
end

syntax_table["break"]=function(block,statement)
	local address = statement[1]
	
	local parent = get_address_block(
		block,address.value
	)
	
	if parent.block_type=="static_variable" then
		parent=parent.value
	end
	
	parent.operations[#parent.operations+1]=eva.blocks.subroutine.inline(
		address.value[#address.value-1].value,
		address.value[#address.value].value,
		eva.blocks.subroutine.break_()
	)
end

syntax_table["variable"]=function(block,statement)
	local address = statement[1]
	local value   = statement[3]
	
	local parent = get_address_block(
		block,address.value
	)
	
	if parent.block_type=="static_variable" then --Assume it's a subroutine
		parent=parent.value
	end
	
	parent.operations[#parent.operations+1]=eva.blocks.subroutine.variable(
		address.value[#address.value-1].value,
		address.value[#address.value].value,
		get_value_block(block,value)
	)
end

syntax_table["argument"]=function(block,statement)
	local address = statement[1]
	
	local parent = get_address_block(
		block,address.value
	)
	
	if parent.block_type=="static_variable" then
		parent=parent.value
	end
	
	parent.operations[#parent.operations+1]=eva.blocks.subroutine.argument(
		address.value[#address.value-1].value,
		address.value[#address.value].value
	)
end

syntax_table["set"]=function(block,statement)
	local address = statement[1]
	local target  = statement[3]
	local from    = statement[4]
	
	local parent = get_address_block(
		block,address.value
	)
	
	if parent.block_type=="static_variable" then
		parent=parent.value
	end
	
	parent.operations[#parent.operations+1]=eva.blocks.subroutine.set(
		address.value[#address.value-1].value,
		address.value[#address.value].value,
		get_value_block(block,target),
		get_value_block(block,from)
	)
end

syntax_table["allocate"]=function(block,statement)
	local address  = statement[1]
	local target   = statement[3]
	local size     = statement[4]
	local contents = statement[5]
	
	local parent = get_address_block(
		block,address.value
	)
	
	if parent.block_type=="static_variable" then
		parent=parent.value
	end
	
	parent.operations[#parent.operations+1]=eva.blocks.subroutine.allocate(
		address.value[#address.value-1].value,
		address.value[#address.value].value,
		get_value_block(block,target),
		get_value_block(block,size),
		get_value_block(block,contents)
	)
end

syntax_table["resize"]=function(block,statement)
	local address = statement[1]
	local target  = statement[3]
	local size    = statement[4]
	
	local parent = get_address_block(
		block,address.value
	)
	
	if parent.block_type=="static_variable" then
		parent=parent.value
	end
	
	parent.operations[#parent.operations+1]=eva.blocks.subroutine.resize(
		address.value[#address.value-1].value,
		address.value[#address.value].value,
		get_value_block(block,target),
		get_value_block(block,size)
	)
end

syntax_table["measure"]=function(block,statement)
	local address = statement[1]
	local target  = statement[3]
	local from    = statement[4]
	
	local parent = get_address_block(
		block,address.value
	)
	
	if parent.block_type=="static_variable" then
		parent=parent.value
	end
	
	parent.operations[#parent.operations+1]=eva.blocks.subroutine.measure(
		address.value[#address.value-1].value,
		address.value[#address.value].value,
		get_value_block(block,target),
		get_value_block(block,from)
	)
end

syntax_table["arithmetic"]=function(block,statement)
	local address   = statement[1]
	local target    = statement[3]
	local operation = statement[4]
	local first     = statement[5]
	local second    = statement[6]
	
	local parent = get_address_block(
		block,address.value
	)
	
	if parent.block_type=="static_variable" then
		parent=parent.value
	end
	
	parent.operations[#parent.operations+1]=eva.blocks.subroutine.arithmetic(
		address.value[#address.value-1].value,
		address.value[#address.value].value,
		get_value_block(block,target),
		(
			(operation.value=="add" and "+") or
			(operation.value=="subtract" and "-") or
			(operation.value=="multiply" and "*") or
			(operation.value=="divide" and "/") or
			(operation.value=="modulo" and "%") or
			(operation.value=="power" and "^")
		),
		get_value_block(block,first),
		get_value_block(block,second)
	)
end

syntax_table["compare"]=function(block,statement)
	local address   = statement[1]
	local target    = statement[3]
	local operation = statement[4]
	local first     = statement[5]
	local second    = statement[6]
	
	local parent = get_address_block(
		block,address.value
	)
	
	if parent.block_type=="static_variable" then
		parent=parent.value
	end
	
	parent.operations[#parent.operations+1]=eva.blocks.subroutine.compare(
		address.value[#address.value-1].value,
		address.value[#address.value].value,
		get_value_block(block,target),
		(
			(operation.value=="or" and "|") or
			(operation.value=="and" and "&") or
			(operation.value=="equal" and "==") or
			(operation.value=="less" and "<") or
			(operation.value=="greater" and ">")
		),
		get_value_block(block,first),
		get_value_block(block,second)
	)
end

syntax_table["type"]=function(block,statement)
	local address = statement[1]
	local target  = statement[3]
	local from    = statement[4]
	
	local parent = get_address_block(
		block,address.value
	)
	
	if parent.block_type=="static_variable" then
		parent=parent.value
	end
	
	parent.operations[#parent.operations+1]=eva.blocks.subroutine.type(
		address.value[#address.value-1].value,
		address.value[#address.value].value,
		get_value_block(block,target),
		get_value_block(block,from)
	)
end

syntax_table["call"]=function(block,statement)
	local address   = statement[1]
	local target    = statement[3]
	local from      = statement[4]
	local arguments = statement[5]
	
	local parent = get_address_block(
		block,address.value
	)
	
	if parent.block_type=="static_variable" then
		parent=parent.value
	end
	
	parent.operations[#parent.operations+1]=eva.blocks.subroutine.call(
		address.value[#address.value-1].value,
		address.value[#address.value].value,
		get_value_block(block,target),
		get_value_block(block,from),
		get_value_block(block,arguments)
	)
end

syntax_table["return"]=function(block,statement)
	local address = statement[1]
	local value   = statement[3]
	
	local parent = get_address_block(
		block,address.value
	)
	
	if parent.block_type=="static_variable" then
		parent=parent.value
	end
	
	parent.operations[#parent.operations+1]=eva.blocks.subroutine.return_(
		address.value[#address.value-1].value,
		address.value[#address.value].value,
		get_value_block(block,value)
	)
end

syntax_table["inline"]=function(block,statement)
	local address = statement[1]
	local code    = statement[3]
	
	local parent = get_address_block(
		block,address.value
	)
	
	if parent.block_type=="static_variable" then
		parent=parent.value
	end
	
	if code then
		code=code.value
		
		local address_string=("_%d_%d"):format(block.x,block.y)
		for i=1,#address.value-2 do
			address_string=address_string..("_%d"):format(
				address.value[i].value
			)
		end
		
		while code:match("__%d+,%d+__") do
			local x=code:match("__(%d+),")
			local y=code:match(",(%d+)__")
			
			code=code:gsub(
				"__%d+,%d+__",
				address_string..("_%s_%s"):format(x,y),1
			)
		end
	end
	
	parent.operations[#parent.operations+1]=eva.blocks.subroutine.inline(
		address.value[#address.value-1].value,
		address.value[#address.value].value,
		code
	)
end

-------------------------------------------------------------------------------

local function construct(tokens)
	local block=eva.blocks.static.group(0,0,{})
	
	for _,statement in ipairs(tokens) do
		local address     = statement[1].value
		local instruction = statement[2].value
		
		if syntax_table[instruction] then
			syntax_table[instruction](block,statement)
		end
	end
	
	return block
end

-------------------------------------------------------------------------------

return construct
end