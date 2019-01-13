AddCSLuaFile()
--create module
module("HoloEditor", package.seeall)
------------------------------------------------------------
--precache functions and table
local vgui = vgui
local util = util
local math = math
local Vector = Vector
local table = table
--local Angle = Angle
local IsValid = IsValid
local Color = Color
------------------------------------------------------------
--consts
local scrW = ScrW()
local scrH = ScrH()
local centerW = scrW * 0.5
local centerH = scrH * 0.5

------------------------------------------------------------
--utils and other
Colors = {
    SELECTION_COLOR = Color(5, 190, 232),
    DEFAULT_COLOR = Color(255, 255, 255)
}

Props = {}
SelectedProps = {}
DeselectedProps = {}
Trace = {}
Camera = {CamPos, CamAng, CamFOV}
EditorWindows = nil
------------------------------------------------------------
--autogen getter setter for table value
AccessorFunc(Camera, "Pos", "Pos")
AccessorFunc(Camera, "Ang", "Ang")
AccessorFunc(Camera, "FOV", "FOV", FORCE_NUMBER)

------------------------------------------------------------
--local functions and helpers
--create new callback
local function Callback()
    local callbackmeta = {}

    function callbackmeta:__call(prop)
        for _, fun in pairs(self.Callbacks) do
            fun(prop)
        end
    end

    local newTable = {
        Callbacks = {}
    }

    function newTable:AddCallback(a)
        self.Callbacks[#self.Callbacks + 1] = a
    end

    return setmetatable(newTable, callbackmeta)
end

--remove value from table by key
local function RemoveFrom(tbl, key)
    tbl[key] = nil
end

--add value to table
local function AddTo(tbl, key)
    tbl[key] = true
end

------------------------------------------------------------
--functions
--init Camera and setup allsetings
function Init()
    Camera:SetPos(Vector(0, -200, 100))
    Camera:SetAng((Vector(0, 0, 0) - Camera:GetPos()):Angle())
    Camera:SetFOV(90)
end

--open editor window
function Open()
    if (IsValid(EditorWindows)) then
        EditorWindows:Close()
        EditorWindows = vgui.Create("D_HoloEditor")
    else
        EditorWindows = vgui.Create("D_HoloEditor")
    end

    return EditorWindows
end

--close editor window
function Close()
    if (IsValid(EditorWindows)) then
        EditorWindows:Close()
    end
end

--add prop
function AddProp(self, propModel, selectProp)
    selectProp = selectProp == nil and true or false
    local prop = ClientsideModel(propModel)
    if (not IsValid(prop)) then return end
    prop:SetPos(Vector(20 * table.Count(Props), 0, 0)) --FIXME: для отладки выделения убрать нахой

    if (selectProp) then
        AddTo(SelectedProps, prop)
    else
        AddTo(DeselectedProps, prop)
    end

    AddTo(Props, prop)
    OnPropAdded(prop)

    return prop
end

-- remove prop
function RemoveProp(self, prop)
    RemoveFrom(SelectedProps, prop)
    RemoveFrom(DeselectedProps, prop)
    RemoveFrom(Props, prop)
    prop:Remove()
    OnPropRemoved(prop)
end

--remove all props and clear table
function RemoveAllProps()
    for prop, _ in pairs(Props) do
        RemoveProp(_, prop)
    end

    table.Empty(Props)
    table.Empty(SelectedProps)
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

-- prop is selected
function IsSelectedProp(slf, prop)
    return SelectedProps[prop] == nil or false
end

-- prop is selected
function IsDeselectedProp(slf, prop)
    return DeselectedProps[prop] == nil or false
end

-- select prop
function SelectProp(slf, prop)
    if (DeselectedProps[prop]) then
        AddTo(SelectedProp, prop)
        RemoveFrom(DeselectedProps, prop)
        prop:SetColor(Colors.SELECTION_COLOR)
        OnPropSelected(prop)
    end
end

-- deselect prop
function DeselectProp(slf, prop)
    if (SelectedProps[prop]) then
        AddTo(DeselectedProps, prop)
        RemoveFrom(SelectedProps, prop)
        prop:SetColor(Colors.DEFAULT_COLOR)
        OnPropDeselected(prop)
    end
end

-- select all props
function SelectAllProp(slf)
    for prop, select in pairs(DeselectedProps) do
        AddTo(SelectedProps, prop)
        RemoveFrom(DeselectedProps, prop)
        OnPropSelected(prop)
    end
end

-- deselect all props
function DeselectAllProp(slf)
    for prop, select in pairs(SelectedProps) do
        AddTo(DeselectedProps, prop)
        RemoveFrom(SelectedProps, prop)
        OnPropDeselected(prop)
    end
end

-- save editor project and return compressed data
function SaveProject()
    local projectProps = {}

    for _, prop in pairs(Props) do
        local propData = {
            Position = prop:GetPos(),
            Angles = prop:GetAngles(),
            Scale = prop:GetModelScale(),
            Color = prop:GetColor(),
            Material = prop:GetMaterial(),
            Model = prop:GetModel()
        }

        -- TODO:
        --Bodygroups =
        --Skin =
        --Clips =
        --SubMaterials =
        --Bones = o_O
        table.insert(projectProps, propData)
    end

    local project = {
        Props = projectProps
    }

    return util.Compress(util.TableToJSON(project, true))
end

------------------------------------------------------------
--callbacks
--call when new prop added
OnPropAdded = Callback()
--call when prop removed
OnPropRemoved = Callback()
--call when prop selected
OnPropSelected = Callback()
--call when prop deselected
OnPropDeselected = Callback()

------------------------------------------------------------
--trace lib function
--get aim vector from screen to world
function Trace:AimVector(ang, fov, x, y, w, h)
    ang = ang == nil and Camera:GetAng() or ang
    endPos = endPos == nil and Camera:GetPos() or endPos
    fov = fov == nil and Camera:GetFOV() or fov
    x = x == nil and centerW or x
    y = y == nil and centerH or y
    w = w == nil and scrW or w
    h = h == nil and scrH or h

    return util.AimVector(ang, fov, x, y, w, h)
end

--get trace hit result if cursor hit some in 3d space
function Trace:IsLineHit(startPosition, endPosition, hitBoxScale)
    local camPos = Camera:GetPos()
    local dotNormal = startPosition:Dot((endPosition - camPos):GetNormalized())
    local dot = math.acos(dotNormal)
    local propDistance = endPosition:Distance(camPos)
    local angle = math.asin(hitBoxScale / propDistance)

    return dot < angle, propDistance
end
