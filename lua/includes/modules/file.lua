--file library
local File = {}

--saves project to the file, overwriting
function File:SaveProject(fileName)
    fileName = fileName or "default_output.txt" --!только для отладки
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
    fileName = fileName or "default" --!FIXME: только для отладки
    local fullFileName = addonDirectory .. "/" .. fileName .. ".txt"
    if (not file.Exists(fullFileName, "DATA")) then return false, 0 end
    RemoveAllProps()
    local projectString = file.Read(fullFileName, "DATA")
    local project = util.JSONToTable(util.Decompress(projectString))
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

return File