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
local addonDirectory = "holo"

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

------------------------------------------------------------
--base table and other
Colors = {
    SELECTION_COLOR = Color(5, 190, 232),
    DEFAULT_COLOR = Color(255, 255, 255),
    GRID_COLOR = Color(17, 74, 122, 200),
    RED = Color(255, 0, 0),
    GREEN = Color(0, 255, 0),
    BLUE = Color(0, 0, 255),
    YELLOW = Color(255, 255, 0),
    RED_A = Color(255, 0, 0, 100),
    GREEN_A = Color(0, 255, 0, 100),
    BLUE_A = Color(0, 0, 255, 100),
    YELLOW_A = Color(255, 255, 0, 100)
}

Render = {
    GridSize,
    GridMesh,
    Materials = {
        GRID_MATERIAL = Material("editor/wireframe")
    }
}

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

Util = {}
File = {}

ControllsPosition = {
    Local = false,
    X = Vector(),
    Y = Vector(),
    Z = Vector(),
    W = Vector(),
    Center = Vector(),
    Angle = Angle(),
    BeamScale = 0
}

local Materials = Render.Materials
local Modes = SelectMode.Modes
------------------------------------------------------------
--autogen getter setter for table value
AccessorFunc(Camera, "Pos", "Pos")
AccessorFunc(Camera, "Ang", "Ang")
AccessorFunc(Camera, "FOV", "FOV", FORCE_NUMBER)
AccessorFunc(Render, "GridSize", "GridSize", FORCE_NUMBER)
AccessorFunc(Render, "GridMesh", "GridMesh")
AccessorFunc(SelectMode, "MutiselectMode", "MutiselectMode", FORCE_BOOL)
AccessorFunc(SelectMode, "Mode", "Mode", FORCE_NUMBER)
AccessorFunc(ControllsPosition, "Local", "Local", FORCE_BOOL)
AccessorFunc(ControllsPosition, "X", "X")
AccessorFunc(ControllsPosition, "Y", "Y")
AccessorFunc(ControllsPosition, "Z", "Z")
AccessorFunc(ControllsPosition, "W", "W")
AccessorFunc(ControllsPosition, "Center", "Center")
AccessorFunc(ControllsPosition, "Angle", "Angle")
AccessorFunc(ControllsPosition, "BeamScale", "BeamScale", FORCE_NUMBER)

------------------------------------------------------------
--functions
--init camera and setup all setings
function Init()
    SelectMode:SetMutiselectMode(true)
    SelectMode:SetMode(Modes.Resize)
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
    util.PrecacheModel(propModel, RENDERGROUP_BOTH)
    local prop = ClientsideModel(propModel)
    if (not IsValid(prop)) then return end
    selectProp = selectProp or SelectMode:GetMutiselectMode()
    local defaultColor = prop:GetColor()
    prop.DefaultColor = defaultColor

    function prop:ResetColor()
        self:SetColor(self.DefaultColor)
    end

    function prop:SetDefaultColor(color)
        self.DefaultColor = color
    end

    prop:SetPos(Vector(20 * Props.Count, 0, 0)) --TODO: для отладки выделения убрать нахой
    AddTo(Props, prop)

    if (selectProp) then
        self:SelectProp(prop)
    else
        self:DeselectProp(prop)
    end

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
        local propPos = prop:GetPos()
        local propAng = prop:GetAngles()
        AddTo(SelectedProps, prop)
        RemoveFrom(DeselectedProps, prop)
        prop:SetColor(Colors.SELECTION_COLOR)
        ControllsPosition:Update(propPos, propAng)
        OnPropSelected(prop)
    end
end

-- deselect prop
function DeselectProp(slf, prop)
    if (prop) then
        local propPos = prop:GetPos() * -1
        local propAng = prop:GetAngles()
        AddTo(DeselectedProps, prop)
        RemoveFrom(SelectedProps, prop)
        prop:ResetColor()
        ControllsPosition:Update(propPos, propAng)
        OnPropDeselected(prop)
    end
end

-- select all props
function SelectAllProps()
    for prop, _ in pairs(DeselectedProps) do
        SelectProp(prop)
    end
end

-- deselect all props
function DeselectAllProps()
    for prop, _ in pairs(SelectedProps) do
        DeselectProp(prop)
    end
end

