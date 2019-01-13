local PANEL = {}

function PANEL:Init()
    self:SetDraggable(false)
    self:SetScreenLock(true)
    self:SetSize(ScrW(), ScrH())
    self:DockPadding(0, 29, 0, 0)
    self:MakePopup()
    self.ToolsPanel = vgui.Create("DTree", self)
    self.ToolsPanel:Dock(LEFT)
    self.ToolsPanel:SetWide(48)

    function self.ToolsPanel:Paint(w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(27, 30, 43))
        surface.SetDrawColor(17, 19, 27)
        self:DrawOutlinedRect()
    end

    self.Tree = vgui.Create("D_Tree", self)
    self.Tree:Dock(RIGHT)
    self.Tree:SetWide(124)
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
    HoloEditor:RemoveAllProps()
end

return vgui.Register("D_HoloEditor", PANEL, "DFrame")