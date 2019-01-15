--send module to client
AddCSLuaFile()
------------------------------------------------------------
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
local ClientsideModel = ClientsideModel
local surface = surface
local setmetatable = setmetatable
local rawget = rawget
local rawset = rawset
local string = string
------------------------------------------------------------
--consts
local scrW = ScrW()
local scrH = ScrH()
local centerW = scrW * 0.5
local centerH = scrH * 0.5

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

--create prop table
local function CreatePropTable()
    local mt = {
        Count = 0
    }

    function mt:__newindex(key, value)
        if (key == "Count") then
            mt.Count = value
        else
            rawset(self, key, value)
        end
    end

    function mt:__index(key)
        if (key == "Count") then return mt.Count end
        local val = rawget(self, key)
        if (val) then return false end

        return val
    end

    return setmetatable({}, mt)
end

--remove value from table by key
local function RemoveFrom(tbl, key)
    if (tbl[key]) then
        tbl[key] = nil
        tbl.Count = tbl.Count - 1
    end
end

--add value to table
local function AddTo(tbl, key)
    if (tbl[key] == nil) then
        tbl[key] = true
        tbl.Count = tbl.Count + 1
    end
end

--add vertex to mesh object
local function AddVertex(pos, u, v, color)
    mesh.Position(pos)
    mesh.TexCoord(0, u, v)
    mesh.Color(color.r, color.g, color.b, color.a)
    mesh.AdvanceVertex()
end

local function GetSelectedPropsCenter()
    local propCont = SelectedProps.Count
    if (propCont == 0) then return end
    local pos = Vector()
    local selectMode = SelectMode:GetMutiselectMode()

    for prop, _ in pairs(SelectedProps) do
        if (selectMode) then
            pos = pos + prop:GetPos()
        else
            pos = prop:GetPos()
        end
    end

    return selectMode == true and pos:Div(propCont) or pos
end

local function DrawCircle3D(pos, radius, segments)
    for i = 0, segments do
        local point1 = math.rad((i / 30) * -360)
        local point2 = math.rad(((i + 1) / 30) * -360)
        local startPoint1 = math.sin(point1) * radius
        local endPoint1 = math.cos(point1) * radius
        local startNextPoint1 = math.sin(point2) * radius
        local startNextPoint2 = math.cos(point2) * radius
        render.DrawLine(pos + Vector(startPoint1, endPoint1, 0), pos + Vector(startNextPoint1, startNextPoint2, 0), Color(255, 0, 0))
        render.DrawLine(pos + Vector(startPoint1, 0, endPoint1), pos + Vector(startNextPoint1, 0, startNextPoint2), Color(0, 255, 0))
        render.DrawLine(pos + Vector(0, startPoint1, endPoint1), pos + Vector(0, startNextPoint1, startNextPoint2), Color(0, 0, 255))
    end
end

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
Props = CreatePropTable()
SelectedProps = CreatePropTable()
DeselectedProps = CreatePropTable()
Trace = {}
Camera = {CamPos, CamAng, CamFOV}
EditorWindows = nil

SelectMode = {
    MutiselectMode,
    Mode,
    Modes = {
        Select = 0,
        Move = 1,
        Rotate = 2,
        Resize = 3
    }
}

local Modes = SelectMode.Modes
Util = {}
------------------------------------------------------------
--autogen getter setter for table value
AccessorFunc(Camera, "Pos", "Pos")
AccessorFunc(Camera, "Ang", "Ang")
AccessorFunc(Camera, "FOV", "FOV", FORCE_NUMBER)
AccessorFunc(Render, "GridSize", "GridSize", FORCE_NUMBER)
AccessorFunc(Render, "GridMesh", "GridMesh")
AccessorFunc(SelectMode, "MutiselectMode", "MutiselectMode", FORCE_BOOL)
AccessorFunc(SelectMode, "Mode", "Mode", FORCE_NUMBER)

------------------------------------------------------------
--functions
--init camera and setup all setings
function Init()
    SelectMode:SetMutiselectMode(true)
    SelectMode:SetMode(Modes.Select)
    Camera:SetPos(Vector(0, -200, 100))
    Camera:SetAng((Vector(0, 0, 0) - Camera:GetPos()):Angle())
    Camera:SetFOV(90)
    Render:SetGridSize(12)
end

--open editor window
function Open()
    if (IsValid(EditorWindows)) then
        EditorWindows:Close()
    end

    Render:UpdateGrid(19)
    EditorWindows = vgui.Create("D_HoloEditor")

    return EditorWindows
end

--add prop
function AddProp(self, propModel, selectProp)
    selectProp = selectProp or SelectMode:GetMutiselectMode()
    util.PrecacheModel(propModel, RENDERGROUP_BOTH)
    local prop = ClientsideModel(propModel)
    local defaultColor = prop:GetColor()
    prop.DefaultColor = defaultColor
    function prop:ResetColor()
        self:SetColor(self.DefaultColor)
    end

    function prop:SetDefaultColor(color)
        self.DefaultColor = color
    end

    prop:SetMoveType(MOVETYPE_NONE)
    if (not IsValid(prop)) then return end

    if (selectProp) then
        self:SelectProp(prop)
    else
        self:DeselectProp(prop)
    end

    AddTo(Props, prop)
    prop:SetPos(Vector(20 * Props.Count, 0, 0)) --TODO: для отладки выделения убрать нахой
    OnPropAdded(prop)

    return prop
end

-- remove prop
function RemoveProp(self, prop)
    if (prop) then
        OnPropRemoved(prop)
        RemoveFrom(SelectedProps, prop)
        RemoveFrom(DeselectedProps, prop)
        RemoveFrom(Props, prop)
        prop:Remove()
    end
