local subroutine={}

-------------------------------------------------------------------------------

subroutine.variable=function(x,y)
	local block={
		block_type = "subroutine_variable",
		x          = x,
		y          = y
	}
	
	return block
end

subroutine.argument=function(x,y) --Basically same as variable
	local block={
		block_type = "subroutine_argument",
		x          = x,
		y          = y
	}
	
	return block
end

subroutine.set=function(x,y,output,value_)
	local block={
		block_type = "subroutine_set",
		x          = x,
		y          = y,
		output     = output,
		value      = value_
	}
	
	return block
end

subroutine.allocate=function(x,y,output,size,contents)
	local block={
		block_type = "subroutine_allocate",
		x          = x,
		y          = y,
		output     = output,
		size       = size,
		contents   = contents or {}
	}
	
	return block
end

subroutine.resize=function(x,y,output,size)
	local block={
		block_type = "subroutine_resize",
		x          = x,
		y          = y,
		output     = output,
		size       = size
	}
	
	return block
end

subroutine.measure=function(x,y,output,from)
	local block={
		block_type = "subroutine_measure",
		x          = x,
		y          = y,
		output     = output,
		from       = from
	}
	
	return block
end

subroutine.arithmetic=function(x,y,output,operation,first,second)
	local block={
		block_type = "subroutine_arithmetic",
		x          = x,
		y          = y,
		output     = output,
		operation  = operation,
		first      = first,
		second     = second
	}
	
	return block
end

subroutine.compare=function(x,y,output,operation,first,second)
	local block={
		block_type = "subroutine_compare",
		x          = x,
		y          = y,
		output     = output,
		operation  = operation,
		first      = first,
		second     = second
	}
	
	return block
end

subroutine.type=function(x,y,output,from)
	local block={
		block_type = "subroutine_type",
		x          = x,
		y          = y,
		output     = output,
		from       = from
	}
	
	return block
end

subroutine.do_=function(x,y,condition,operations)
	local block={
		block_type = "subroutine_do_",
		x          = x,
		y          = y,
		condition  = condition,
		operations = operations or {}
	}
	
	return block
end

subroutine.loop=function(x,y,condition,operations)
	local block={
		block_type = "subroutine_loop",
		x          = x,
		y          = y,
		condition  = condition,
		operations = operations or {}
	}
	
	return block
end

subroutine.break_=function(x,y)
	local block={
		block_type = "subroutine_break_",
		x          = x,
		y          = y
	}
	
	return block
end

subroutine.return_=function(x,y,value_)
	local block={
		block_type = "subroutine_return_",
		x          = x,
		y          = y,
		value      = value_
	}
	
	return block
end

subroutine.call=function(x,y,output,subroutine_,arguments)
	local block={
		block_type = "subroutine_call",
		x          = x,
		y          = y,
		output     = output,
		subroutine = subroutine_,
		arguments  = arguments
	}
	
	return block
end

subroutine.inline=function(x,y,code)
	local block={
		block_type = "subroutine_inline",
		x          = x,
		y          = y,
		code       = code
	}
	
	return block
end

-------------------------------------------------------------------------------

return subroutine