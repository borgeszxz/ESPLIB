local current_camera = game:GetService("Workspace").CurrentCamera
local run_service = game:GetService("RunService")
local players = game:GetService("Players")

local ESP = {
    Enabled = true,
    BoxEnabled = true,
    BoxColor = Color3.fromRGB(255, 255, 255),
    HealthBarEnabled = true,
    HealthBarColor = Color3.fromRGB(0, 255, 0),
    NameEnabled = true,
    DistanceEnabled = true,
    MaxDistance = 2500
}

local function IsNPC(entity)
    return entity:IsA("Model") and entity:FindFirstChildOfClass("Humanoid") 
        and entity:FindFirstChild("HumanoidRootPart") 
        and not players:GetPlayerFromCharacter(entity)
end

local function calculate_box(entity)
    local character = entity
    if not character then return end

    local torso_cframe = character.HumanoidRootPart.CFrame
    local matrix_top = (torso_cframe.Position + Vector3.new(0, 0.3, 0)) + (torso_cframe.UpVector * 1.5) + current_camera.CFrame.UpVector
    local matrix_bottom = (torso_cframe.Position + Vector3.new(0, 0.4, 0)) - (torso_cframe.UpVector * 3)
    local top, top_is_visible = current_camera:WorldToViewportPoint(matrix_top)
    local bottom, bottom_is_visible = current_camera:WorldToViewportPoint(matrix_bottom)
    if not top_is_visible and not bottom_is_visible then return end

    local width = math.floor(math.abs(top.X - bottom.X))
    local height = math.floor(math.max(math.abs(bottom.Y - top.Y), width * 0.6))
    local box_size = Vector2.new(math.floor(math.max(height / 1.7, width * 1.8)), height)
    local box_position = Vector2.new(math.floor(top.X * 0.5 + bottom.X * 0.5 - box_size.X * 0.5), math.floor(math.min(top.Y, bottom.Y)))
    
    return { X = box_position.X, Y = box_position.Y, W = box_size.X, H = box_size.Y }
end

local esp_objects = {}

local function AddNPCEsp()
    for _, entity in pairs(workspace:GetDescendants()) do
        if IsNPC(entity) then
            local box = calculate_box(entity)
            if box then
                esp_objects[entity] = {
                    Box = Drawing.new("Square"),
                    Name = Drawing.new("Text"),
                    HealthBar = Drawing.new("Square"),
                    Distance = Drawing.new("Text")
                }

                esp_objects[entity].Box.Size = Vector2.new(box.W, box.H)
                esp_objects[entity].Box.Position = Vector2.new(box.X, box.Y)
                esp_objects[entity].Box.Color = ESP.BoxColor
                esp_objects[entity].Box.Thickness = 1
                esp_objects[entity].Box.Visible = ESP.BoxEnabled
                
                esp_objects[entity].Name.Text = entity.Name
                esp_objects[entity].Name.Position = Vector2.new(box.X + (box.W / 2), box.Y - 5)
                esp_objects[entity].Name.Color = Color3.fromRGB(255, 255, 255)
                esp_objects[entity].Name.Size = 14
                esp_objects[entity].Name.Center = true
                esp_objects[entity].Name.Visible = ESP.NameEnabled
                
                local distance = (entity.HumanoidRootPart.Position - game.Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                esp_objects[entity].Distance.Text = string.format("[%.1fm]", distance)
                esp_objects[entity].Distance.Position = Vector2.new(box.X + (box.W / 2), box.Y + box.H + 3)
                esp_objects[entity].Distance.Color = Color3.fromRGB(255, 255, 255)
                esp_objects[entity].Distance.Size = 12
                esp_objects[entity].Distance.Center = true
                esp_objects[entity].Distance.Visible = ESP.DistanceEnabled

                local health = entity:FindFirstChildOfClass("Humanoid").Health
                local max_health = entity:FindFirstChildOfClass("Humanoid").MaxHealth
                local health_percent = math.clamp(health / max_health, 0, 1)

                esp_objects[entity].HealthBar.Size = Vector2.new(3, box.H * health_percent)
                esp_objects[entity].HealthBar.Position = Vector2.new(box.X - 5, box.Y + (box.H * (1 - health_percent)))
                esp_objects[entity].HealthBar.Color = ESP.HealthBarColor
                esp_objects[entity].HealthBar.Thickness = 1
                esp_objects[entity].HealthBar.Visible = ESP.HealthBarEnabled
            end
        end
    end
end

workspace.DescendantAdded:Connect(function(obj)
    task.wait(1)
    if IsNPC(obj) then
        AddNPCEsp()
    end
end)

run_service.RenderStepped:Connect(function()
    if ESP.Enabled then
        AddNPCEsp()
    else
        for _, obj in pairs(esp_objects) do
            obj.Box.Visible = false
            obj.Name.Visible = false
            obj.HealthBar.Visible = false
            obj.Distance.Visible = false
        end
    end
end)

AddNPCEsp()

return ESP
