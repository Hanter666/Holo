local Editor = include("editor/editor.lua")

concommand.Add("holo", function()
    Editor:Create()
    local prop1 = Editor:AddProp("models/holograms/cube.mdl")
    local prop2 = Editor:AddProp("models/holograms/sphere.mdl")
end)