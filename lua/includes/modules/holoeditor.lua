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
local IsValid = IsValid
local Color = Color
local render = render
local mesh = mesh
local Material = Material
local AccessorFunc = AccessorFunc
------------------------------------------------------------
--consts
local scrW = ScrW()
local scrH = ScrH()
local centerW = scrW * 0.5
local centerH = scrH * 0.5

------------------------------------------------------------
--base table and other
Colors = {
    SELECTION_COLOR = Color(5, 190, 232),
    DEFAULT_COLOR = Color(255, 255, 255),
    GRID_COLOR = Color(17, 74, 122, 200)
}

Render = {
    GridSize,
    GridMesh,
    Materials = {
        GRID_MATERIAL = Material("editor/wireframe")
    }
}

local Materials = Render.Materials
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
AccessorFunc(Render, "GridSize", "GridSize", FORCE_NUMBER)
AccessorFunc(Render, "GridMesh", "GridMesh")

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

--add vertex to mesh object
local function AddVertex(pos, u, v, color)
    mesh.Position(pos)
    mesh.TexCoord(0, u, v)
    mesh.Color(color.r, color.g, color.b, color.a)
    mesh.AdvanceVertex()
end

------------------------------------------------------------
--functions
--init Camera and setup allsetings
function Init()
    Camera:SetPos(Vector(0, -200, 100))
    Camera:SetAng((Vector(0, 0, 0) - Camera:GetPos()):Angle())
    Camera:SetFOV(90)
    Render:SetGridSize(12)
    Render:UpdateGrid(19)
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
        Render:GetGridMesh():Destroy()
    end
end

--add prop
function AddProp(self, propModel, selectProp)
    selectProp = selectProp or true
    local prop = ClientsideModel(propModel)
    if (not IsValid(prop)) then return end
    prop:SetPos(Vector(20 * table.Count(Props), 0, 0)) --TODO: для отладки выделения убрать нахой

    if (selectProp) then
        SelectProp(prop)
    else
        DeselectProp(prop)
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
    return SelectedProps[prop]
end

-- prop is not selected
function IsDeselectedProp(slf, prop)
    return DeselectedProps[prop]
end

-- select prop
function SelectProp(slf, prop)
    if (IsDeselectedProp(slf, prop)) then
        AddTo(SelectedProps, prop)
        RemoveFrom(DeselectedProps, prop)
        prop:SetColor(Colors.SELECTION_COLOR)
        OnPropSelected(prop)
    end
end

-- deselect prop
function DeselectProp(slf, prop)
    if (IsSelectedProp(slf, prop)) then
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
        prop:SetColor(Colors.SELECTION_COLOR)
        OnPropSelected(prop) -- FIXME: нужен ли калбек, если некоторые пропы и так были выбраны?
    end
end

-- deselect all props
function DeselectAllProp(slf)
    for prop, select in pairs(SelectedProps) do
        AddTo(DeselectedProps, prop)
        RemoveFrom(SelectedProps, prop)
        prop:SetColor(Colors.DEFAULT_COLOR)
        OnPropDeselected(prop) -- FIXME: нужен ли калбек, если некоторые пропы и так не были выбраны?
    end
end

-- save editor project and return compressed data
-- FIXME: save - неподходящее название
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
--trace lib functions for hit testing in 3D space
--get aim direction from screen to world
function Trace:AimDirection(ang, fov, x, y, w, h)
    ang = ang or Camera:GetAng()
    endPos = endPos or Camera:GetPos()
    fov = fov or Camera:GetFOV()
    x = x or centerW
    y = y or centerH
    w = w or scrW
    h = h or scrH

    return util.AimVector(ang, fov, x, y, w, h)
end

--get trace result
function Trace:IsLineHit(traceOrigin, traceDirection, targetPosition, targetRadius)
    local dotNormal = traceDirection:Dot((targetPosition - traceOrigin):GetNormalized())
    local dot = math.acos(dotNormal)
    local targetDistance = targetPosition:Distance(traceOrigin)
    local angle = math.asin(targetRadius / targetDistance)

    return dot < angle, targetDistance
end

--get trace result for cursor
function Trace:IsCursorHit(cursorX, cursorY, viewportW, viewportH, targetPosition, targetRadius)
    local traceOrigin = Camera:GetPos()
    local traceDirection = Trace:AimDirection(_, _, cursorX, cursorY, viewportW, viewportH)
    local dotNormal = traceDirection:Dot((targetPosition - traceOrigin):GetNormalized())
    local dot = math.acos(dotNormal)
    local targetDistance = targetPosition:Distance(traceOrigin)
    local angle = math.asin(targetRadius / targetDistance)

    return dot < angle, targetDistance
end

------------------------------------------------------------
--render lib functions draw stuff
--draw mesh grid
function Render:DrawGrid()
    local gridMesh = self:GetGridMesh()

    if (gridMesh) then
        render.SetMaterial(Materials.GRID_MATERIAL)
        gridMesh:Draw()
    end
end

function Render:UpdateGrid(scale)
    local gridMesh = Render:GetGridMesh()

    if (gridMesh) then
        gridMesh:Destroy()
    end

    Render:SetGridMesh(Mesh())
    local gridSize = Render:GetGridSize()
    local gridColor = Colors.GRID_COLOR
    local lineLenght = gridSize * scale
    local center = lineLenght * 0.5
    local offset = Vector(center, center, 0)
    gridMesh = Render:GetGridMesh()
    mesh.Begin(gridMesh, MATERIAL_LINES, scale * 2 + 4)

    for i = 0, scale do
        local pos = i * gridSize
        --x:left y:forward z:up
        AddVertex(Vector(pos, lineLenght, 0) - offset, 0, 0, gridColor)
        AddVertex(Vector(pos, 0, 0) - offset, 1, 1, gridColor)
        AddVertex(Vector(lineLenght, pos, 0) - offset, 0, 0, gridColor)
        AddVertex(Vector(0, pos, 0) - offset, 1, 1, gridColor)
    end

    mesh.End()
end