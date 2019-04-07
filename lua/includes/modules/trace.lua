--trace lib functions for hit testing in 3D space
local Trace = {}

--get aim direction from screen to world
--@return util.AimVector(ang, fov, x, y, w, h)
function Trace:AimDirection(camera, ang, fov, x, y, w, h)
    ang = ang or camera:GetAng()
    fov = fov or camera:GetFOV()
    x = x or centerW
    y = y or centerH
    w = w or scrW
    h = h or scrH

    return util.AimVector(ang, fov, x, y, w, h)
end

--get trace result for cursor
--@return isHit,distance to target from camera
function Trace:IsCursorHit(camera, cursorX, cursorY, viewportW, viewportH, targetPosition, targetRadius)
    local traceOrigin = camera:GetPos()
    local traceDirection = self:AimDirection(camera, _, _, cursorX, cursorY, viewportW, viewportH)
    local dotNormal = traceDirection:Dot((targetPosition - traceOrigin):GetNormalized())
    local dot = math.acos(dotNormal)
    local targetDistance = targetPosition:Distance(traceOrigin)
    local angle = math.asin(targetRadius / targetDistance)

    return dot < angle, targetDistance
end

--get trace result if hit the line
function Trace:IsHitLine(camera, cursorX, cursorY, viewportW, viewportH, lineStart, lineEnd)
    --local traceOrigin = Camera:GetPos()
    local traceDirection = Trace:AimDirection(camera, _, _, cursorX, cursorY, viewportW, viewportH)
    traceDirection = traceDirection * traceDirection:Distance(lineStart)
    local _, nearestPoint, _ = util.DistanceToLine(lineStart, lineEnd, traceDirection)
    debugoverlay.Line(camera:GetPos(), traceDirection, 5, Color(255, 0, 0), true)
    debugoverlay.Line(lineStart, lineEnd, 5, Color(0, 255, 255), true)
    debugoverlay.Box(nearestPoint, Vector(-1, -1, -1), Vector(1, 1, 1), 5, Color(0, 255, 0))
end

return Trace