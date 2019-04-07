--util functions
local Util = {}

--return nice model name from model obj
function Util:GetNiceModelName(prop)
    local propModel = string.StripExtension(prop:GetModel())

    return string.GetFileFromFilename(propModel)
end

--clear all callbacks
function Util:RemoveCallbacks(callback)
    callback.Callbacks = {}
end

--print message to console with prefix
function Util:Log(...)
    local printResult = "\n"
    local args = {...}
    local colorH = args[1]
    print(colorH)

    if (isnumber(colorH)) then
        table.remove(args, 1)
    end

    for k, v in pairs(args) do
        printResult = printResult .. "\t\t" .. tostring(k) .. ":\t" .. tostring(v) .. "\n"
    end

    printResult = printResult .. "\n"
    MsgC(Color(255, 0, 255), "HoloEditor:\t", HSVToColor(colorH, 1, 1), printResult)
end

function Util:CreateCallback()
    local callbackmeta = {}

    function callbackmeta:__call(prop)
        for id, fun in pairs(self.Callbacks) do
            if (isfunction(fun)) then
                fun(prop)
            else
                self.Callbacks[id] = nil
            end
        end
    end

    local newTable = {
        Callbacks = {}
    }

    function newTable:AddCallback(a)
        self.Callbacks[#self.Callbacks + 1] = a
    end

    return setmetatable(newTable, callbackmeta)
end

--create prop table
function Util:CreatePropTable()
    local mt = {
        Count = 0
    }

    function mt:__newindex(key, value)
        if (key == "Count") then
            mt.Count = value
        else
            rawset(self, key, value)
        end
    end

    function mt:__index(key)
        if (key == "Count") then return mt.Count end
        local val = rawget(self, key)
        if (val) then return false end

        return val
    end

    return setmetatable({}, mt)
end

--remove value from table by key
function Util:RemoveFrom(tbl, key)
    if (tbl[key]) then
        tbl[key] = nil
        tbl.Count = tbl.Count - 1
    end
end

--add value to table
function Util:AddTo(tbl, key)
    if (tbl[key] == nil) then
        tbl[key] = true
        tbl.Count = tbl.Count + 1
    end
end

return Util