local scope={}

-------------------------------------------------------------------------------

scope.address=function(address,next_scope)
	local block={
		block_type = "scope_address",
		address    = address or {},
		next_scope = next_scope
	}
	
	return block
end

scope.index=function(index,next_scope)
	local block={
		block_type = "scope_index",
		index      = index,
		next_scope = next_scope
	}
	
	return block
end

-------------------------------------------------------------------------------

return scope