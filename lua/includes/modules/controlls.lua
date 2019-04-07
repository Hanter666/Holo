--lib for change control position and orientation
local Controlls = {
    Local = false,
    X = Vector(),
    Y = Vector(),
    Z = Vector(),
    W = Vector(),
    Center = Vector(),
    Angle = Angle(),
    BeamScale = 0
}

local SelectMode = {
    MutiselectMode,
    Mode,
    Modes = {
        Select = 0,
        Move = 1,
        Rotate = 2,
        Resize = 3
    }
}

AccessorFunc(SelectMode, "MutiselectMode", "MutiselectMode", FORCE_BOOL)
AccessorFunc(SelectMode, "Mode", "Mode", FORCE_NUMBER)
Controlls.SelectMode = SelectMode
AccessorFunc(Controlls, "Local", "Local", FORCE_BOOL)
AccessorFunc(Controlls, "X", "X")
AccessorFunc(Controlls, "Y", "Y")
AccessorFunc(Controlls, "Z", "Z")
AccessorFunc(Controlls, "W", "W")
AccessorFunc(Controlls, "Center", "Center")
AccessorFunc(Controlls, "Angle", "Angle")
AccessorFunc(Controlls, "BeamScale", "BeamScale", FORCE_NUMBER)

--update controlls angle
function Controlls:UpdateAngle(propAngle)
    local ang = (not self.SelectMode:GetMutiselectMode() and self:GetLocal()) and propAngle or Angle()
    self:SetAngle(ang)
end

--update controlls scale
function Controlls:UpdateScale(camera)
    local distance = self:GetCenter():Distance(camera:GetPos()) * 0.1
    local beamScale = distance * 0.1
    self:SetX(Vector(distance, 0, 0))
    self:SetY(Vector(0, distance, 0))
    self:SetZ(Vector(0, 0, distance))
    self:SetW(Vector(distance, distance, distance) * 0.5)
    self:SetBeamScale(beamScale)
end

--update controls position for next rendering
function Controlls:Update(camera, selectedProps, propPos, propAng)
    local center = Vector()

    for prop, _ in pairs(selectedProps) do
        center = center + prop:GetPos()
    end

    self:SetCenter(center / selectedProps.Count)
    self:UpdateAngle(propAng)
    self:UpdateScale(camera)
end

return Controlls