return function(eva) --Wrote this shit while sleep deprived

-------------------------------------------------------------------------------

local parse_table={}

local function tokenize(line)
	for _,parser in ipairs(parse_table) do
		local token,nline=parser(line)
		
		if token then
			return token,nline
		end
	end
end

-------------------------------------------------------------------------------

parse_table[#parse_table+1]=function(line)
	if line:sub(1,1)~="<" then
		return
	end
	
	local address={
		token_type = "address",
		value      = {}
	}
	
	while line:sub(1,1)~=">" do
		local ntoken,nline=tokenize(line:sub(2,#line))
		
		if ntoken then
			address.value[#address.value+1]=ntoken
			line=nline
		else
			line=line:sub(2,#line)
		end
	end
	
	return address,line:sub(2,#line)
end

parse_table[#parse_table+1]=function(line)
	if line:sub(1,1)~="{" then
		return
	end
	
	local table_={
		token_type = "table",
		value      = {}
	}
	
	while line:sub(1,1)~="}" do
		local ntoken,nline=tokenize(line:sub(2,#line))
		
		if ntoken then
			table_.value[#table_.value+1]=ntoken
			line=nline
		else
			line=line:sub(2,#line)
		end
	end
	
	return table_,line:sub(2,#line)
end

parse_table[#parse_table+1]=function(line)
	if line:sub(1,1)~="[" then
		return
	end
	
	local index={
		token_type = "index",
		value      = nil
	}
	
	while line:sub(1,1)~="]" and not index.value do
		local ntoken,nline=tokenize(line:sub(2,#line))
		
		if ntoken then
			index.value=ntoken
			line=nline
		else
			line=line:sub(2,#line)
		end
	end
	
	return index,line:sub(2,#line)
end

parse_table[#parse_table+1]=function(line)
	if line:sub(1,1)~="_" then
		return
	end
	
	local null={
		token_type = "null"
	}
	
	return null,line:sub(2,#line)
end

parse_table[#parse_table+1]=function(line)
	if line:sub(1,1)~='"' then
		return
	end
	
	local string_={
		token_type = "string",
		value      = line:match([["([^"]+)]])
	}
	
	return string_,line:match([["[^"]+.(.*)]])
end

parse_table[#parse_table+1]=function(line)
	if not tonumber(line:sub(1,1)) then
		return
	end
	
	local number={
		token_type = "number",
		value      = tonumber(line:match("%d[%d.]*"))
	}
	
	return number,line:match("%d[%d.]*(.*)")
end

parse_table[#parse_table+1]=function(line)
	if line:sub(1,1):gsub("%A","")=="" then
		return
	end
	
	local instruction={
		token_type = "instruction",
		value      = line:match("%a+")
	}
	
	return instruction,line:match("%a+(.*)")
end

-------------------------------------------------------------------------------

local function list_token(token)
	local value=""
	
	if type(token.value)=="table" then
		value="<"
		
		for i,token_ in ipairs(token.value) do
			value=value..list_token(token_)
			
			if i<#token.value then
				value=value..", "
			end
		end
		
		value=value..">"
	else
		value=token.value
	end
	
	return ("%s: %s"):format(token.token_type,value)
end

-------------------------------------------------------------------------------

local function parse(source)
	local tokens={}
	
	for line in string.gmatch(source,"[^\r\n;]+") do
		local statement={}
		
		while #line:gsub("%s","")>0 do
			local token,nline=tokenize(line)
			
			if token then
				statement[#statement+1]=token
				line=nline
			else
				line=line:sub(2,#line)
			end
		end
		
		tokens[#tokens+1]=statement
	end
	
	return tokens
end

-------------------------------------------------------------------------------

return parse
end