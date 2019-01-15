include("includes/modules/holoeditor.lua") --reload
require("HoloEditor")
include("gui/d_tree.lua")
include("gui/d_workspace.lua")
include("gui/d_editor.lua")
HoloEditor:Init()

concommand.Add("holo", function()
    for i = 1, 5 do
        HoloEditor:AddProp("models/holograms/sphere.mdl")
    end

    PrintTable(HoloEditor.DeselectedProps)
    HoloEditor:Open()
end)