------------------------------------------------------------
--file library
--saves project to the file, overwriting
function File:SaveProject(fileName)
    fileName = fileName or "default_output.txt" -- FIXME: только для о��ладки
    local fullFileName = addonDirectory .. "/" .. fileName .. ".txt"
    local projectProps = {}

    for prop, _ in pairs(Props) do
        local propData = {
            Position = prop:GetPos(),
            Angles = prop:GetAngles(),
            Scale = prop:GetManipulateBoneScale(0),
            Color = prop:GetColor(),
            Material = prop:GetMaterial(),
            Model = prop:GetModel(),
            IsFullbright = prop.IsFullbright == true,
            Skin = prop:GetSkin() -- TODO: include Bodygroups, Clips, SubMaterials
        }

        table.insert(projectProps, propData)
    end

    local project = {
        FormatVersion = 0,
        Props = projectProps
    }

    local projectString = util.Compress(util.TableToJSON(project, true))

    if (not file.Exists(addonDirectory, "DATA")) then
        file.CreateDir(addonDirectory)
    end

    file.Write(fullFileName, projectString)
end

--loads project from the file
--returns true if successful, otherwise returns false plus error number
function File:LoadProject(fileName)
    fileName = fileName or "default" -- FIXME: только для отладки
    local fullFileName = addonDirectory .. "/" .. fileName .. ".txt"
    if (not file.Exists(fullFileName, "DATA")) then return false, 0 end
    RemoveAllProps()
    projectString = file.Read(fullFileName, "DATA")
    project = util.JSONToTable(util.Decompress(projectString))
    if (project == nil) then return false, 1 end

    local safe, err = pcall(function()
        for i, propData in pairs(project.Props) do
            local prop = AddProp(slf, propData.Model, false)
            prop:SetPos(propData.Position)
            prop:SetAngles(propData.Angles)
            prop:ManipulateBoneScale(0, propData.Scale)
            prop:SetDefaultColor(propData.Color)
            prop:ResetColor()
            prop:SetMaterial(propData.Material)
            prop.IsFullbright = propData.IsFullbright
            prop:SetSkin(propData.Skin)
        end
    end)

    if (not safe) then
        RemoveAllProps()
        Util:Log(err)

        return false, 2
    end

    return true
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
--@return util.AimVector(ang, fov, x, y, w, h)
function Trace:AimDirection(ang, fov, x, y, w, h)
    ang = ang or Camera:GetAng()
    fov = fov or Camera:GetFOV()
    x = x or centerW
    y = y or centerH
    w = w or scrW
    h = h or scrH

    return util.AimVector(ang, fov, x, y, w, h)
end

--get trace result for cursor
--@return isHit,distance to target from camera
function Trace:IsCursorHit(cursorX, cursorY, viewportW, viewportH, targetPosition, targetRadius)
    local traceOrigin = Camera:GetPos()
    local traceDirection = Trace:AimDirection(_, _, cursorX, cursorY, viewportW, viewportH)
    local dotNormal = traceDirection:Dot((targetPosition - traceOrigin):GetNormalized())
    local dot = math.acos(dotNormal)
    local targetDistance = targetPosition:Distance(traceOrigin)
    local angle = math.asin(targetRadius / targetDistance)

    return dot < angle, targetDistance
end

--get trace result if hit the line
function Trace:IsHitLine(cursorX, cursorY, viewportW, viewportH, lineStart, lineEnd)
    local traceOrigin = Camera:GetPos()
    local traceDirection = Trace:AimDirection(_, _, cursorX, cursorY, viewportW, viewportH)
    traceDirection = traceDirection * traceDirection:Distance(lineStart)
    local distance, nearestPoint, distanceLineStart = util.DistanceToLine(lineStart, lineEnd, traceDirection)
    debugoverlay.Line(Camera:GetPos(), traceDirection, 5, Color(255, 0, 0), true)
    debugoverlay.Line(lineStart, lineEnd, 5, Color(0, 255, 255), true)
    debugoverlay.Box(nearestPoint, Vector(-1, -1, -1), Vector(1, 1, 1), 5, Color(0,255,0))
    --print(distance)
    print(nearestPoint)
    --print(distanceLineStart)
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
function Render:DrawMoveOrResizeControll(resize)
    local pos = ControllsPosition:GetCenter()
    local xPos = ControllsPosition:GetX()
    local yPos = ControllsPosition:GetY()
    local zPos = ControllsPosition:GetZ()
    local beamScale = ControllsPosition:GetBeamScale()
    local pozScale = Vector(beamScale, beamScale, beamScale)
    local negScale = Vector(-beamScale, -beamScale, -beamScale)
    render.DrawLine(pos, pos + xPos, Colors.RED_A)
    render.DrawBox(pos + xPos, Angle(0, 0, 0), negScale, pozScale, Colors.RED_A, true)
    render.DrawLine(pos, pos + yPos, Colors.BLUE_A)
    render.DrawBox(pos + yPos, Angle(0, 0, 0), negScale, pozScale, Colors.BLUE_A, true)
    render.DrawLine(pos, pos + zPos, Colors.GREEN_A)
    render.DrawBox(pos + zPos, Angle(0, 0, 0), negScale, pozScale, Colors.GREEN_A, true)

    if (resize) then
        local wPos = ControllsPosition:GetW()
        render.DrawLine(pos, pos + wPos, Colors.YELLOW_A)
        render.DrawBox(pos + wPos, Angle(0, 0, 0), negScale, pozScale, Colors.YELLOW_A, true)
    end
