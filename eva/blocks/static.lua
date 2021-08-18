local static={}

-------------------------------------------------------------------------------

static.group=function(x,y,blocks)
	local block={
		block_type = "static_group",
		x          = x,
		y          = y,
		blocks     = blocks or {}
	}
	
	return block
end

static.variable=function(x,y,value)
	local block={
		block_type = "static_variable",
		x          = x,
		y          = y,
		value      = value
	}
	
	return block
end

-------------------------------------------------------------------------------

return static