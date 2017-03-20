
require "lfs"

local function GetProjectPath()
    local path = lfs.currentdir()
    path = string.gsub(path, "\\", "/")
    return path
end

local projectPath = GetProjectPath()

---需要导出的文件或路径
local filesPath = {
    "/Examples"
}

local savePath = projectPath.."/lua.json"

local pattern = "function%s+(%w+)([%.:])(%w+)%("
local jsonTemplatePath = projectPath.."/snippetstemplate.json"

local function findindir (path, wefind, r_table, intofolder)
	for file in lfs.dir(path) do
		if file ~= "." and file ~= ".." then
			local f = path..'\\'..file
			--print ("/t "..f)
			if string.find(f, wefind) ~= nil then
				--print("/t "..f)
				table.insert(r_table, f)
			end
			local attr = lfs.attributes (f)
			assert (type(attr) == "table")
			if attr.mode == "directory" and intofolder then
				findindir (f, wefind, r_table, intofolder)
			else
				--for name, value in pairs(attr) do
				--	print (name, value)
				--end
			end
		end
	end
end

local function GetFileName(filepath, stripextension)
    stripextension = stripextension or false
    local filename = string.match(filepath, ".+/([^/]*%.%w+)$")
    if stripextension == true then
        local idx = filename:match(".+()%.%w+$")  
        if idx then  
            return filename:sub(1, idx-1)  
        end
    end
    return filename
end

local function Export(path)
    local filename = GetFileName(path, true)
    local f = io.open(path, "r")
    local result = ""
    for line in f:lines() do
        for i, j, k in string.gmatch(line, pattern) do
            local funcname = string.format("%s%s%s", filename, j, k)
            result = result..string.format("\t%q:{\n\t\t\"body\": %q,\n\t\t\"description\": %q,\n\t\t\"prefix\": %q\n\t},\n", funcname, funcname.."()", funcname, funcname)
        end
    end
    f:close()
    return result
end

local function ExportAll()
    local json = ""
    for i, filepath in ipairs(filesPath) do
        local path = string.format("%s%s", projectPath, filepath)
        local allfile = {}
        findindir(path, "%.lua$", allfile, true)
        if #allfile > 0 then
            for j, p in pairs(allfile) do
                p = string.gsub(p, "\\", "/" )
                json = json..Export(p)
            end
        else
            json = json..Export(path)
        end
    end

    print(json)

    local f = io.open(jsonTemplatePath, "r")
    local template = ""
    for line in f:lines() do
       template = template.."\n"..line
    end
    f:close()

    template = string.gsub(template, "//replace with my snippets", json)
    local savefile = io.open(savePath, "w")
    savefile:write(template)
    savefile:close()

    print(string.format("save done ===> (%s).", savePath))
end

ExportAll()