end

--remove all props and clear table
function RemoveAllProps()
    for prop, _ in pairs(Props) do
        RemoveProp(_, prop)
    end
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
    if (prop) then
        AddTo(SelectedProps, prop)
        RemoveFrom(DeselectedProps, prop)
        prop:SetColor(Colors.SELECTION_COLOR)
        OnPropSelected(prop)
    end
end

-- deselect prop
function DeselectProp(slf, prop)
    if (prop) then
        AddTo(DeselectedProps, prop)
        RemoveFrom(SelectedProps, prop)
        prop:ResetColor()
        OnPropDeselected(prop)
    end
end

-- select all props
function SelectAllProps()
    for prop, _ in pairs(DeselectedProps) do
        AddTo(SelectedProps, prop)
        RemoveFrom(DeselectedProps, prop)
        prop:SetColor(Colors.SELECTION_COLOR)
        OnPropSelected(prop)
    end
end

-- deselect all props
function DeselectAllProps()
    for prop, _ in pairs(SelectedProps) do
        AddTo(DeselectedProps, prop)
        RemoveFrom(SelectedProps, prop)
        prop:SetColor(Colors.DEFAULT_COLOR)
        OnPropDeselected(prop)
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

    return util.Compress(util.TableToJSON(project))
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
--render lib functions for draw stuff
--update grid mesh
function Render:UpdateGrid(scale)
    local gridMesh = Render:GetGridMesh()

    if (IsValid(gridMesh)) then
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

--draw mesh grid
function Render:DrawGrid()
    local gridMesh = self:GetGridMesh()

    if (gridMesh) then
        render.SetMaterial(Materials.GRID_MATERIAL)
        gridMesh:Draw()
    end
end

--draw all prop
function Render:DrawProps()
    for prop, _ in pairs(Props) do
        local color = prop:GetColor()
        render.SetColorModulation(color.r / 255, color.g / 255, color.b / 255)
        render.SetBlend(color.a / 255)
        prop:DrawModel()
    end
end

--draw resize contorll
function Render:DrawMoveOrResizeControll(pos, distance, beamScale, resize)
    local xPos = pos + Vector(distance, 0, 0)
    local yPos = pos + Vector(0, distance, 0)
    local zPos = pos + Vector(0, 0, distance)
    local pozScale = Vector(beamScale, beamScale, beamScale)
    local negScale = Vector(-beamScale, -beamScale, -beamScale)
    local R = Color(255, 0, 0)
    local G = Color(0, 255, 0)
    local B = Color(0, 0, 255)
    render.DrawBeam(pos, zPos, beamScale, 0, 1, G)
    render.DrawBox(zPos, Angle(0, 0, 0), negScale, pozScale, G, true)
    render.DrawBeam(pos, yPos, beamScale, 0, 1, B)
    render.DrawBox(yPos, Angle(0, 0, 0), negScale, pozScale, B, true)
    render.DrawBeam(pos, xPos, beamScale, 0, 1, R)
    render.DrawBox(xPos, Angle(0, 0, 0), negScale, pozScale, R, true)

    if (resize) then
        render.DrawBox(pos + Vector(beamScale, beamScale, 0), Angle(0, 0, 0), negScale, pozScale, Color(255, 255, 0), true)
    end
end

--draw rotate controll
function Render:DrawRotateControll(pos, beamScale)
    DrawCircle3D(pos, beamScale, 90)
end

--draw holo count and fps
function Render:DrawStats2D()
    surface.SetTextColor(255, 255, 255)
    surface.SetTextPos(10, 10)
    surface.DrawText(string.format("FPS: %d", 1 / RealFrameTime()))
    surface.SetTextPos(10, 20)
    surface.DrawText(string.format("Holos: %d / %d", Props.Count, GetConVar("wire_holograms_max"):GetInt()))
end

function Render:DrawCrosshair2D(w, h)
    surface.SetDrawColor(Color(255, 255, 255)) -- TODO: try to improve crosshair visibility
    surface.DrawLine(w * 0.5 - 12, h * 0.5, w * 0.5 + 12, h * 0.5)
    surface.DrawLine(w * 0.5, h * 0.5 - 12, w * 0.5, h * 0.5 + 12)
end

--TODO: optimize render loop for many props
function Render:DrawControlls()
    local pos = GetSelectedPropsCenter()
    Render:DrawProps()
    render.SuppressEngineLighting(true)
    Render:DrawGrid()

    if (pos) then
        local distance = pos:Distance(Camera:GetPos()) * 0.1
        local beamScale = distance * 0.1
        local mode = SelectMode:GetMode()
        render.SetColorMaterialIgnoreZ()

        if (mode == Modes.Move) then
            Render:DrawMoveOrResizeControll(pos, distance, beamScale)
        elseif (mode == Modes.Rotate) then
            Render:DrawRotateControll(pos, distance)
        elseif (mode == Modes.Resize) then
            Render:DrawMoveOrResizeControll(pos, distance, beamScale, true)
        end

        render.DrawSphere(pos, 2, 50, 50, Color(0, 255, 0))
    end

    render.SuppressEngineLighting(false)
end

------------------------------------------------------------
--util functions
--return nice model name from model obj
function Util:GetNiceModelName(prop)
    local propModel = string.StripExtension(prop:GetModel())

    return string.GetFileFromFilename(propModel)
end

--clear all callbacks
function Util:RemoveCallbacks()
    OnPropAdded.Callbacks = {}
    OnPropRemoved.Callbacks = {}
    OnPropSelected.Callbacks = {}
    OnPropDeselected.Callbacks = {}
end