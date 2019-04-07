--render lib functions for draw stuff
local Colors = include("colors.lua")
local Util = include("util.lua")
local Controlls = include("controlls.lua")

local Render = {
    GridSize,
    GridMesh,
    Materials = {
        GRID_MATERIAL = Material("editor/wireframe")
    }
}

AccessorFunc(Render, "GridSize", "GridSize", FORCE_NUMBER)
AccessorFunc(Render, "GridMesh", "GridMesh")

local function AddVertex(mesh, pos, u, v, color)
    mesh.Position(pos)
    mesh.TexCoord(0, u, v)
    mesh.Color(color.r, color.g, color.b, color.a)
    mesh.AdvanceVertex()
end

--update grid mesh
function Render:UpdateGrid(scale)
    local gridMesh = self:GetGridMesh()

    if (IsValid(gridMesh)) then
        gridMesh:Destroy()
    end

    self:SetGridMesh(Mesh())
    local gridSize = self:GetGridSize()
    local gridColor = Colors.GRID_COLOR
    local lineLenght = gridSize * scale
    local center = lineLenght * 0.5
    local offset = Vector(center, center, 0)
    gridMesh = self:GetGridMesh()
    mesh.Begin(gridMesh, MATERIAL_LINES, scale * 2 + 4)

    for i = 0, scale do
        local pos = i * gridSize
        local vec1 = Vector(pos, lineLenght, 0) - offset
        local vec2 = Vector(pos, 0, 0) - offset
        local vec3 = Vector(lineLenght, pos, 0) - offset
        local vec4 = Vector(0, pos, 0) - offset
        mesh.Position(vec1)
        mesh.TexCoord(0, 0, 0)
        mesh.Color(gridColor.r, gridColor.g, gridColor.b, gridColor.a)
        mesh.AdvanceVertex()
        mesh.Position(vec2)
        mesh.TexCoord(0, 0, 0)
        mesh.Color(gridColor.r, gridColor.g, gridColor.b, gridColor.a)
        mesh.AdvanceVertex()
        mesh.Position(vec3)
        mesh.TexCoord(0, 0, 0)
        mesh.Color(gridColor.r, gridColor.g, gridColor.b, gridColor.a)
        mesh.AdvanceVertex()
        mesh.Position(vec4)
        mesh.TexCoord(0, 0, 0)
        mesh.Color(gridColor.r, gridColor.g, gridColor.b, gridColor.a)
        mesh.AdvanceVertex()
    end

    mesh.End()
end

--draw mesh grid
function Render:DrawGrid()
    local gridMesh = self:GetGridMesh()

    if (gridMesh) then
        render.SetMaterial(self.Materials.GRID_MATERIAL)
        gridMesh:Draw()
    end
end

--draw all prop
function Render:DrawProps(props)
    for prop, _ in pairs(props) do
        local color = prop:GetColor()
        render.SetColorModulation(color.r / 255, color.g / 255, color.b / 255)
        render.SetBlend(color.a / 255)
        prop:DrawModel()
    end
end

--draw resize contorll
function Render:DrawMoveOrResizeControll(resize)
    local pos = Controlls:GetCenter()
    local xPos = Controlls:GetX()
    local yPos = Controlls:GetY()
    local zPos = Controlls:GetZ()
    local beamScale = Controlls:GetBeamScale()
    local pozScale = Vector(beamScale, beamScale, beamScale)
    local negScale = Vector(-beamScale, -beamScale, -beamScale)
    render.DrawLine(pos, pos + xPos, Colors.RED_A)
    render.DrawBox(pos + xPos, Angle(0, 0, 0), negScale, pozScale, Colors.RED_A, true)
    render.DrawLine(pos, pos + yPos, Colors.BLUE_A)
    render.DrawBox(pos + yPos, Angle(0, 0, 0), negScale, pozScale, Colors.BLUE_A, true)
    render.DrawLine(pos, pos + zPos, Colors.GREEN_A)
    render.DrawBox(pos + zPos, Angle(0, 0, 0), negScale, pozScale, Colors.GREEN_A, true)

    if (resize) then
        local wPos = Controlls:GetW()
        render.DrawLine(pos, pos + wPos, Colors.YELLOW_A)
        render.DrawBox(pos + wPos, Angle(0, 0, 0), negScale, pozScale, Colors.YELLOW_A, true)
    end
end

--draw rotate controll
function Render:DrawRotateControll()
    local radius = Controlls:GetBeamScale()
    local pos = Controlls:GetCenter()

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
function Render:DrawStats2D(props)
    surface.SetTextColor(255, 255, 255)
    surface.SetTextPos(10, 10)
    surface.DrawText(string.format("FPS: %d", 1 / RealFrameTime()))
    surface.SetTextPos(10, 20)
    surface.DrawText(string.format("Holos: %d / %d", props.Count, GetConVar("wire_holograms_max"):GetInt()))
end

--draw 2d crosshair
function Render:DrawCrosshair2D(w, h)
    -- TODO: try to improve crosshair visibility
    surface.SetDrawColor(Colors.DEFAULT_COLOR)
    surface.DrawLine(w * 0.5 - 12, h * 0.5, w * 0.5 + 12, h * 0.5)
    surface.DrawLine(w * 0.5, h * 0.5 - 12, w * 0.5, h * 0.5 + 12)
end

--TODO: optimize render loop for many props
function Render:DrawControlls(props, selectedProps, deselectedProps)
    self:DrawProps(props)
    render.SuppressEngineLighting(true)
    self:DrawGrid()

    if (selectedProps.Count > 0) then
        render.SetColorMaterialIgnoreZ()
        local mode = Controlls.SelectMode:GetMode()
        local modes = Controlls.SelectMode.Modes

        if (mode == modes.Move) then
            self:DrawMoveOrResizeControll()
        elseif (mode == modes.Rotate) then
            self:DrawRotateControll()
        elseif (mode == modes.Resize) then
            self:DrawMoveOrResizeControll(true)
        end

        render.DrawSphere(Controlls:GetCenter(), Controlls:GetBeamScale(), 50, 50, Color(0, 255, 0, 100))
    end

    render.SuppressEngineLighting(false)
end

function Render:DrawHalos(prop)
    hook.Remove("PreDrawHalos", "HoloEditorPropsHalos")

    hook.Add("PreDrawHalos", "HoloEditorPropsHalos", function()
        halo.Add({prop}, Color(255, 0, 0), 2, 2, 1, true, true)
    end)
end

function Render:RemoveHalos()
    hook.Remove("PreDrawHalos", "HoloEditorPropsHalos")
end

return Render