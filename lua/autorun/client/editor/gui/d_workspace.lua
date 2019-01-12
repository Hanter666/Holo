local PANEL = {}
AccessorFunc(PANEL, "MultiSelectMode", "MultiSelectMode", FORCE_BOOL)

function PANEL:Init()
    self:RequestFocus()
    self:SetMultiSelectMode(true)
    self.SelectorSize = 5
    self.GridMeshVerts = {}
    self.GridMeshMat = Material("editor/wireframe")
    self.GridSize = 12
    self.CamPos = Vector(0, -200, 100)
    self.CamAng = (Vector(0, 0, 0) - self.CamPos):Angle()
    self.CamMove = {}
    self.CamMove[KEY_W] = 0
    self.CamMove[KEY_S] = 0
    self.CamMove[KEY_A] = 0
    self.CamMove[KEY_D] = 0
    self.CamMove[KEY_SPACE] = 0
    self.CamMove[KEY_LCONTROL] = 0
    self.CamMove[KEY_LSHIFT] = 0
    self.CamMove[KEY_LALT] = 0
    self.CamIsMoving = false
    self.CamSpeed = 1
    self.CamShiftSpeed = 2
    self.CamInterpolation = 0.1
    self.CamIsRotating = false
    self.LastSelectedProp = nil

    self.OldCursorPos = {
        x = 0,
        y = 0
    }

    self.Props = {}
    self.PropsLocalCoords = false

    self.Colors = {
        SELECTION_COLOR = Color(5, 190, 232),
        DEFAULT_COLOR = Color(255, 255, 255)
    }

    self:UpdateGrid(20)
end

function PANEL:AddProp(prop)
    if (not self.MultiSelectMode) then
        for _, pr in pairs(self.Props) do
            self:DeselectProp(pr)
        end
    end

    self:SelectProp(prop)
    table.insert(self.Props, prop)
end

function PANEL:RemoveProp(prop)
    self:DeselectProp(prop)
    table.RemoveByValue(self.Props, prop)
    prop:Remove()
end

--Callback
function PANEL:OnSelectedPropChanged(prop)
end

function PANEL:SelectProp(prop)
    prop.IsSelected = true
    prop:SetColor(self.Colors.SELECTION_COLOR)
    self.LastSelectedProp = prop
    self:OnSelectedPropChanged(prop)
end

function PANEL:DeselectProp(prop)
    prop.IsSelected = false
    prop:SetColor(self.Colors.DEFAULT_COLOR)
    self:OnSelectedPropChanged(prop)
end

