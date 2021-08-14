local scope={}

-------------------------------------------------------------------------------

scope.level=function(level,next_scope)
	local block={
		block_type = "scope_level",
		level      = level,
		next_scope = next_scope
	}
	
	return block
end

scope.position=function(x,y,next_scope)
	local block={
		block_type = "scope_position",
		x          = x,
		y          = y,
		next_scope = next_scope
	}
	
	return block
end

scope.index=function(index,next_scope)
	local block={
		block_type = "scope_index",
		index      = index,       --Can be literal or variable
		next_scope = next_scope
	}
	
	return block
end

-------------------------------------------------------------------------------

return scope