end

--draw rotate controll
function Render:DrawRotateControll()
    local radius = ControllsPosition:GetBeamScale()
    local pos = ControllsPosition:GetCenter()

    for i = 0, 30 do
        local point1 = math.rad((i / 30) * -360)
        local point2 = math.rad(((i + 1) / 30) * -360)
        local startPoint1 = math.sin(point1) * radius
        local endPoint1 = math.cos(point1) * radius
        local startNextPoint1 = math.sin(point2) * radius
        local startNextPoint2 = math.cos(point2) * radius
        render.DrawLine(pos + Vector(startPoint1, endPoint1, 0), pos + Vector(startNextPoint1, startNextPoint2, 0), Colors.RED_A)
        render.DrawLine(pos + Vector(startPoint1, 0, endPoint1), pos + Vector(startNextPoint1, 0, startNextPoint2), Colors.GREEN_A)
        render.DrawLine(pos + Vector(0, startPoint1, endPoint1), pos + Vector(0, startNextPoint1, startNextPoint2), Colors.BLUE_A)
    end
end

--draw holo count and fps
function Render:DrawStats2D()
    surface.SetTextColor(255, 255, 255)
    surface.SetTextPos(10, 10)
    surface.DrawText(string.format("FPS: %d", 1 / RealFrameTime()))
    surface.SetTextPos(10, 20)
    surface.DrawText(string.format("Holos: %d / %d", Props.Count, GetConVar("wire_holograms_max"):GetInt()))
end

--drwa 2d crosshair
function Render:DrawCrosshair2D(w, h)
    surface.SetDrawColor(Colors.DEFAULT_COLOR) -- TODO: try to improve crosshair visibility
    surface.DrawLine(w * 0.5 - 12, h * 0.5, w * 0.5 + 12, h * 0.5)
    surface.DrawLine(w * 0.5, h * 0.5 - 12, w * 0.5, h * 0.5 + 12)
end

--TODO: optimize render loop for many props
function Render:DrawControlls()
    Render:DrawProps()
    render.SuppressEngineLighting(true)
    Render:DrawGrid()

    if (SelectedProps.Count > 0) then
        render.SetColorMaterialIgnoreZ()
        local mode = SelectMode:GetMode()

        if (mode == Modes.Move) then
            Render:DrawMoveOrResizeControll()
        elseif (mode == Modes.Rotate) then
            Render:DrawRotateControll()
        elseif (mode == Modes.Resize) then
            Render:DrawMoveOrResizeControll(true)
        end

        render.DrawSphere(ControllsPosition:GetCenter(), ControllsPosition:GetBeamScale(), 50, 50, Color(0, 255, 0, 100))
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

--print message to console with prefix
function Util:Log(...)
    local printResult = "\n"
    local args = {...}
    local colorH = args[1]
    print(colorH)

    if (isnumber(colorH)) then
        table.remove(args, 1)
    end

    for k, v in pairs(args) do
        printResult = printResult .. "\t\t" .. tostring(k) .. ":\t" .. tostring(v) .. "\n"
    end

    printResult = printResult .. "\n"
    MsgC(Color(255, 0, 255), "HoloEditor:\t", HSVToColor(colorH, 1, 1), printResult)
end

------------------------------------------------------------
--lib for change control position
--update controlls angle
function ControllsPosition:UpdateAngle(propAngle)
    local ang = (not SelectMode:GetMutiselectMode() and self:GetLocal()) and propAngle or Angle()
    self:SetAngle(ang)
end

--update controlls scale
function ControllsPosition:UpdateScale()
    local distance = self:GetCenter():Distance(Camera:GetPos()) * 0.1
    local beamScale = distance * 0.1
    self:SetX(Vector(distance, 0, 0))
    self:SetY(Vector(0, distance, 0))
    self:SetZ(Vector(0, 0, distance))
    self:SetW(Vector(distance, distance, distance) * 0.5)
    self:SetBeamScale(beamScale)
end

--update controls position for nex rendering
function ControllsPosition:Update(propPos, propAng)
    local center = Vector()

    for prop, _ in pairs(SelectedProps) do
        center = center + prop:GetPos()
    end

    self:SetCenter(center / SelectedProps.Count)
    self:UpdateAngle()
    self:UpdateScale()
end