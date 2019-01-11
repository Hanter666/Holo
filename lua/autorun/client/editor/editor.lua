include("gui/d_workspace.lua")
include("gui/d_editor.lua")

local Editor = {
    Window = nil
}

function Editor:Create()
    if (IsValid(self.Window)) then
        self.Window:Close()
        self.Window = vgui.Create("HoloEditor")
    else
        self.Window = vgui.Create("HoloEditor")
    end
end

function Editor:Close()
    if (IsValid(self.Window)) then
        self.Window:Close()
    end
end

function Editor:SetGridSize(size)
    self.Window.WorkSpace:UpdateGrid(size)
end

function Editor:AddProp(modelName)
    local prop = ents.CreateClientProp(modelName)
    prop:SetPos(Vector(20 * #self.Window.Tree.ChildNodes, 0, 0)) --FIXME: для отладки выделения убрать нахой
    local propModel = string.StripExtension(modelName)
    local treeNode = self.Window.Tree:AddNode(string.GetFileFromFilename(propModel), "icon16/shape_square.png")
    treeNode.Prop = prop
    self.Window.WorkSpace:AddProp(prop)
    table.insert(self.Window.Tree.ChildNodes, treeNode)

    return prop
end

return Editor