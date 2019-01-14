include("includes/modules/holoeditor.lua") --reload
require("HoloEditor")
include("gui/d_tree.lua")
include("gui/d_workspace.lua")
include("gui/d_editor.lua")
HoloEditor:Init()

concommand.Add("holo", function()
    if (HoloEditor:LoadProject()) then
        --HoloEditor:SaveProject()
        YEEE = not BOIIIIIII
    else
        HoloEditor:AddProp("models/holograms/sphere.mdl")
        HoloEditor:AddProp("models/holograms/cube.mdl")
        HoloEditor:AddProp("models/holograms/cube.mdl")
        HoloEditor:AddProp("models/holograms/sphere.mdl")
    end

    HoloEditor:Open()
end)