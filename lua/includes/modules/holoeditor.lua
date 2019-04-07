--send module to client
AddCSLuaFile()
------------------------------------------------------------
--create module
module("HoloEditor", package.seeall)
------------------------------------------------------------
--precache functions and table
------------------------------------------------------------
--consts
local scrW = ScrW()
local scrH = ScrH()
local centerW = scrW * 0.5
local centerH = scrH * 0.5
local addonDirectory = "holo"
------------------------------------------------------------
--base table and other
Util = include("util.lua")
File = include("file.lua")
Render = include("render.lua")
Controlls = include("controlls.lua")
Camera = include("camera.lua")
Trace = include("trace.lua")
Props = Util:CreatePropTable()
SelectedProps = Util:CreatePropTable()
DeselectedProps = Util:CreatePropTable()
EditorWindows = nil
local Materials = Render.Materials
local SelectMode = Controlls.SelectMode
local Modes = SelectMode.Modes
------------------------------------------------------------
--callbacks
--call when new prop added
OnPropAdded = Util:CreateCallback()
--call when prop removed
OnPropRemoved = Util:CreateCallback()
--call when prop selected
OnPropSelected = Util:CreateCallback()
--call when prop deselected
OnPropDeselected = Util:CreateCallback()

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

    --!для отладки выделения, убрать нахой
    prop:SetPos(Vector(20 * Props.Count, 0, 0))
    Util:AddTo(Props, prop)

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
        Util:RemoveFrom(SelectedProps, prop)
        Util:RemoveFrom(DeselectedProps, prop)
        Util:RemoveFrom(Props, prop)
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
        Util:AddTo(SelectedProps, prop)
        Util:RemoveFrom(DeselectedProps, prop)
        Controlls:Update(Camera, SelectedProps, propPos, propAng)
        OnPropSelected(prop)
        Render:DrawHalos(prop)
    end
end

-- deselect prop
function DeselectProp(slf, prop)
    if (prop) then
        local propPos = prop:GetPos() * -1
        local propAng = prop:GetAngles()
        Util:AddTo(DeselectedProps, prop)
        Util:RemoveFrom(SelectedProps, prop)
        prop:ResetColor()
        Controlls:Update(Camera, SelectedProps, propPos, propAng)
        OnPropDeselected(prop)
        Render:DrawHalos(prop)
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