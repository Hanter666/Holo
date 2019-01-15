include("includes/modules/holoeditor.lua") --reload
require("HoloEditor")
include("gui/d_tree.lua")
include("gui/d_workspace.lua")
include("gui/d_editor.lua")
HoloEditor:Init()

concommand.Add("holo", function()
    if (not HoloEditor:LoadProject("delorean")) then
        HoloEditor:AddProp("models/holograms/sphere.mdl")
        HoloEditor:AddProp("models/holograms/cube.mdl")
        HoloEditor:AddProp("models/holograms/cube.mdl")
        HoloEditor:AddProp("models/holograms/sphere.mdl")
    end

    HoloEditor:Open()
end)