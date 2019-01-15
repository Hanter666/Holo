local Util = HoloEditor.Util
local Render = HoloEditor.Render
local PANEL = {}

function PANEL:Init()
    self:SetDraggable(false)
    self:SetScreenLock(true)
    self:SetSize(ScrW(), ScrH())
    self:DockPadding(0, 29, 0, 0)
    self:MakePopup()
    --TODO: add ang alight menu bar
    --self.MenuBar = vgui.Create("DMenuBar", self)
    --self.MenuBar:Dock(TOP)
    --self.MenuBar:DockMargin(100, 0, 100, 0)
    self.ToolsPanel = vgui.Create("DPanel", self)
    self.ToolsPanel:Dock(LEFT)
    self.ToolsPanel:SetWide(48)
    local DermaButton = vgui.Create("DButton", self.ToolsPanel)
    DermaButton:Dock(TOP)
    DermaButton:SetText("Say hi")
    DermaButton:SetSize(250, 30)
    DermaButton.DoClick = function() end

    function self.ToolsPanel:Paint(w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(27, 30, 43))
        surface.SetDrawColor(17, 19, 27)
        self:DrawOutlinedRect()
    end

    --FIXME: big tree slowdown fps ~50 elements -40 fps
    self.Tree = vgui.Create("D_Tree", self)
    self.Tree:Dock(RIGHT)
    self.Tree:SetWide(124)

    --TODO: fix code dublication
    HoloEditor.OnPropAdded:AddCallback(function(prop)
        local niceName = Util:GetNiceModelName(prop)
        local treeNode = self.Tree:AddNode(niceName, "icon16/shape_square.png")
        treeNode.Prop = prop

        function treeNode.DoClick(slf)
            local nodeProp = slf.Prop

            if (HoloEditor:IsSelectedProp(nodeProp)) then
                HoloEditor:DeselectProp(nodeProp)
            else
                HoloEditor:SelectProp(nodeProp)
            end

            return false
        end

        self.Tree:SetSelectedItem(treeNode)
    end)

    HoloEditor.OnPropRemoved:AddCallback(slf, function(prop)
        for _, treeNode in pairs(self.Tree.RootNode:GetChildren()) do
            if (treeNode.Prop == prop) then
                treeNode:Remove()
                break
            end
        end
    end)

    HoloEditor.OnPropSelected:AddCallback(function(prop)
        self.Tree:ChangeSelection(prop)
    end)

    HoloEditor.OnPropDeselected:AddCallback(function(prop)
        self.Tree:ChangeSelection(prop)
    end)

    self.WorkSpace = vgui.Create("D_Workspace", self)
    self.WorkSpace:Dock(FILL)
end

function PANEL:Paint(w, h)
    draw.RoundedBox(0, 0, 0, w, 28, Color(27, 30, 43))
    surface.SetDrawColor(17, 19, 27)
    surface.DrawLine(-1, 28, w, 28)
    draw.RoundedBox(0, 0, 29, w, h - 29, Color(41, 45, 62))
end

function PANEL:OnClose()
    Util:RemoveCallbacks()
    HoloEditor:RemoveAllProps()
    Render:GetGridMesh():Destroy()
end

return vgui.Register("D_HoloEditor", PANEL, "DFrame")