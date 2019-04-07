local Camera = {
    CamPos = Vector(),
    CamAng = Angle(),
    CamFOV = 90
}

AccessorFunc(Camera, "Pos", "Pos")
AccessorFunc(Camera, "Ang", "Ang")
AccessorFunc(Camera, "FOV", "FOV", FORCE_NUMBER)

return Camera