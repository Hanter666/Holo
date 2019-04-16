local Props = HoloEditor.Props
local SelectedProps = HoloEditor.SelectedProps
local DeselectedProps = HoloEditor.DeselectedProps
local Camera = HoloEditor.Camera
local Trace = HoloEditor.Trace
local Render = HoloEditor.Render
local Controlls = HoloEditor.Controlls
local SelectMode = Controlls.SelectMode
local Modes = SelectMode.Modes
local PANEL = {}

function PANEL:Init()
    self:RequestFocus()
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
    self.LastClickTime = SysTime()

    self.OldCursorPos = {
        x = 0,
        y = 0
    }
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
    local x, y = self:CursorPos()
    local w, h = self:GetSize()

    if (keyCode == MOUSE_RIGHT) then
        self.OldCursorPos.x = x
        self.OldCursorPos.y = y
        self.CamIsRotating = true
        self:SetCursor("blank")
        RememberCursorPosition()
    elseif (keyCode == MOUSE_LEFT) then
        if (self.LastClickTime and SysTime() - self.LastClickTime < 0.2) then
            self:DoDoubleClick()

            return
        end

        self.LastClickTime = SysTime()
        local editorMode = SelectMode:GetMode()
        local isMutiselectMode = SelectMode:GetMutiselectMode()
        local camAng = Camera:GetAng()
        local camFOV = Camera:GetFOV()
        local camPos = Camera:GetPos()
        local traceVector = util.AimVector(camAng, camFOV, x, y, ScrW(), ScrH())

        if (editorMode == Modes.Move) then
            --TODO: readl radius not 5
            local isHit, distance = Trace:IsCursorHit(traceVector, camPos, targetPosition, 5)
        elseif (editorMode == Modes.Resize) then
            local center = Controlls:GetCenter()
            Trace:IsHitLine(traceVector, center, center + Controlls:GetX())
        end
    end
end

function PANEL:DoDoubleClick()
    if (SelectedProps.Count == 0) then
        HoloEditor:SelectAllProps()
    else
        HoloEditor:DeselectAllProps()
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
    local xw, xh = self:LocalToScreen(self:GetWide(), self:GetTall())
    cam.Start3D(Camera:GetPos(), Camera:GetAng(), Camera:GetFOV(), x, y, w, h, 5, 1000)
    render.SetScissorRect(x, y, xw, xh, true)
    Render:DrawControlls(Props, SelectedProps, DeselectedProps)
    render.SetScissorRect(0, 0, 0, 0, false)
    cam.End3D()

    if (self.CamIsRotating) then
        Render:DrawCrosshair2D(w, h)
    end

    Render:DrawStats2D(Props)
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
        elseif (self.CamMove[KEY_LALT] ~= 0) then
            speed = speed * 0.5
        end

        Camera:SetPos(Camera:GetPos() + direction * speed)
        Controlls:UpdateScale(Camera)
    end
end

return vgui.Register("D_Workspace", PANEL, "DPanel")