function PANEL:DrawGrid()
    if (#self.GridMeshVerts < 0) then return end
    render.SetMaterial(self.GridMeshMat)
    mesh.Begin(MATERIAL_LINES, #self.GridMeshVerts)

    for i = 1, #self.GridMeshVerts do
        mesh.Position(self.GridMeshVerts[i].pos)
        mesh.TexCoord(0, self.GridMeshVerts[i].u, self.GridMeshVerts[i].v)
        mesh.Color(17, 74, 122, 200)
        mesh.AdvanceVertex()
    end

    mesh.End()
end

function PANEL:DrawResizeLine()
    if (not self.LastSelectedProp) then return end
    local propPos = Vector(0, 0, 0)

    if (self.MultiSelectMode) then
        local pos = Vector()
        local selected = 0

        for _, prop in pairs(self.Props) do
            if (prop.IsSelected) then
                propPos = pos + prop:GetPos()
                selected = selected + 1
            end
        end

        propPos:Div(selected)
    else
        propPos = self.LastSelectedProp:GetPos()
    end

    local distance = propPos:Distance(self.CamPos) * 0.1
    local beamScale = distance * 0.1
    local xPos = propPos + Vector(distance, 0, 0)
    local yPos = propPos + Vector(0, distance, 0)
    local zPos = propPos + Vector(0, 0, distance)
    local pozScale = Vector(beamScale, beamScale, beamScale)
    local negScale = Vector(-beamScale, -beamScale, -beamScale)
    local R = Color(255, 0, 0)
    local G = Color(0, 255, 0)
    local B = Color(0, 0, 255)
    render.SetColorMaterialIgnoreZ()
    render.DrawBeam(propPos, zPos, beamScale, 0, 1, G)
    render.DrawBox(zPos, Angle(0, 0, 0), negScale, pozScale, G, true)
    render.DrawBeam(propPos, yPos, beamScale, 0, 1, B)
    render.DrawBox(yPos, Angle(0, 0, 0), negScale, pozScale, B, true)
    render.DrawBeam(propPos, xPos, beamScale, 0, 1, R)
    render.DrawBox(xPos, Angle(0, 0, 0), negScale, pozScale, R, true)
    render.DrawSphere(propPos, beamScale, 50, 50, G)
end

function PANEL:DrawProps()
    for _, prop in pairs(self.Props) do
        local color = prop:GetColor()
        render.SetColorModulation(color.r / 255, color.g / 255, color.b / 255)
        render.SetBlend(color.a / 255)
        prop:DrawModel()
    end
end

function PANEL:OnKeyCodePressed(keyCode)
    if (self.CamMove[keyCode] ~= nil) then
        self.CamIsMoving = true
        self.CamMove[keyCode] = 1
    end
end

function PANEL:OnKeyCodeReleased(keyCode)
    if (self.CamMove[keyCode] ~= nil) then
        self.CamMove[keyCode] = 0
    end

    if (table.maxn(self.CamMove) == 0) then
        self.CamIsMoving = false
    end
end

function PANEL:OnMousePressed(keyCode)
    if (keyCode == MOUSE_RIGHT) then
        local x, y = self:CursorPos()
        self.OldCursorPos.x = x
        self.OldCursorPos.y = y
        self.CamIsRotating = true
        self:SetCursor("blank")
        RememberCursorPosition()
    elseif (keyCode == MOUSE_LEFT) then
        local x, y = self:CursorPos()
        local scrVec = util.AimVector(self.CamAng, 90, x, y, self:GetWide(), self:GetTall())
        local minDistance = math.huge
        local minDistanceProp = nil
        local ed = HoloEditor
        PrintTable(ed)
        for _, prop in pairs(self.Props) do
            --local rayResult = CustomRayTrace() -- TODO:custom ray trace v2 hitbox test mb make dis later
            if (not self.MultiSelectMode) then
                self:DeselectProp(prop)
            end

            local propPos = prop:GetPos()
            local lookAt = math.acos(scrVec:Dot((propPos - self.CamPos):GetNormalized()))
            local propDistance = propPos:Distance(self.CamPos)
            local radius = prop:GetModelRadius()
            local angle = math.asin(radius / propDistance)

            if (lookAt < angle and propDistance < minDistance) then
                minDistance = propDistance
                minDistanceProp = prop
            end
        end

        if (minDistanceProp) then
            self.LastSelectedProp = minDistanceProp

            if (minDistanceProp.IsSelected) then
                self:DeselectProp(minDistanceProp)
            else
                self:SelectProp(minDistanceProp)
            end
        end
    end
end

local function CustomRayTrace()
end

function PANEL:OnMouseReleased(keyCode)
    if (keyCode == MOUSE_RIGHT) then
        self.CamIsRotating = false
        self:SetCursor("arrow")
        RestoreCursorPosition()
    end
end

function PANEL:OnCursorMoved(cursorX, cursorY)
    if (self.CamIsRotating) then
        local ang = Angle(-(self.OldCursorPos.y - cursorY), self.OldCursorPos.x - cursorX, 0)
        local lerpAng = LerpAngle(self.CamInterpolation, self.CamAng, self.CamAng + ang)
        local pitch = math.Clamp(lerpAng.pitch, -89, 89)
        lerpAng.pitch = pitch
        lerpAng.Roll = 0
        self.CamAng = lerpAng
        RestoreCursorPosition()
    end
end

function PANEL:Paint(w, h)
    local x, y = self:LocalToScreen(0, 0)
    cam.Start3D(self.CamPos, self.CamAng, 90, x, y, w, h, 5, 1000)
    self:DrawProps()
    render.SuppressEngineLighting(true)
    self:DrawGrid()
    self:DrawResizeLine()
    render.SuppressEngineLighting(false)
    cam.End3D()
end

function PANEL:UpdateGrid(lines)
    table.Empty(self.GridMeshVerts)
    --x:left y:forward z:up
    local lineLenght = self.GridSize * lines
    local center = lineLenght * 0.5
    local offset = Vector(center, center, 0)

    for i = 0, lines do
        local pos = i * self.GridSize

        table.insert(self.GridMeshVerts, {
            pos = Vector(pos, lineLenght, 0) - offset,
            u = 0,
            v = 0
        })

        table.insert(self.GridMeshVerts, {
            pos = Vector(pos, 0, 0) - offset,
            u = 1,
            v = 1
        })

        table.insert(self.GridMeshVerts, {
            pos = Vector(lineLenght, pos, 0) - offset,
            u = 0,
            v = 0
        })

        table.insert(self.GridMeshVerts, {
            pos = Vector(0, pos, 0) - offset,
            u = 1,
            v = 1
        })
    end
end

function PANEL:Think()
    if (self.CamIsMoving) then
        local forward = self.CamMove[KEY_W] - self.CamMove[KEY_S]
        local right = self.CamMove[KEY_D] - self.CamMove[KEY_A]
        local up = self.CamMove[KEY_SPACE] - self.CamMove[KEY_LCONTROL]
        local speed = self.CamSpeed
        local direction = ((self.CamAng:Forward() * forward) + (self.CamAng:Right() * right) + Vector(0, 0, up)):GetNormalized()

        if (self.CamMove[KEY_LSHIFT] ~= 0) then
            speed = speed * self.CamShiftSpeed
        end

        if (self.CamMove[KEY_LALT] ~= 0) then
            speed = speed * 0.5
        end

        self.CamPos = self.CamPos + direction * speed
    end
end

return vgui.Register("D_Workspace", PANEL, "DPanel")