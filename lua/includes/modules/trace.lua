--trace lib functions for hit testing in 3D space
local Trace = {}

--get trace result for cursor
--@return isHit,distance to target from camera
function Trace:IsCursorHit(traceDirection, startPos, targetPosition, targetRadius)
    local dotNormal = traceDirection:Dot((targetPosition - startPos):GetNormalized())
    local dot = math.acos(dotNormal)
    local targetDistance = targetPosition:Distance(startPos)
    local angle = math.asin(targetRadius / targetDistance)

    return dot < angle, targetDistance
end

--get trace result if hit the line
function Trace:IsHitLine(traceDirection, lineStart, lineEnd)
    traceDirection = traceDirection * traceDirection:Distance(lineStart)
    local _, nearestPoint, _ = util.DistanceToLine(lineStart, lineEnd, traceDirection)
    debugoverlay.Line(camera:GetPos(), traceDirection, 5, Color(255, 0, 0), true)
    debugoverlay.Line(lineStart, lineEnd, 5, Color(0, 255, 255), true)
    debugoverlay.Box(nearestPoint, Vector(-1, -1, -1), Vector(1, 1, 1), 5, Color(0, 255, 0))
end

return Trace