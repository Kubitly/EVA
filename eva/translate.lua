return function(eva)

-------------------------------------------------------------------------------

local function translate(block,target,output,stack)
	stack=stack or {}
	
	local class,type_=block.block_type:match("(.+)_(.+)")
	
	if target.blocks[class][type_] then
		stack[#stack+1]=block
		target.blocks[class][type_](block,target,output,stack)
		stack[#stack]=nil
	else
		print(("Warning: %s is not implemented"):format(
			block.block_type
		))
	end
end

-------------------------------------------------------------------------------

return translate
end