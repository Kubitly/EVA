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
	
	local condition_block
	
	if condition.token_type=="number" then
		condition_block=eva.blocks.value.literal(
			condition.value
		)
	elseif condition.token_type=="address" then
		condition_block=eva.blocks.value.variable(
			get_address_scope(block,condition)
		)
	elseif condition.token_type=="null" then --Idk why but sure
		condition_block=eva.blocks.value.null()
	end
	
	parent.operations[#parent.operations+1]=eva.blocks.subroutine.do_(
		address.value[#address.value-1].value,
		address.value[#address.value].value,
		condition_block
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
	
	local condition_block
	
	if condition.token_type=="number" then
		condition_block=eva.blocks.value.literal(
			condition.value
		)
	elseif condition.token_type=="address" then
		condition_block=eva.blocks.value.variable(
			get_address_scope(block,condition)
		)
	elseif condition.token_type=="null" then
		condition_block=eva.blocks.value.null()
	end
	
	parent.operations[#parent.operations+1]=eva.blocks.subroutine.loop(
		address.value[#address.value-1].value,
		address.value[#address.value].value,
		condition_block
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
	
	local start_block
	
	if start.token_type=="number" then
		start_block=eva.blocks.value.literal(
			start.value
		)
	elseif start.token_type=="address" then
		start_block=eva.blocks.value.variable(
			get_address_scope(block,start)
		)
	end
	
	local end_block
	
	if end_.token_type=="number" then
		end_block=eva.blocks.value.literal(
			end_.value
		)
	elseif end_.token_type=="address" then
		end_block=eva.blocks.value.variable(
			get_address_scope(block,end_)
		)
	end
	
	local step_block --What are you doing step block!?
	
	if step.token_type=="number" then
		step_block=eva.blocks.value.literal(
			step.value
		)
	elseif step.token_type=="address" then
		step_block=eva.blocks.value.variable(
			get_address_scope(block,step)
		)
	end
	
	parent.operations[#parent.operations+1]=eva.blocks.subroutine.for_(
		address.value[#address.value-1].value,
		address.value[#address.value].value,
		eva.blocks.value.variable(
			get_address_scope(block,target)
		),
		start_block,end_block,step_block
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
	
	local parent = get_address_block(
		block,address.value
	)
	
	if parent.block_type=="static_variable" then --Assume it's a subroutine
		parent=parent.value
	end
	
	parent.operations[#parent.operations+1]=eva.blocks.subroutine.variable(
		address.value[#address.value-1].value,
		address.value[#address.value].value
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
	
	local from_block
	
	if from.token_type=="number" then
		from_block=eva.blocks.value.literal(from.value)
	elseif from.token_type=="null" then
		from_block=eva.blocks.value.null()
	elseif from.token_type=="address" then
		from_block=eva.blocks.value.variable(
			get_address_scope(block,from)
		)
	end
	
	parent.operations[#parent.operations+1]=eva.blocks.subroutine.set(
		address.value[#address.value-1].value,
		address.value[#address.value].value,
		eva.blocks.value.variable(
			get_address_scope(block,target)
		),
		from_block
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
	
	local target_block=eva.blocks.value.variable(
		get_address_scope(block,target)
	)
	local size_block
	local content_blocks={}
	
	if size.token_type=="number" then
		size_block=eva.blocks.value.literal(size.value)
	elseif size.token_type=="address" then
		size_block=eva.blocks.value.variable(
			get_address_scope(block,size)
		)
	end
	
	if contents then
		for _,token in ipairs(contents.value) do
			if token.token_type=="number" then
				content_blocks[#content_blocks+1]=eva.blocks.value.literal(
					token.value
				)
			elseif token.token_type=="null" then
				content_blocks[#content_blocks+1]=eva.blocks.value.null()
			end
		end
	end
	
	parent.operations[#parent.operations+1]=eva.blocks.subroutine.allocate(
		address.value[#address.value-1].value,
		address.value[#address.value].value,
		target_block,size_block,content_blocks
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
	
	local size_block
	
	if size.token_type=="number" then
		size_block=eva.blocks.value.literal(size.value)
	elseif size.token_type=="address" then
		size_block=eva.blocks.value.variable(
			get_address_scope(block,size)
		)
	end
	
	parent.operations[#parent.operations+1]=eva.blocks.subroutine.resize(
		address.value[#address.value-1].value,
		address.value[#address.value].value,
		eva.blocks.value.variable(
			get_address_scope(block,target)
		),
		size_block
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
		eva.blocks.value.variable(
			get_address_scope(block,target)
		),
		eva.blocks.value.variable(
			get_address_scope(block,from)
		)
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
	
	local first_block
	local second_block
	
	if first.token_type=="number" then
		first_block=eva.blocks.value.literal(first.value)
	elseif first.token_type=="address" then
		first_block=eva.blocks.value.variable(
			get_address_scope(block,first)
		)
	end
	
	if second.token_type=="number" then
		second_block=eva.blocks.value.literal(second.value)
	elseif second.token_type=="address" then
		second_block=eva.blocks.value.variable(
			get_address_scope(block,second)
		)
	end
	
	parent.operations[#parent.operations+1]=eva.blocks.subroutine.arithmetic(
		address.value[#address.value-1].value,
		address.value[#address.value].value,
		eva.blocks.value.variable(
			get_address_scope(block,target)
		),
		(
			(operation.value=="add" and "+") or
			(operation.value=="subtract" and "-") or
			(operation.value=="multiply" and "*") or
			(operation.value=="divide" and "/") or
			(operation.value=="modulo" and "%") or
			(operation.value=="power" and "^")
		),
		first_block,second_block
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
	
	local first_block
	local second_block
	
	if first.token_type=="number" then
		first_block=eva.blocks.value.literal(first.value)
	elseif first.token_type=="address" then
		first_block=eva.blocks.value.variable(
			get_address_scope(block,first)
		)
	end
	
	if second.token_type=="number" then
		second_block=eva.blocks.value.literal(second.value)
	elseif second.token_type=="address" then
		second_block=eva.blocks.value.variable(
			get_address_scope(block,second)
		)
	end
	
	parent.operations[#parent.operations+1]=eva.blocks.subroutine.compare(
		address.value[#address.value-1].value,
		address.value[#address.value].value,
		eva.blocks.value.variable(
			get_address_scope(block,target)
		),
		(
			(operation.value=="or" and "|") or
			(operation.value=="and" and "&") or
			(operation.value=="equal" and "==") or
			(operation.value=="less" and "<") or
			(operation.value=="greater" and ">")
		),
		first_block,second_block
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
	
	local from_block
	
	if from.token_type=="number" then
		from_block=eva.blocks.value.literal(from.value)
	elseif from.token_type=="null" then
		from_block=eva.blocks.value.null()
	elseif from.token_type=="address" then
		from_block=eva.blocks.value.variable(
			get_address_scope(block,from)
		)
	end
	
	parent.operations[#parent.operations+1]=eva.blocks.subroutine.type(
		address.value[#address.value-1].value,
		address.value[#address.value].value,
		eva.blocks.value.variable(
			get_address_scope(block,target)
		),
		from_block
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
	
	local target_block
	
	if target.token_type=="null" then
		target_block=eva.blocks.value.null()
	elseif target.token_type=="address" then
		target_block=eva.blocks.value.variable(
			get_address_scope(block,target)
		)
	end
	
	local from_block=eva.blocks.value.variable(
		get_address_scope(block,from)
	)
	
	local arguments_block={}
	
	if arguments then
		for _,token in ipairs(arguments.value) do
			if token.token_type=="number" then
				arguments_block[#arguments_block+1]=eva.blocks.value.literal(
					token.value
				)
			elseif token.token_type=="null" then
				arguments_block[#arguments_block+1]=eva.blocks.value.null()
			elseif token.token_type=="address" then
				arguments_block[#arguments_block+1]=eva.blocks.value.variable(
					get_address_scope(block,token)
				)
			end
		end
	end
	
	parent.operations[#parent.operations+1]=eva.blocks.subroutine.call(
		address.value[#address.value-1].value,
		address.value[#address.value].value,
		target_block,from_block,arguments_block
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
	
	local value_block
	
	if value then
		if value.token_type=="number" then
			value_block=eva.blocks.value.literal(value.value)
		elseif value.token_type=="address" then
			value_block=eva.blocks.value.variable(
				get_address_scope(block,value)
			)
		end
	end
	
	parent.operations[#parent.operations+1]=eva.blocks.subroutine.return_(
		address.value[#address.value-1].value,
		address.value[#address.value].value,
		value_block
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