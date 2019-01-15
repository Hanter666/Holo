local HoloEditor = HoloEditor
local Props = HoloEditor.Props
local Util = HoloEditor.Util
local PANEL = {}

function PANEL:Init()
    --TODO: fix code dublication
    for prop, _ in pairs(Props) do
        local niceName = Util:GetNiceModelName(prop)
        local treeNode = self:AddNode(niceName, "icon16/shape_square.png")
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

        self:SetSelectedItem(treeNode)
    end
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

function PANEL:SetSelectedItem(node)
    self.m_pSelectedItem = node

    if (node) then
        node:SetSelected(HoloEditor:IsSelectedProp(node.Prop))
    end
end

function PANEL:GetChildNodes()
    return self.RootNode:GetChildren()
end

function PANEL:ChangeSelection(prop)
    for _, treeNode in pairs(self:GetChildNodes()) do
        if (treeNode.Prop == prop) then
            self:SetSelectedItem(treeNode)
            break
        end
    end
end

return vgui.Register("D_Tree", PANEL, "DTree")