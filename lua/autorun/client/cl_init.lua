include("includes/modules/holoeditor.lua") --reload
require("HoloEditor")
include("gui/d_tree.lua")
include("gui/d_workspace.lua")
include("gui/d_editor.lua")
HoloEditor:Init()

concommand.Add("holo", function()
    local prop1 = HoloEditor:AddProp("models/holograms/rcube_thin.mdl")

    for i = 1, 50 do
        HoloEditor:AddProp("models/holograms/sphere.mdl")
    end

    --HoloEditor:RemoveProp(prop1)
    HoloEditor:Open()
end)