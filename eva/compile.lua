return function(eva)

-------------------------------------------------------------------------------

local function compile(block,target)
	local output={}
	
	if target.header then
		output[#output+1]=target.header.."\n"
	end
	
	eva.translate(block,target,output)
	
	if target.footer then
		output[#output+1]="\n"..target.footer.."\n"
	end
	
	return table.concat(output)
end

-------------------------------------------------------------------------------

return compile
end