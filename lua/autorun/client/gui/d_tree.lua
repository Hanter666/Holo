local PANEL = {}

function PANEL:Init()
end

function PANEL:Paint(w, h)
    draw.RoundedBox(0, 0, 0, w, h, Color(27, 30, 43))
    surface.SetDrawColor(17, 19, 27)
    self:DrawOutlinedRect()
end

function PANEL:RemoveNodeByProp(prop)
    for _, treeNode in pairs(self.ChildNodes) do
        if (treeNode.Prop == prop) then
            table.RemoveByValue(self.ChildNodes, treeNode)
            treeNode:Remove()
            break
        end
    end
end

--[[function PANEL:SetSelectedItem(node)
    self.m_pSelectedItem = node

    if (node) then
        local selected = HoloEditor:IsSelectedProp()
        node:SetSelected(selected)
    end
end]]
return vgui.Register("D_Tree", PANEL, "DTree")