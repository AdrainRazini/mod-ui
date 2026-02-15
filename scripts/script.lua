-- Script Colocar Objeto 

local args = {
    [1] = game:GetService("Players").LocalPlayer.Toolbar.Spikes, -- Acesso
    [2] = Vector3.new(302.5, 38.79999923706055, 1822.5), -- Poss
    [3] = Vector3.new(0, 44.72301483154297, 0) -- Rotação
}

game:GetService("ReplicatedStorage").Network.Items.BuildItem:FireServer(unpack(args))

-- 