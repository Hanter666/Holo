include("includes/modules/holoeditor.lua") --reload
require("HoloEditor")
include("gui/d_tree.lua")
include("gui/d_workspace.lua")
include("gui/d_editor.lua")
HoloEditor:Init()

concommand.Add("holo", function()

    if (not HoloEditor:LoadProject("delorean")) then
      for i = 1, 5 do
          HoloEditor:AddProp("models/holograms/sphere.mdl")
      end
    end
    HoloEditor:Open()
end)