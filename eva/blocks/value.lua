local value={}

-------------------------------------------------------------------------------

value.null=function()
	local block={
		block_type = "value_null"
	}
	
	return block
end

value.literal=function(value)
	local block={
		block_type = "value_literal",
		value      = value
	}
	
	return block
end

value.variable=function(scope)
	local block={
		block_type = "value_variable",
		scope      = scope
	}
	
	return block
end

value.table=function(contents)
	local block={
		block_type = "value_table",
		contents   = contents or {}
	}
	
	return block
end

value.subroutine=function(operations)
	local block={
		block_type = "value_subroutine",
		operations = operations or {}
	}
	
	return block
end

-------------------------------------------------------------------------------

return value