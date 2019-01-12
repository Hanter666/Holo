--create module
module("HoloEditor", package.seeall)
------------------------------------------------------------
--precache functions and table
local vgui = vgui
local util = util
local math = math
local Vector = Vector
local Angle = Angle
local IsValid = IsValid
--consts
local scrW = ScrW()
local scrH = ScrH()
local centerW = scrW * 0.5
local centerH = scrH * 0.5
------------------------------------------------------------
--utils and other
Props = {}
SelectedProps = {}
DeselectedProps = {}
Trace = {}
Camera = {CamPos, CamAng, CamFov}
EditorWindows = nil
------------------------------------------------------------
--autogen getter setter for table value
AccessorFunc(Camera, "Pos", "Pos")
AccessorFunc(Camera, "Ang", "Ang")
AccessorFunc(Camera, "Fov", "Fov", FORCE_NUMBER)

------------------------------------------------------------
--functions
--init Camera and setup allsetings
function Init()
    Camera:SetPos(Vector(0, -200, 100))
    Camera:SetAng((Vector(0, 0, 0) - Camera:GetPos()):Angle())
    Camera:SetFov(90)
end

--Open editor window
function Open()
    if (IsValid(EditorWindows)) then
        EditorWindows:Close()
        EditorWindows = vgui.Create("D_HoloEditor")
    else
        EditorWindows = vgui.Create("D_HoloEditor")
    end

    return EditorWindows
end

function Close()
    if (IsValid(EditorWindows)) then
        EditorWindows:Close()
    end
end

--Add prop
function AddProp(self, propModel, selectProp)
    selectProp = selectProp == nil and true or selectProp
    local prop = ClientsideModel(propModel)
    if (not IsValid(prop)) then return end
    prop:SetPos(Vector(20 * #SelectedProps, 0, 0)) --FIXME: для отладки выделения убрать нахой

    if (selectProp) then
        table.insert(SelectedProps, prop)
    else
        table.insert(DeselectedProps, prop)
    end

    table.insert(Props, prop)
    OnPropAdded(prop)
end

-- remove prop
function RemoveProp(self, prop)
    if (not IsValid(prop)) then return end

    if (table.HasValue(SelectedProps, prop)) then
        table.RemoveByValue(Props, prop)
    elseif (table.HasValue(DeselectedProps, prop)) then
        table.RemoveByValue(Props, prop)
    end

    if (table.HasValue(Props, prop)) then
        table.RemoveByValue(Props, prop)
        prop:Remove()
    end
end

--remove all props and clear table
function RemoveAllProps()
    for _, prop in pairs(Props) do
        OnPropRemoved(prop)
        prop.Remove()
    end

    table.Empty(Props)
    table.Empty(SelectProp)
    table.Empty(DeselectedProps)
end

--get all selected props
function GetSelectedProps()
    return SelectedProps
end

--get all deselected props
function GetDeselectedProps()
    return DeselectedProps
end

-- get all props
function GetAllProps()
    return Props
end

------------------------------------------------------------
--callbacks
function OnPropAdded(self, prop)
end

function OnPropRemoved(self, prop)
end

------------------------------------------------------------
--trace lib function
--get aim vector from screen to world
function Trace:AimVector(ang, fov, x, y, w, h)
    ang = ang == nil and Camera:GetAng() or ang
    endPos = endPos == nil and Camera:GetPos() or endPos
    fov = fov == nil and Camera:GetFov() or fov
    x = x == nil and centerW or x
    y = y == nil and centerH or y
    w = w == nil and scrW or w
    h = h == nil and scrH or h

    return util.AimVector(ang, fov, x, y, w, h)
end

--get trace hit result if cursor hit some in 3d space
function Trace:IsCursorHit(x, y, w, h, endPosition, hitBoxScale)
    local camPos = Camera:GetPos()
    local trace = self:AimVector(_, _, x, y, w, h)
    local dotNormal = trace:Dot((endPosition - camPos):GetNormalized())
    local dot = math.acos(dotNormal)
    local propDistance = endPosition:Distance(camPos)
    local angle = math.asin(hitboxScale / propDistance)

    return dot < angle
end