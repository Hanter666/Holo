local Props = HoloEditor.Props
local SelectedProps = HoloEditor.SelectedProps
local Camera = HoloEditor.Camera
local Trace = HoloEditor.Trace
local Render = HoloEditor.Render
local PANEL = {}
AccessorFunc(PANEL, "MultiSelectMode", "MultiSelectMode", FORCE_BOOL)

function PANEL:Init()
    self:RequestFocus()
    self:SetMultiSelectMode(false)
    self.SelectorSize = 5
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

    self.PropsLocalCoords = false
end

function PANEL:DrawResizeLine()
    if (not self.LastSelectedProp) then return end
    local pos = Vector()

    if (self.MultiSelectMode) then
        for prop, _ in pairs(SelectedProps) do
            pos = pos + prop:GetPos()
        end

        pos:Div(table.Count(SelectedProps))
    else
        pos = self.LastSelectedProp:GetPos()
    end

    local distance = pos:Distance(Camera:GetPos()) * 0.1
    local beamScale = distance * 0.1
    local xPos = pos + Vector(distance, 0, 0)
    local yPos = pos + Vector(0, distance, 0)
    local zPos = pos + Vector(0, 0, distance)
    local pozScale = Vector(beamScale, beamScale, beamScale)
    local negScale = Vector(-beamScale, -beamScale, -beamScale)
    local R = Color(255, 0, 0)
    local G = Color(0, 255, 0)
    local B = Color(0, 0, 255)
    render.SetColorMaterialIgnoreZ()
    render.DrawBeam(pos, zPos, beamScale, 0, 1, G)
    render.DrawBox(zPos, Angle(0, 0, 0), negScale, pozScale, G, true)
    render.DrawBeam(pos, yPos, beamScale, 0, 1, B)
    render.DrawBox(yPos, Angle(0, 0, 0), negScale, pozScale, B, true)
    render.DrawBeam(pos, xPos, beamScale, 0, 1, R)
    render.DrawBox(xPos, Angle(0, 0, 0), negScale, pozScale, R, true)
    render.DrawSphere(pos, beamScale, 50, 50, G)
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
        local minDistance = math.huge
        local minDistanceProp = nil
        local w, h = self:GetSize()
        local x, y

        if (self.CamIsRotating) then
            x, y = w * 0.5, h * 0.5
        else
            x, y = self:CursorPos()
        end

        for prop, _ in pairs(Props) do
            if (not self.MultiSelectMode) then
                HoloEditor:DeselectProp(prop)
            end

            local propPos = prop:GetPos()
            local propRadius = prop:GetModelRadius()
            local isHit, distanseToCamera = Trace:IsCursorHit(x, y, w, h, propPos, propRadius)

            if (isHit and distanseToCamera < minDistance) then
                minDistance = distanseToCamera
                minDistanceProp = prop
            end
        end

        if (minDistanceProp) then
            self.LastSelectedProp = minDistanceProp

            if (HoloEditor:IsSelectedProp(minDistanceProp)) then
                print(false)
                HoloEditor:DeselectProp(minDistanceProp)
            else
                print(true)
                HoloEditor:SelectProp(minDistanceProp)
            end
        else
            --HoloEditor:DeselectAllProp()
            -- TODO: select all by double click
        end
    end
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
        local lerpAng = LerpAngle(self.CamInterpolation, Camera:GetAng(), Camera:GetAng() + ang)
        local pitch = math.Clamp(lerpAng.pitch, -89, 89)
        lerpAng.pitch = pitch
        lerpAng.Roll = 0
        Camera:SetAng(lerpAng)
        RestoreCursorPosition()
    end
end

function PANEL:Paint(w, h)
    local x, y = self:LocalToScreen(0, 0)
    cam.Start3D(Camera:GetPos(), Camera:GetAng(), Camera:GetFOV(), x, y, w, h, 5, 1000)
    Render:DrawProps()
    render.SuppressEngineLighting(true)
    Render:DrawGrid()
    self:DrawResizeLine()
    render.SuppressEngineLighting(false)
    cam.End3D()

    if (self.CamIsRotating) then
        surface.SetDrawColor(Color(255, 255, 255)) -- TODO: try to improve crosshair visibility
        surface.DrawLine(w * 0.5 - 12, h * 0.5, w * 0.5 + 12, h * 0.5)
        surface.DrawLine(w * 0.5, h * 0.5 - 12, w * 0.5, h * 0.5 + 12)
    end
end

function PANEL:Think()
    if (self.CamIsMoving) then
        local forward = self.CamMove[KEY_W] - self.CamMove[KEY_S]
        local right = self.CamMove[KEY_D] - self.CamMove[KEY_A]
        local up = self.CamMove[KEY_SPACE] - self.CamMove[KEY_LCONTROL]
        local speed = self.CamSpeed
        local direction = ((Camera:GetAng():Forward() * forward) + (Camera:GetAng():Right() * right) + Vector(0, 0, up)):GetNormalized()

        if (self.CamMove[KEY_LSHIFT] ~= 0) then
            speed = speed * self.CamShiftSpeed
        end

        if (self.CamMove[KEY_LALT] ~= 0) then
            speed = speed * 0.5
        end

        Camera:SetPos(Camera:GetPos() + direction * speed)
    end
end

return vgui.Register("D_Workspace", PANEL, "DPanel")