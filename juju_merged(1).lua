-- ============================================================
-- LINORIA REWRITE PREAMBLE
-- All dependencies needed before the logic block
-- ============================================================

repeat wait() until game:IsLoaded()

-- > ( services )
local user_input_service = cloneref(game:GetService("UserInputService"))
local get_mouse_location = user_input_service["GetMouseLocation"]
local players_service = cloneref(game:GetService("Players"))
local local_player = players_service["LocalPlayer"]
local mouse = local_player:GetMouse()
local tween_service = cloneref(game:GetService("TweenService"))
local get_value = tween_service["GetValue"]
local run_service = cloneref(game:GetService("RunService"))
local workspace = workspace
local camera = cloneref(workspace["CurrentCamera"])

-- > ( math / type aliases )
local color3_fromrgb = Color3["fromRGB"]
local vector2_new = Vector2["new"]
local vector3_new = Vector3["new"]
local cframe_new = CFrame["new"]
local math_random = math["random"]
local math_sqrt = math["sqrt"]
local clock = os["clock"]
local delay = task and task["delay"] or delay or function(t, f) wait(t) f() end
local spawn = task and task["spawn"] or spawn or coroutine.wrap
local clamp = math["clamp"]
local floor = math["floor"]
local wait = task and task["wait"] or wait
local pi = math["pi"]
local cos = math["cos"]
local abs = math["abs"]
local render_stepped = run_service["RenderStepped"]
local render_stepped_wait = render_stepped["Wait"]
local exponential = Enum["EasingStyle"]["Exponential"]
local circular = Enum["EasingStyle"]["Circular"]
local quad = Enum["EasingStyle"]["Quad"]
local out = Enum["EasingDirection"]["Out"]

-- > ( world aliases )
local world_to_viewport_point = camera["WorldToViewportPoint"]
local viewport_point_to_ray = camera["ViewportPointToRay"]
local destroy = game["Destroy"]
local clone = workspace["Clone"]
local bush = workspace["Bush"]
local vehicles = workspace["Vehicles"]
local ignored = workspace["Ignored"]

-- > ( utility functions )
local connections = {}
local heartbeat = {}
local anti_aim = {}

local create_connection = function(signal, callback)
    local connection = signal:Connect(callback)
    connections[#connections + 1] = connection
    return connection
end

local remove = function(tbl, index)
    local length = #tbl
    for i = index, length - 1 do
        tbl[i] = tbl[i + 1]
    end
    tbl[length] = nil
end

local round = function(num, decimals)
    local mult = 10^(decimals or 0)
    return floor(num * mult + 0.5 - (num < 0 and 1 or 0)) / mult
end

-- > ( raycast params )
local params = RaycastParams["new"]()
params["FilterType"] = Enum["RaycastFilterType"]["Exclude"]
local raycast = workspace["Raycast"]

-- > ( drawing )
local real_drawing = getgenv()["Drawing"]
local create_real_drawing = function(class, properties)
    local object = real_drawing["new"](class)
    for property, value in properties do
        object[property] = value
    end
    return object
end

-- > ( cheat state )
local legitbot_target = nil
local player_data = {}
local local_guns = {}
local local_character = local_player["Character"]
local local_reloading = false
local local_parts = {}
local local_ping = 50
local local_fps = 200
local local_gun = nil
local local_client_position = cframe_new()
local local_server_position = cframe_new()
local in_void = false
local get_backtrack_models = nil

local set_legitbot_target = nil
local set_aim_assist_position = nil

-- > ( flags - all defaults )
local flags = {
    ["aim_assist"] = false,
    ["aim_assist_field_of_view"] = 30,
    ["aim_assist_dead_zone"] = 0,
    ["aim_assist_horizontal_smoothing_amount"] = 45,
    ["aim_assist_vertical_smoothing_amount"] = 45,
    ["aim_assist_smoothing_type"] = {"random"},
    ["aim_assist_hitbox"] = {"head"},
    ["aim_assist_method"] = {"mouse"},
    ["aim_assist_multipoint"] = 15,
    ["aim_assist_max_distance"] = 0,
    ["aim_assist_dont_aim_if_no_gun_equipped"] = true,
    ["aim_assist_dont_aim_if_reloading"] = true,
    ["aim_assist_field_of_view_show_fov"] = false,
    ["aim_assist_field_of_view_color"] = color3_fromrgb(181, 255, 246),
    ["aim_assist_field_of_view_transparency"] = 0.8,
    ["aim_assist_field_of_view_outline_color"] = color3_fromrgb(181, 255, 246),
    ["aim_assist_field_of_view_outline_transparency"] = 0.4,
    ["aim_assist_field_of_view_dead_zone_color"] = color3_fromrgb(155, 0, 0),
    ["aim_assist_field_of_view_dead_zone_transparency"] = 0.8,
    ["silent_aim"] = false,
    ["silent_aim_fov"] = 30,
    ["silent_aim_max_curve"] = 100,
    ["silent_aim_dont_curve_vertically"] = false,
    ["silent_aim_redirect_chance"] = 100,
    ["triggerbot"] = false,
    ["triggerbot_max_distance"] = 0,
    ["triggerbot_hitboxes"] = {head=true, torso=true, arms=true, legs=true},
    ["triggerbot_refresh_rate"] = 0,
    ["triggerbot_cooldown"] = 0,
    ["triggerbot_delay"] = 0,
    ["triggerbot_hover_time"] = 0,
    ["triggerbot_angular_fov"] = false,
    ["triggerbot_angular_fov_value"] = 30,
    ["triggerbot_angular_fov_visualize"] = false,
    ["triggerbot_angular_fov_x"] = 2,
    ["triggerbot_angular_fov_y"] = 5,
    ["triggerbot_angular_fov_z"] = 2,
    ["jump_prediction"] = false,
    ["jump_prediction_strength"] = 50,
    ["jump_prediction_max_y"] = 5,
    ["velocity_prediction"] = false,
    ["velocity_prediction_strength"] = 50,
    ["reduce_shotgun_spread"] = false,
    ["reduce_shotgun_spread_amount"] = 50,
    ["backtrack"] = false,
    ["hitbox_expander"] = false,
    ["hitbox_expander_size_x"] = 2,
    ["hitbox_expander_size_y"] = 5,
    ["hitbox_expander_size_z"] = 2,
    ["hitbox_expander_visualize"] = false,
    ["hitbox_expander_team_check"] = false,
    ["magnetic_aim"] = false,
    ["magnetic_aim_fov"] = 30,
    ["magnetic_aim_strength"] = 50,
    ["magnetic_aim_hitbox"] = {"head"},
    ["magnetic_aim_only_when_ads"] = true,
    ["magnetic_aim_team_check"] = false,
    ["legitbot_target_selection_automatic"] = false,
    ["legitbot_target_selection_target_enemy"] = true,
    ["legitbot_target_selection_target_friendly"] = false,
    ["legitbot_target_selection_target_neutral"] = true,
    ["legitbot_ignore_if_invulnerable"] = true,
    ["legitbot_ignore_if_knocked"] = true,
    ["legitbot_ignore_if_not_visible"] = true,
    ["legitbot_untarget_when_knocked"] = true,
    ["legitbot_untarget_when_better_target"] = false,
    ["legitbot_untarget_when_off_screen"] = false,
    ["legitbot_untarget_when_not_visible"] = true,
    ["legitbot_max_distance"] = 0,
}


-- > ( player data tracker )
-- data[1] = status (1=neutral, 2=friendly, 3=enemy)
-- data[2] = player name
-- data[3] = character
-- data[4] = parts table {Name = Part}
-- data[5] = drawings (unused here)
-- data[6] = crew
-- data[7] = dead
-- data[8] = highlight (unused here)
-- data[9] = health
-- data[10] = max health
-- data[13] = equipped tool
-- data[16] = role
-- data[18] = knocked

local wait_for_child = workspace["WaitForChild"]
local get_children = workspace["GetChildren"]
local find_first_child = workspace["FindFirstChild"]
local find_first_child_of_class = workspace["FindFirstChildOfClass"]

local function register_player(player)
    if player == local_player then return end

    local data = {
        3,       -- [1] status: default enemy
        player,  -- [2] player ref
        nil,     -- [3] character
        {},      -- [4] parts
        {},      -- [5] drawings (unused)
        nil,     -- [6] crew
        false,   -- [7] dead
        nil,     -- [8] highlight
        100,     -- [9] health
        100,     -- [10] max health
        100,     -- [11] old health
        nil,     -- [12] chams
        nil,     -- [13] tool
    }

    local function on_character_added(character)
        data[3] = character
        data[7] = false
        data[18] = false

        local data_parts = data[4]
        for k in data_parts do data_parts[k] = nil end

        local children = character:GetChildren()
        for i = 1, #children do
            local child = children[i]
            data_parts[child["Name"]] = child
        end

        create_connection(character["ChildAdded"], function(child)
            data_parts[child["Name"]] = child
            if child["ClassName"] == "Tool" then
                data[13] = child
            end
        end)
        create_connection(character["ChildRemoved"], function(child)
            data_parts[child["Name"]] = nil
            if child["ClassName"] == "Tool" then data[13] = nil end
        end)

        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
            create_connection(humanoid:GetPropertyChangedSignal("Health"), function()
                data[9] = math["floor"](humanoid["Health"])
            end)
        end

        local head = character:FindFirstChild("Head")
        if head then
            create_connection(head:GetPropertyChangedSignal("Parent"), function()
                if head["Parent"] == nil then data[7] = true end
            end)
        end

        -- wait for body effects
        spawn(function()
            local body_effects = character:WaitForChild("BodyEffects", 9e9)
            if not body_effects then return end
            local knocked_val = body_effects:WaitForChild("K.O", 9e9)
            local dead_val = body_effects:WaitForChild("SDeath", 9e9)
            local armor_val = body_effects:WaitForChild("Armor", 9e9)
            if knocked_val then
                data[18] = knocked_val["Value"]
                create_connection(knocked_val:GetPropertyChangedSignal("Value"), function()
                    data[18] = knocked_val["Value"]
                end)
            end
            if dead_val then
                data[7] = dead_val["Value"]
                create_connection(dead_val:GetPropertyChangedSignal("Value"), function()
                    data[7] = dead_val["Value"]
                end)
            end
        end)
    end

    player_data[player] = data

    if player["Character"] then
        spawn(on_character_added, player["Character"])
    end
    create_connection(player["CharacterAdded"], on_character_added)
end

-- register existing players
local all_players = players_service:GetPlayers()
for i = 1, #all_players do
    spawn(register_player, all_players[i])
end
create_connection(players_service["PlayerAdded"], register_player)
create_connection(players_service["PlayerRemoving"], function(player)
    if legitbot_target and legitbot_target[1] == player_data[player] then
        set_legitbot_target(nil)
    end
    player_data[player] = nil
end)

-- > ( local character tracking )
create_connection(local_player["CharacterAdded"], function(character)
    local_character = character
    local_parts = {}
    local children = character:GetChildren()
    for i = 1, #children do
        local child = children[i]
        local_parts[child["Name"]] = child
    end
    create_connection(character["ChildAdded"], function(child)
        local_parts[child["Name"]] = child
        if child["ClassName"] == "Tool" then
            local_gun = child["Name"]
        end
    end)
    create_connection(character["ChildRemoved"], function(child)
        local_parts[child["Name"]] = nil
        if child["ClassName"] == "Tool" then
            local_gun = nil
        end
    end)
end)

if local_player["Character"] then
    local_character = local_player["Character"]
    local children = local_character:GetChildren()
    for i = 1, #children do
        local child = children[i]
        local_parts[child["Name"]] = child
        if child["ClassName"] == "Tool" then
            local_gun = child["Name"]
        end
    end
end

-- > ( ping tracking handled in finalization block )


-- ============================================================
-- SIGNAL SYSTEM
-- ============================================================

local Signal = {}
Signal.__index = Signal

function Signal.new()
    local self = setmetatable({}, Signal)
    self._callbacks = {}
    return self
end

function Signal:Connect(callback)
    local id = #self._callbacks + 1
    self._callbacks[id] = callback
    return {
        Disconnect = function()
            self._callbacks[id] = nil
        end
    }
end

function Signal:Fire(...)
    for _, cb in self._callbacks do
        pcall(cb, ...)
    end
end

signals = {
    ["on_legitbot_target_changed"]   = Signal.new(),
    ["on_vehicle_sat_in"]            = Signal.new(),
    ["on_local_tool_equipped"]       = Signal.new(),
    ["on_local_character_added"]     = Signal.new(),
    ["on_local_bullet_confirmed"]    = Signal.new(),
    ["on_player_status_changed"]     = Signal.new(),
    ["on_player_added"]              = Signal.new(),
    ["on_player_character_added"]    = Signal.new(),
}

-- ============================================================
-- MENU REFERENCES STUB
-- ============================================================

local function make_ref()
    return {
        on_toggle_change       = Signal.new(),
        on_slider_change       = Signal.new(),
        on_dropdown_change     = Signal.new(),
        on_key_press           = Signal.new(),
        on_color_change        = Signal.new(),
        on_transparency_change = Signal.new(),
        set_visible            = function() end,
    }
end

menu_references = setmetatable({}, {
    __index = function(t, k)
        local ref = make_ref()
        rawset(t, k, ref)
        return ref
    end
})

-- ============================================================
-- MISC STUBS REFERENCED BY LOGIC
-- ============================================================

backtrack_data  = {}
ragebot_target  = nil
vehicle         = nil
purchasing      = false
cached_backtrack_models = {}
body_parts = {
    "Head", "UpperTorso", "LowerTorso", "HumanoidRootPart",
    "LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm",
    "LeftHand", "RightHand",
    "LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg",
    "LeftFoot", "RightFoot"
}

local new_notification = function(msg, duration)
    print("[juju] " .. tostring(msg))
end


-- ============================================================
-- LOGIC BLOCK
-- ============================================================

-- ============================================================
-- JUJU LEGITBOT LOGIC - EXTRACTED & STRIPPED
-- Dependencies needed from outer scope:
--   camera, user_input_service, tween_service
--   player_data, local_player, local_character, local_parts
--   local_gun, local_reloading, local_ping
--   legitbot_target, set_legitbot_target, set_aim_assist_position
--   heartbeat, create_connection, signals
--   ignored, bush, vehicles
--   get_backtrack_models (declared as nil before this block)
--   
-- Executor globals used directly:
--   mousemoverel, mouse1press, mouse1release
--
-- Lua aliases needed:
--   vector2_new, vector3_new, cframe_new, color3_fromrgb
--   math_random, clock, delay, spawn, clamp, floor, pi, sqrt, remove
--   world_to_viewport_point, viewport_point_to_ray
--   raycast, params, render_stepped, render_stepped_wait
-- ============================================================

    -- >> ( legitbot master )

    local legitbot_ignore_if_invulnerable = true
    local legitbot_ignore_if_knocked = true
    local legitbot_ignore_if_not_visible = true
    local legitbot_untarget_when_knocked = true
    local legitbot_untarget_when_better_target = false
    local legitbot_untarget_when_off_screen = false

    local legitbot_max_distance = 0
    local legitbot_untarget_when_not_visible = true
    local target_switch_cooldown = 0
    local legitbot_automatic = false
    local legitbot_dont_aim = false
    local do_notification = false

    local target_enemy = true
    local target_neutral = true
    local target_friendly = false
    local last_target_dt = clock()
    local last_switch = clock()

    local params = RaycastParams["new"]()
    local raycast = workspace["Raycast"]

    params["FilterType"] = Enum["RaycastFilterType"]["Exclude"]
    params["FilterDescendantsInstances"] = {}

    local target_changed_signal = signals["on_legitbot_target_changed"]

    set_legitbot_target = function(target, automatic)
        if legitbot_target == target then
            return
        end

        if not automatic or (target == nil or clock() - last_switch > target_switch_cooldown) then
            last_switch = clock()

            if do_notification then
                new_notification("set legitbot target to "..(target and target[1][2]["Name"] or "nobody"), 1)
            end

            legitbot_target = target
            target_changed_signal:Fire(target and target[1] or nil)
        end
    end

    local legitbot_field_of_view = false

    local get_legitbot_target = nil; get_legitbot_target = function(dt, getting, bypass)
        local camera_pos = camera["CFrame"]["p"]
        local mouse_pos = get_mouse_location(user_input_service)

        if not bypass then
            legitbot_dont_aim = false

            if legitbot_target then
                local data = legitbot_target[1]

                if data then
                    local parts = data[4]
                    local hrp = parts["HumanoidRootPart"]
                    local hrp_position = hrp["Position"]

                    if (legitbot_untarget_when_knocked and data[18]) then
                        set_legitbot_target(legitbot_automatic and get_legitbot_target(dt, true, true) or nil)
                        return
                    end

                    if legitbot_untarget_when_not_visible then
                        local distance = hrp_position-camera_pos

                        params["FilterDescendantsInstances"] = {data[3], local_character, ignored, bush, vehicles, cached_backtrack_models}

                        if raycast(workspace, camera_pos, distance.unit * distance.Magnitude, params) then
                            set_legitbot_target(legitbot_automatic and get_legitbot_target(dt, true, true) or nil)
                            return
                        end
                    end

                    if legitbot_untarget_when_better_target then
                        local target = get_legitbot_target(dt, hrp, true)
                        if target and target[1] ~= data then
                            set_legitbot_target(legitbot_automatic and get_legitbot_target(dt, true, true) or nil, true)
                            return
                        end
                    end

                    if legitbot_max_distance == 2500 or (hrp_position-local_client_position["p"])["Magnitude"] < (legitbot_max_distance == 0 and (local_gun or 200) or legitbot_max_distance) then
                        local position, on_screen = world_to_viewport_point(camera, hrp_position)

                        if legitbot_untarget_when_off_screen and not on_screen then
                            set_legitbot_target(legitbot_automatic and get_legitbot_target(dt, true, true) or nil)
                            return
                        end

                        if legitbot_ignore_if_invulnerable and ((parts["FORCEFIELD"] or parts["ForceField"])) then
                            legitbot_dont_aim = true
                            return
                        elseif legitbot_ignore_if_knocked and data[18] then
                            legitbot_dont_aim = true
                            return
                        end

                        if legitbot_ignore_if_not_visible then
                            local distance = hrp_position-camera_pos

                            params["FilterDescendantsInstances"] = {data[3], local_character, ignored, bush, vehicles, cached_backtrack_models}
                            if raycast(workspace, camera_pos, distance.unit * distance.Magnitude, params) then
                                legitbot_dont_aim = true
                                return
                            end
                        end

                        legitbot_target = {data, hrp, (vector2_new(position["X"], position["Y"]) - mouse_pos)["Magnitude"]}
                        legitbot_dont_aim = false

                        return legitbot_target
                    end
                end
            end

            if not legitbot_automatic then
                return
            end
        end

        last_target_dt = dt
        local targets = {}

        local local_client_position = local_client_position["p"]
        local mouse_position = get_mouse_location(user_input_service)
        local cached_backtrack_models = get_backtrack_models()
        
        local field_of_view = legitbot_field_of_view and (camera["ViewportSize"]["Magnitude"]/(pi/2))*legitbot_field_of_view or false

        for player, data in player_data do
            if not data[7] and not data[18] then
                local status = data[1]

                if status == 3 and target_enemy or status == 2 and target_friendly or status == 1 and target_neutral then
                    local parts = data[4]
                    local hrp = parts["HumanoidRootPart"]

                    if hrp then
                        local hrp_position = hrp["Position"]
                        local position, on_screen = world_to_viewport_point(camera, hrp_position)

                        if on_screen and (legitbot_max_distance == 2500 or (hrp_position-local_client_position)["Magnitude"] < (legitbot_max_distance == 0 and (local_gun or 200) or legitbot_max_distance)) then
                            if legitbot_ignore_if_invulnerable and ((parts["FORCEFIELD"] or parts["ForceField"]) or parts["GRABBING_CONSTRAINT"]) then
                                continue
                            end
                            local distance = (vector2_new(position["X"], position["Y"]) - mouse_pos)["Magnitude"]

                            if field_of_view and distance > field_of_view then
                                continue
                            end
                            if legitbot_ignore_if_not_visible then
                                local distance = hrp_position-camera_pos

                                params["FilterDescendantsInstances"] = {data[3], local_character, ignored, bush, vehicles, cached_backtrack_models}
                                if raycast(workspace, camera_pos, distance.unit * distance.Magnitude, params) then
                                    continue
                                end
                            end
                            if legitbot_ignore_if_knocked and data[18] then
                                continue
                            end

                            targets[#targets+1] = {data, hrp, distance}
                        end
                    end
                end
            end
        end

        local closest = math["huge"]
        local best = nil
        for i = 1, #targets do
            local target = targets[i]
            local distance = target[3]
            if distance < closest then
                closest = distance
                best = target
            end
        end

        if getting then
            return best
        end

        set_legitbot_target(best, true)

        return best
    end

    local get_closest_part = function(data)
        local mouse_pos = get_mouse_location(user_input_service)

        local parts = data[4]
        local closest = math["huge"]
        local closest_part = nil

        for i = 1, #body_parts do
            local part = body_parts[i]
            local body_part = parts[part]
            if body_part then
                local pos, on_screen = world_to_viewport_point(camera, body_part["Position"])
                if on_screen then
                    local distance = (mouse_pos - vector2_new(pos["X"], pos["Y"])).Magnitude
                    if distance < closest then
                        closest = distance
                        closest_part = part
                    end
                end
            end
        end

        return closest_part or ""
    end

    create_connection(menu_references["legitbot_target_selection_automatic"]["on_toggle_change"], function(value)
        legitbot_dont_aim = false
        legitbot_automatic = value
        menu_references["legitbot_target_selection_target_bind"]:set_visible(not value)
    end

    create_connection(menu_references["legitbot_target_selection_target_bind"]["on_key_press"], function(value)
        if not legitbot_automatic and (flags["aim_assist"] or flags["triggerbot"] or flags["silent_aim"]) then
            if legitbot_target then
                set_legitbot_target(nil)
            else
                set_legitbot_target(get_legitbot_target(clock(), true, true))
            end
        end
    end

    create_connection(menu_references["legitbot_target_selection_ignore_if"]["on_dropdown_change"], function(value)
        legitbot_ignore_if_knocked = false
        legitbot_ignore_if_invulnerable = false
        legitbot_ignore_if_not_visible = false

        for i = 1, #value do
            local value = value[i]
            if value == "knocked" then
                legitbot_ignore_if_knocked = true
            elseif value == "invulnerable" then
                legitbot_ignore_if_invulnerable = true
            elseif value == "not visible" then
                legitbot_ignore_if_not_visible = true
            end
        end
    end

    create_connection(menu_references["legitbot_target_selection_target_switch_cooldown"]["on_slider_change"], function(value)
        target_switch_cooldown = value
    end

    create_connection(menu_references["legitbot_target_selection_max_target_distance"]["on_slider_change"], function(value)
        legitbot_max_distance = value
    end

    create_connection(menu_references["legitbot_target_selection_untarget_when"]["on_dropdown_change"], function(value)
        legitbot_untarget_when_knocked = false
        legitbot_untarget_when_better_target = false
        legitbot_untarget_when_not_visible = false
        legitbot_untarget_when_off_screen = false

        for i = 1, #value do
            local value = value[i]
            if value == "knocked" then
                legitbot_untarget_when_knocked = true
            elseif value == "not visible" then
                legitbot_untarget_when_not_visible = true
            elseif value == "better target" then
                legitbot_untarget_when_better_target = true
            elseif value == "off screen" then
                legitbot_untarget_when_off_screen = true
            end
        end
    end

    create_connection(menu_references["legitbot_target_selection_notification"]["on_toggle_change"], function(value)
        do_notification = value
    end

    create_connection(menu_references["legitbot_field_of_view"]["on_slider_change"], function(value)
        legitbot_field_of_view = value ~= 180 and value/180 or false
    end

    -- >> ( aim assist )

    local fov_circle = nil
    local fov_circle_outline = nil
    local fov_circle_dead_zone = nil

    local aim_assist_field_of_view = (camera["ViewportSize"]["Magnitude"]/(pi/2))*(flags["aim_assist_field_of_view"]/180)
    local aim_assist_dead_zone = 0
    local aim_assist_vertical_smoothing = 6
    local aim_assist_horizontal_smoothing = 6
    local aim_assist_multipoint = 0.15
    local aim_assist_hitbox = "Head"
    local aim_assist_smoothing_type = "random"
    local aim_assist_dont_aim_if_no_gun_equipped = true
    local aim_assist_dont_aim_if_reloading = true
    local aim_assist_max_distance = 0
    local aim_assist_method = "mouse"
    local custom_aim_assist_position = nil
    local magnetic_aim_enabled = false
    local magnetic_aim_fov_degrees = 30
    local magnetic_aim_strength = 50
    local magnetic_aim_hitbox = "Head"
    local magnetic_aim_only_when_ads = true
    local magnetic_aim_team_check = false

    local do_aim_assist = function(dt, local_hrp)
        local mouse_position = get_mouse_location(user_input_service)
        local cached_backtrack_models = get_backtrack_models()

        if fov_circle then
            local old_position = fov_circle["Position"]
            local new_position = old_position + (mouse_position - old_position) * dt*4^2

            fov_circle["Position"] = new_position
            fov_circle_outline["Position"] = new_position
            fov_circle_dead_zone["Position"] = new_position
        end

        if dt ~= last_target_dt and flags["aim_assist"] then
            get_legitbot_target(dt)
        end

        if legitbot_target and local_hrp then
            local distance = legitbot_target[3]
            if distance <= aim_assist_field_of_view and distance >= aim_assist_dead_zone and not legitbot_dont_aim then
                local data = legitbot_target[1]
                local part = data[4][aim_assist_hitbox == "closest" and get_closest_part(data) or aim_assist_hitbox]

                if part and not data[18] and not data[7] and (not aim_assist_dont_aim_if_no_gun_equipped or local_gun ~= nil) and (not aim_assist_dont_aim_if_reloading or not local_reloading) then
                    local part_position = custom_aim_assist_position or part["Position"]

                        -- >> ( jump prediction )
                        local jump_pred_y_delta = 0
                        if flags["jump_prediction"] then
                            local vy = part["Velocity"]["Y"]
                            if vy > 10 then
                                local gravity = workspace.Gravity
                                local t = local_ping / 500
                                local arc_y = vy * t - 0.5 * gravity * t * t
                                if arc_y > 0 then
                                    local base_pos, _ = world_to_viewport_point(camera, part_position)
                                    local arc_pos, _ = world_to_viewport_point(camera, vector3_new(part_position["X"], part_position["Y"] + arc_y, part_position["Z"]))
                                    local strength = flags["jump_prediction_strength"] / 100
                                    local max_y = -(flags["jump_prediction_max_y"] or 5)
                                    jump_pred_y_delta = clamp((arc_pos["Y"] - base_pos["Y"]) * strength, max_y, 0)
                                end
                            end
                        end

                        -- >> ( velocity prediction )
                        local vel_pred_x_delta = 0
                        if flags["velocity_prediction"] then
                            local vx = part["Velocity"]["X"]
                            local vz = part["Velocity"]["Z"]
                            local horiz_speed = math["sqrt"](vx * vx + vz * vz)
                            if horiz_speed > 5 then
                                local t = local_ping / 1000
                                local pred_pos = vector3_new(
                                    part_position["X"] + vx * t,
                                    part_position["Y"],
                                    part_position["Z"] + vz * t
                                )
                                local base_pos, _ = world_to_viewport_point(camera, part_position)
                                local pred_screen, _ = world_to_viewport_point(camera, pred_pos)
                                local strength = flags["velocity_prediction_strength"] / 100
                                vel_pred_x_delta = (pred_screen["X"] - base_pos["X"]) * strength
                            end
                        end

                    if aim_assist_max_distance == 2500 or (local_hrp["Position"]-part_position)["Magnitude"] <= (aim_assist_max_distance == 0 and (local_gun or 250) or aim_assist_max_distance) then
                        if aim_assist_multipoint ~= 0 and not custom_aim_assist_position then
                            local part_cframe = part["CFrame"]
                            local cf = part_cframe:PointToObjectSpace(mouse["Hit"]["p"])
                            local size = part["Size"]*aim_assist_multipoint

                            part_cframe*=vector3_new(clamp(cf.X, -size.X, size.X),clamp(cf.Y, -size.Y, size.Y),clamp(cf.Z, -size.Z, size.Z))
                            part_position = vector3_new(part_cframe.X, part_cframe.Y, part_cframe.Z)
                        end

                        local pos, _ = world_to_viewport_point(camera, part_position)
                        local move_position = vector2_new(pos["X"] - mouse_position["X"], pos["Y"] - mouse_position["Y"])

                        if move_position["magnitude"] > 1 then 
                            local aim_assist_horizontal_multiplier = nil
                            local aim_assist_vertical_multiplier = nil

                            if aim_assist_horizontal_smoothing == 0 then
                                aim_assist_horizontal_multiplier = 0.9999
                            elseif aim_assist_smoothing_type == "random" then
                                aim_assist_horizontal_multiplier=((dt*100)/(math_random(floor(aim_assist_horizontal_smoothing*450), floor(aim_assist_horizontal_smoothing*1100))/1000))
                            elseif aim_assist_smoothing_type == "constant" then
                                aim_assist_horizontal_multiplier=((dt*100)/aim_assist_horizontal_smoothing)
                            else
                                aim_assist_horizontal_multiplier=((dt*100)/(aim_assist_horizontal_smoothing*get_value(tween_service, move_position["Magnitude"]/aim_assist_field_of_view, aim_assist_smoothing_type, out)))
                            end

                            if aim_assist_vertical_smoothing == 0 then
                                aim_assist_vertical_multiplier = 0.9999
                            elseif aim_assist_smoothing_type == "random" then
                                aim_assist_vertical_multiplier=((dt*100)/(math_random(floor(aim_assist_vertical_smoothing*450), floor(aim_assist_vertical_smoothing*1100))/1000))
                            elseif aim_assist_smoothing_type == "constant" then
                                aim_assist_vertical_multiplier=((dt*100)/aim_assist_vertical_smoothing)
                            else
                                aim_assist_vertical_multiplier=((dt*100)/(aim_assist_vertical_smoothing*get_value(tween_service, move_position["Magnitude"]/aim_assist_field_of_view, aim_assist_smoothing_type, out)))
                            end

                            if aim_assist_method == "mouse" then
                                mousemoverel(move_position["X"]*aim_assist_horizontal_multiplier, move_position["Y"]*aim_assist_vertical_multiplier)
                                if jump_pred_y_delta ~= 0 or vel_pred_x_delta ~= 0 then
                                    mousemoverel(vel_pred_x_delta, jump_pred_y_delta)
                                end
                            elseif camera then
                                render_stepped_wait(render_stepped)
                                local old = camera["CFrame"]
                                camera["CFrame"] = old:Lerp(cframe_new(old["p"], vector3_new(part_position["X"], old["Y"], part_position["Z"])), clamp(aim_assist_horizontal_multiplier/9, 0, 1)):Lerp(cframe_new(old["p"], part_position), clamp(aim_assist_vertical_multiplier/9, 0, 1))
                                if jump_pred_y_delta ~= 0 or vel_pred_x_delta ~= 0 then
                                    mousemoverel(vel_pred_x_delta, jump_pred_y_delta)
                                end
                            end
                        end
                    end
                end
            end
        end

        custom_aim_assist_position = nil
    end

    local update_aim_assist_field_of_view = function()
        aim_assist_field_of_view = (camera["ViewportSize"]["Magnitude"]/(pi/2))*(flags["aim_assist_field_of_view"]/180)
        aim_assist_dead_zone = aim_assist_field_of_view*(flags["aim_assist_dead_zone"]/100)

        if fov_circle_outline then
            fov_circle_outline["Radius"] = aim_assist_field_of_view
        end

        if fov_circle_dead_zone then
            fov_circle_dead_zone["Radius"] = aim_assist_dead_zone
        end

        if fov_circle then
            fov_circle["Radius"] = aim_assist_field_of_view
        end
    end

    local aim_assist_camera_connection = nil

    create_connection(menu_references["aim_assist"]["on_toggle_change"], function(value)
        last_target_dt = nil

        if not value and not flags["triggerbot"] and not flags["silent_aim"] then
            delay(0.01, function()
                set_legitbot_target(nil)
                last_target_dt = nil
                silent_aim_position = nil
            end
        end

        if not value then
            delay(0.15, function()
                for i = 1, #heartbeat do
                    if heartbeat[i] == do_aim_assist then
                        remove(heartbeat, i)
                        break
                    end
                end
            end
        else
            for i = 1, #heartbeat do
                if heartbeat[i] == do_aim_assist then
                    remove(heartbeat, i)
                    break
                end
            end
        end

        if aim_assist_camera_connection then
            aim_assist_camera_connection:Disconnect()
            aim_assist_camera_connection = nil
        end

        if value then
            if fov_circle then
                tween(fov_circle, {["Transparency"] = -flags["aim_assist_field_of_view_transparency"]+1}, circular, out, 0.15)
                tween(fov_circle_outline, {['Transparency'] = -flags["aim_assist_field_of_view_outline_transparency"]+1}, circular, out, 0.15)
                tween(fov_circle_dead_zone, {['Transparency'] = -flags["aim_assist_field_of_view_dead_zone_transparency"]+1}, circular, out, 0.15)
            end
            heartbeat[#heartbeat+1] = do_aim_assist
            aim_assist_camera_connection = create_connection(camera:GetPropertyChangedSignal("ViewportSize"), update_aim_assist_field_of_view)
        elseif fov_circle then
            if fov_circle then
                tween(fov_circle, hide_transparency, circular, out, 0.15)
                tween(fov_circle_outline, hide_transparency, circular, out, 0.15)
                tween(fov_circle_dead_zone, hide_transparency, circular, out, 0.15)
            end
        end
    end

    create_connection(menu_references["aim_assist_hitbox"]["on_dropdown_change"], function(value)
        local value = value[1]
        aim_assist_hitbox = value == "head" and "Head" or value == "root" and "HumanoidRootPart" or "closest"
    end

    create_connection(menu_references["aim_assist_method"]["on_dropdown_change"], function(value)
        aim_assist_method = value[1]
    end

    create_connection(menu_references["aim_assist_max_distance"]["on_slider_change"], function(value)
        aim_assist_max_distance = value
    end

    create_connection(menu_references["aim_assist_field_of_view_show_fov"]["on_toggle_change"], function(value)
        if fov_circle then
            fov_circle:Destroy()
            fov_circle = nil
        end

        if fov_circle_outline then
            fov_circle_outline:Destroy()
            fov_circle_outline = nil
        end

        if fov_circle_dead_zone then
            fov_circle_dead_zone:Destroy()
            fov_circle_dead_zone= nil
        end

        if value then
            fov_circle = create_real_drawing("Circle", {
                ["Radius"] = aim_assist_field_of_view,
                ["Color"] = flags["aim_assist_field_of_view_color"],
                ["Filled"] = true,
                ["Transparency"] = 0,
                ["Thickness"] = 1,
                ["ZIndex"] = 12,
                ["Visible"] = true
            })
            fov_circle_outline = create_real_drawing("Circle", {
                ["Radius"] = aim_assist_field_of_view,
                ["Color"] = flags["aim_assist_field_of_view_outline_color"],
                ["Filled"] = false,
                ["Transparency"] = 0,
                ["Thickness"] = 2,
                ["ZIndex"] = 10,
                ["Visible"] = true
            })
            fov_circle_dead_zone = create_real_drawing("Circle", {
                ["Radius"] = aim_assist_dead_zone,
                ["Color"] = flags["aim_assist_field_of_view_dead_zone_color"],
                ["Filled"] = false,
                ["Transparency"] = 0,
                ["Thickness"] = 2,
                ["ZIndex"] = 11,
                ["Visible"] = true
            })
            if flags["aim_assist"] then
                tween(fov_circle, {["Transparency"] = -flags["aim_assist_field_of_view_transparency"]+1}, circular, out, 0.15)
                tween(fov_circle_outline, {['Transparency'] = -flags["aim_assist_field_of_view_outline_transparency"]+1}, circular, out, 0.15)
                tween(fov_circle_dead_zone, {['Transparency'] = -flags["aim_assist_field_of_view_dead_zone_transparency"]+1}, circular, out, 0.15)
            end
        end
    end

    create_connection(menu_references["aim_assist_field_of_view_show_fov"]["on_color_change"], function(value)
        if fov_circle then
            fov_circle["Color"] = value
        end
    end

    create_connection(menu_references["aim_assist_field_of_view_show_fov"]["on_transparency_change"], function(value)
        local transparency = 1-value
        if fov_circle and flags["aim_assist"] then
            tween(fov_circle, {["Transparency"] = transparency}, circular, out, 0)
        end
    end

    create_connection(menu_references["aim_assist_field_of_view_outline"]["on_color_change"], function(value)
        if fov_circle_outline then
            fov_circle_outline["Color"] = value
        end
    end

    create_connection(menu_references["aim_assist_field_of_view_outline"]["on_transparency_change"], function(value)
        local transparency = 1-value

        if fov_circle_outline and flags["aim_assist"] then
            tween(fov_circle_outline, {['Transparency'] = transparency}, circular, out, 0.15)
        end
    end

    create_connection(menu_references["aim_assist_field_of_view_dead_zone"]["on_color_change"], function(value)
        if fov_circle_dead_zone then
            fov_circle_dead_zone["Color"] = value
        end
    end

    create_connection(menu_references["aim_assist_field_of_view_dead_zone"]["on_transparency_change"], function(value)
        local transparency = 1-value
        if fov_circle_dead_zone and flags["aim_assist"] then
            tween(fov_circle_dead_zone, {['Transparency'] = transparency}, circular, out, 0.15)
        end
    end

    create_connection(menu_references["aim_assist_field_of_view"]["on_slider_change"], update_aim_assist_field_of_view)
    create_connection(menu_references["aim_assist_dead_zone"]["on_slider_change"], update_aim_assist_field_of_view)

    create_connection(menu_references["aim_assist_smoothing"]["on_toggle_change"], function(value)
        aim_assist_vertical_smoothing = value and flags["aim_assist_vertical_smoothing_amount"]/5 or 0
        aim_assist_horizontal_smoothing = value and flags["aim_assist_horizontal_smoothing_amount"]/5 or 0
    end

    create_connection(menu_references["aim_assist_multipoint"]["on_slider_change"], function(value)
        aim_assist_multipoint = value/200
    end

    create_connection(menu_references["aim_assist_vertical_smoothing_amount"]["on_slider_change"], function(value)
        if flags["aim_assist_smoothing"] then
            aim_assist_vertical_smoothing = value/5
        end
    end

    create_connection(menu_references["aim_assist_horizontal_smoothing_amount"]["on_slider_change"], function(value)
        if flags["aim_assist_smoothing"] then
            aim_assist_horizontal_smoothing = value/5
        end
    end

    create_connection(menu_references["aim_assist_smoothing_type"]["on_dropdown_change"], function(value)
        local value = value[1]
        aim_assist_smoothing_type = value == "exponential" and Enum["EasingStyle"]["Exponential"] or value == "circular" and Enum["EasingStyle"]["Circular"] or value == "quad" and Enum["EasingStyle"]["Quad"] or value == "sine" and Enum["EasingStyle"]["Sine"] or value == "quart" and Enum["EasingStyle"]["Quart"] or value == "back" and Enum["EasingStyle"]["Back"] or value
    end

    create_connection(menu_references["aim_assist_dont_aim_if"]["on_dropdown_change"], function(value)
        aim_assist_dont_aim_if_no_gun_equipped = false
        aim_assist_dont_aim_if_reloading = false

        for i = 1, #value do
            local value = value[i]
            if value == "no gun equipped" then
                aim_assist_dont_aim_if_no_gun_equipped = true
            elseif value == "reloading" then
                aim_assist_dont_aim_if_reloading = true
            end
        end
    end

    set_aim_assist_position = function(position)
        local type = typeof(position)

        if type ~= "Vector3" then
            error("juju: set_aim_assist_position arg #1 expected Vector3 got "..type)
            return
        end

        custom_aim_assist_position = position
        spawn(function()
            if custom_aim_assist_position == position then
                custom_aim_assist_position = nil
            end
        end
    end

    -- >> ( silent aim )

    local viewport_point_to_ray = camera["ViewportPointToRay"]

    local fov_circle = nil
    local fov_circle_outline = nil

    local silent_aim_max_distance = 0
    local silent_aim_field_of_view = (camera["ViewportSize"]["Magnitude"]/(pi/2))*(flags["silent_aim_field_of_view"]/180)
    local silent_aim_multipoint = 0.15
    local silent_aim_hitbox = "Head"
    local silent_aim_max_curve = nil
    local silent_aim_dont_curve_vertically = false

    local do_silent_aim = function(dt, hrp)
        local mouse_position = get_mouse_location(user_input_service)

        if fov_circle then
            local old_position = fov_circle["Position"]
            local new_position = old_position + (mouse_position - old_position) * dt*4^2

            fov_circle["Position"] = new_position
            fov_circle_outline["Position"] = new_position
        end

        if dt ~= last_target_dt and flags["silent_aim"] then
            get_legitbot_target(dt)
        end

        if legitbot_target and legitbot_target[3] < silent_aim_field_of_view and not legitbot_dont_aim then
            local data = legitbot_target[1]
            local part = data[4][silent_aim_hitbox == "closest" and get_closest_part(data) or silent_aim_hitbox]

            if part and not data[18] and not data[7] then
                local part_position = custom_silent_aim_position or part["Position"]

                if local_gun and (silent_aim_max_distance == 2500 or (hrp["Position"]-part_position)["Magnitude"] <= (silent_aim_max_distance == 0 and (local_gun or 250) or silent_aim_max_distance)) then
                    if silent_aim_multipoint ~= 0 and not custom_silent_aim_position then
                        local part_cframe = part["CFrame"]
                        local cf = part_cframe:PointToObjectSpace(mouse["Hit"]["p"])
                        local size = part["Size"]*silent_aim_multipoint

                        part_cframe*=vector3_new(clamp(cf.X, -size.X, size.X),clamp(cf.Y, -size.Y, size.Y),clamp(cf.Z, -size.Z, size.Z))
                        part_position = vector3_new(part_cframe.X, part_cframe.Y, part_cframe.Z)
                    end

                    silent_aim_position = part_position
                    custom_silent_aim_position = nil

                    if silent_aim_max_curve or silent_aim_dont_curve_vertically then
                        local pos = world_to_viewport_point(camera, silent_aim_position)
                        local world_position = mouse_position+((vector2_new(pos.X, pos.Y)-mouse_position)*(silent_aim_max_curve or 1))
                        local ray = viewport_point_to_ray(camera, world_position.X, silent_aim_dont_curve_vertically and mouse_position["Y"] or world_position["Y"])
                        silent_aim_position = ray["Origin"] + ray["Direction"] * (ray["Origin"]-part_position)["magnitude"]
                    end

                    return
                end
            end
        end

        silent_aim_position = nil
        custom_silent_aim_position = nil
    end

    local update_silent_aim_field_of_view = function()
        local value = flags["silent_aim_field_of_view"]
        silent_aim_field_of_view = (camera["ViewportSize"]["Magnitude"]/(pi/2))*(value/180)

        if fov_circle_outline then
            fov_circle_outline["Radius"] = silent_aim_field_of_view
        end

        if fov_circle then
            fov_circle["Radius"] = silent_aim_field_of_view
        end
    end

    local silent_aim_camera_connection = nil

    create_connection(menu_references["silent_aim_max_curve"]["on_slider_change"], function(value)
        silent_aim_max_curve = value ~= 100 and value/100 or nil
    end

    create_connection(menu_references["silent_aim_dont_curve_vertically"]["on_toggle_change"], function(value)
        silent_aim_dont_curve_vertically = value
    end

    create_connection(menu_references["silent_aim"]["on_toggle_change"], function(value)
        last_target_dt = nil
        silent_aim_position = nil

        if not value and not flags["triggerbot"] and not flags["aim_assist"] then
            delay(0.01, function()
                set_legitbot_target(nil)
                last_target_dt = nil
                silent_aim_position = nil
            end
        end

        if not value then
            delay(0.15, function()
                for i = 1, #heartbeat do
                    if heartbeat[i] == do_silent_aim then
                        remove(heartbeat, i)
                        break
                    end
                end
            end
        else
            for i = 1, #heartbeat do
                if heartbeat[i] == do_silent_aim then
                    remove(heartbeat, i)
                    break
                end
            end
        end

        if silent_aim_camera_connection then
            silent_aim_camera_connection:Disconnect()
            silent_aim_camera_connection = nil
        end

        if value then
            update_silent_aim_field_of_view()
            if fov_circle then
                tween(fov_circle, {["Transparency"] = -flags["silent_aim_field_of_view_transparency"]+1}, circular, out, 0.15)
                tween(fov_circle_outline, {['Transparency'] = -flags["silent_aim_field_of_view_outline_transparency"]+1}, circular, out, 0.15)
            end
            heartbeat[#heartbeat+1] = do_silent_aim
            silent_aim_camera_connection = create_connection(camera:GetPropertyChangedSignal("ViewportSize"), update_silent_aim_field_of_view)
        else
            if fov_circle then
                tween(fov_circle, hide_transparency, circular, out, 0.15)
                tween(fov_circle_outline, hide_transparency, circular, out, 0.15)
            end
        end
    end

    create_connection(menu_references["silent_aim_hitbox"]["on_dropdown_change"], function(value)
        local value = value[1]
        silent_aim_hitbox = value == "head" and "Head" or value == "root" and "HumanoidRootPart" or "closest"
    end

    create_connection(menu_references["silent_aim_field_of_view_show_fov"]["on_toggle_change"], function(value)
        if fov_circle then
            fov_circle:Destroy()
            fov_circle = nil
        end

        if fov_circle_outline then
            fov_circle_outline:Destroy()
            fov_circle_outline = nil
        end

        if value then
            fov_circle = create_real_drawing("Circle", {
                ["Radius"] = silent_aim_field_of_view,
                ["Color"] = flags["silent_aim_field_of_view_color"],
                ["Filled"] = true,
                ["Transparency"] = 0,
                ["Thickness"] = 1,
                ["ZIndex"] = 11,
                ["Visible"] = true
            })
            fov_circle_outline = create_real_drawing("Circle", {
                ["Radius"] = silent_aim_field_of_view,
                ["Color"] = flags["silent_aim_field_of_view_outline_color"],
                ["Filled"] = false,
                ["Transparency"] = 0,
                ["Thickness"] = 2,
                ["ZIndex"] = 10,
                ["Visible"] = true
            })
            if flags["silent_aim"] then
                tween(fov_circle, {["Transparency"] = -flags["silent_aim_field_of_view_transparency"]+1}, circular, out, 0.15)
                tween(fov_circle_outline, {['Transparency'] = -flags["silent_aim_field_of_view_outline_transparency"]+1}, circular, out, 0.15)
            end
        end
    end

    create_connection(menu_references["silent_aim_field_of_view_show_fov"]["on_color_change"], function(value)
        if fov_circle then
            fov_circle["Color"] = value
        end
    end

    create_connection(menu_references["silent_aim_field_of_view_show_fov"]["on_transparency_change"], function(value)
        if fov_circle and flags["silent_aim"] then
            tween(fov_circle, {["Transparency"] = 1-value}, circular, out, 0)
        end
    end

    create_connection(menu_references["silent_aim_field_of_view_outline"]["on_color_change"], function(value)
        if fov_circle_outline then
            fov_circle_outline["Color"] = value
        end
    end

    create_connection(menu_references["silent_aim_field_of_view_outline"]["on_transparency_change"], function(value)
        if fov_circle_outline and flags["silent_aim"] then
            tween(fov_circle_outline, {["Transparency"] = 1-value}, circular, out, 0)
        end
    end

    create_connection(menu_references["silent_aim_field_of_view"]["on_slider_change"], update_silent_aim_field_of_view)

    create_connection(menu_references["silent_aim_multipoint"]["on_slider_change"], function(value)
        silent_aim_multipoint = value/200
    end

    create_connection(menu_references["silent_aim_redirect_chance"]["on_slider_change"], function(value)
        silent_aim_redirect_chance = 100 - value
    end

    create_connection(menu_references["silent_aim_max_distance"]["on_slider_change"], function(value)
        silent_aim_max_distance = value
    end

    -- >> ( triggerbot )

    do
        local viewport_point_to_ray = camera["ViewportPointToRay"]

        local triggerbot_do_head = true
        local triggerbot_do_torso = true
        local triggerbot_do_arms = false
        local triggerbot_do_legs = false
        local triggerbot_cooldown = 0
        local triggerbot_hover_time = 0
        local triggerbot_delay = 0
        local last_triggerbot_part = nil
        local triggerbot_max_distance = 0

        local triggerbot_hover_tick = clock()
        local triggerbot_angular_fov_enabled = false
        local triggerbot_angular_fov_degrees = 30
        local triggerbot_angular_fov_visualize = false
        local triggerbot_angular_fov_x = 2
        local triggerbot_angular_fov_y = 5
        local triggerbot_angular_fov_z = 2
        local triggerbot_fov_circle = nil
        local triggerbot_fov_circle_outline = nil

        local function update_triggerbot_fov_circle()
            local radius = (camera["ViewportSize"]["Magnitude"] / (math["pi"] / 2)) * (triggerbot_angular_fov_degrees / 360)
            if triggerbot_fov_circle then
                triggerbot_fov_circle["Radius"] = radius
            end
            if triggerbot_fov_circle_outline then
                triggerbot_fov_circle_outline["Radius"] = radius
            end
        end
        local triggerbot_tick = clock()
        local triggerbot_refresh_rate = 0
        local triggerbot_scan_tick = 0
        local triggerbot_cached_ignore = nil
        local triggerbot_cached_parts = nil

        local do_triggerbot = function(dt, hrp)
            local mouse_position = get_mouse_location(user_input_service)

            if triggerbot_fov_circle then
                triggerbot_fov_circle["Position"] = mouse_position
                triggerbot_fov_circle_outline["Position"] = mouse_position
            end

            -- refresh rate throttle: skip raycast if not enough time has passed
            local now = clock()
            if triggerbot_refresh_rate > 0 and now - triggerbot_scan_tick < triggerbot_refresh_rate then
                return
            end
            triggerbot_scan_tick = now

            if dt ~= last_target_dt then
                get_legitbot_target(dt)
            end

            if legitbot_target and not legitbot_dont_aim and local_gun then
                local ray = viewport_point_to_ray(camera, mouse_position["X"], mouse_position["Y"])
                local data = legitbot_target[1]
                local parts = data[4]
                local target_hrp = parts["HumanoidRootPart"]
                if not data[7] and not data[18] and not parts["ForceField"] and not parts["FORCEFIELD"] and target_hrp then
                    local max = (triggerbot_max_distance == 0 and (local_gun or 250) or triggerbot_max_distance)
                    if triggerbot_max_distance == 2500 or (hrp["Position"]-target_hrp["Position"])["Magnitude"] <= max then
                        local tb_hrp_original_size = nil
                        if triggerbot_angular_fov_enabled then
                            -- angle check only, no slab test (raycast handles wall blocking)
                            local cam_cf = camera["CFrame"]
                            local to_target = (target_hrp["Position"] - cam_cf["Position"])["Unit"]
                            local angle = math["deg"](math["acos"](math["clamp"](cam_cf["LookVector"]:Dot(to_target), -1, 1)))
                            if angle > triggerbot_angular_fov_degrees / 2 then
                                last_triggerbot_part = nil
                                return
                            end
                            -- angle passed: temporarily resize HRP so raycast hits expanded box
                            tb_hrp_original_size = target_hrp["Size"]
                            target_hrp["Size"] = vector3_new(triggerbot_angular_fov_x, triggerbot_angular_fov_y, triggerbot_angular_fov_z)
                            target_hrp["CanCollide"] = false
                            target_hrp["Transparency"] = triggerbot_angular_fov_visualize and 0.7 or 1
                            if triggerbot_angular_fov_visualize then
                                target_hrp["BrickColor"] = BrickColor["new"]("Cyan")
                                target_hrp["Material"] = Enum["Material"]["Neon"]
                            end
                        end
                        local ignore = {local_character, ignored, bush, vehicles, data[13], cached_backtrack_models}

                        for name, part in parts do
                            if part["ClassName"] == "Accessory" then
                                ignore[#ignore+1] = part
                            elseif part:IsA("BasePart") and part["Transparency"] == 1 and part ~= target_hrp then
                                ignore[#ignore+1] = part
                            end
                        end

                        params["FilterDescendantsInstances"] = ignore

                        local result = raycast(workspace, ray["Origin"], ray["Direction"] * (max), params)
                        -- reset HRP size immediately after raycast, restore full transparency
                        if tb_hrp_original_size then
                            target_hrp["Size"] = tb_hrp_original_size
                            target_hrp["Transparency"] = 1
                            target_hrp["CanCollide"] = false
                        end

                        if result then
                            local instance = result["Instance"]

                            if instance then
                                local name = instance["Name"]

                                if parts[name] == instance then
                                    local do_triggerbot = false

                                    if triggerbot_do_head and name == "Head" then
                                        do_triggerbot = instance
                                    elseif triggerbot_do_torso and (name == "UpperTorso" or name == "LowerTorso" or name == "HumanoidRootPart") then
                                        do_triggerbot = instance
                                    elseif triggerbot_do_arms and (name == "LeftUpperArm" or name == "RightUpperArm" or name == "LeftLowerArm" or name == "RightLowerArm" or name == "LeftHand" or name == "RightHand") then
                                        do_triggerbot = instance
                                    elseif triggerbot_do_legs and (name == "LeftUpperLeg" or name == "RightUpperLeg" or name == "LeftLowerLeg" or name == "RightLowerLeg" or name == "LeftFoot" or name == "RightFoot") then
                                        do_triggerbot = instance
                                    end

                                    if do_triggerbot then
                                        local tick = clock()

                                        if tick-triggerbot_tick > triggerbot_cooldown or triggerbot_cooldown == 0 then
                                            triggerbot_tick = tick

                                            if last_triggerbot_part ~= instance then
                                                triggerbot_hover_tick = tick
                                            end

                                            if tick - triggerbot_hover_tick > triggerbot_hover_time or triggerbot_hover_time == 0 then
                                                if triggerbot_delay > 0 then
                                                    delay(triggerbot_delay, function()
                                                        mouse1press()
                                                        wait()
                                                        mouse1release()
                                                    end
                                                else
                                                    mouse1press()
                                                    wait()
                                                    mouse1release()
                                                end
                                            end
                                        end
                                    end

                                    last_triggerbot_part = instance

                                    return
                                end
                            end
                        end
                    end
                end
            end

            last_triggerbot_part = nil
        end

        create_connection(menu_references["triggerbot"]["on_toggle_change"], function(value)
            last_target_dt = nil

            if not value and not flags["silent_aim"] and not flags["aim_assist"] then
                delay(0.01, function()
                    set_legitbot_target(nil)
                    last_target_dt = nil
                    silent_aim_position = nil
                end
            end

            for i = 1, #heartbeat do
                if heartbeat[i] == do_triggerbot then
                    remove(heartbeat, i)
                    break
                end
            end

            if value then
                heartbeat[#heartbeat+1] = do_triggerbot
            end
        end

        create_connection(menu_references["triggerbot_hitboxes"]["on_dropdown_change"], function(value)
            triggerbot_do_legs = false
            triggerbot_do_torso = false
            triggerbot_do_arms = false
            triggerbot_do_head = false

            for i = 1, #value do
                local value = value[i]

                if value == "head" then
                    triggerbot_do_head = true
                elseif value == "torso" then
                    triggerbot_do_torso = true
                elseif value == "arms" then
                    triggerbot_do_arms = true
                elseif value == "legs" then
                    triggerbot_do_legs = true
                end
            end
        end

        create_connection(menu_references["triggerbot_cooldown"]["on_slider_change"], function(value)
            triggerbot_cooldown = value
        end
        create_connection(menu_references["triggerbot_refresh_rate"]["on_slider_change"], function(value)
            triggerbot_refresh_rate = value
        end

        create_connection(menu_references["triggerbot_max_distance"]["on_slider_change"], function(value)
            triggerbot_max_distance = value
        end

        create_connection(menu_references["triggerbot_delay"]["on_slider_change"], function(value)
            triggerbot_delay = value
        end

        create_connection(menu_references["triggerbot_hover_time"]["on_slider_change"], function(value)
            triggerbot_hover_time = value
        end

        create_connection(menu_references["triggerbot_angular_fov"]["on_toggle_change"], function(value)
            triggerbot_angular_fov_enabled = value
        end

        create_connection(menu_references["triggerbot_angular_fov_value"]["on_slider_change"], function(value)
            triggerbot_angular_fov_degrees = value
            update_triggerbot_fov_circle()
        end

        create_connection(menu_references["triggerbot_angular_fov_visualize"]["on_toggle_change"], function(value)
            triggerbot_angular_fov_visualize = value
            if value then
                if not triggerbot_fov_circle then
                    local mouse_pos = get_mouse_location(user_input_service)
                    triggerbot_fov_circle = create_real_drawing("Circle", {
                        ["Radius"] = 0,
                        ["Color"] = color3_fromrgb(181, 255, 246),
                        ["Filled"] = true,
                        ["Transparency"] = 0.05,
                        ["Thickness"] = 1,
                        ["ZIndex"] = 11,
                        ["Position"] = mouse_pos,
                        ["Visible"] = true
                    })
                    triggerbot_fov_circle_outline = create_real_drawing("Circle", {
                        ["Radius"] = 0,
                        ["Color"] = color3_fromrgb(181, 255, 246),
                        ["Filled"] = false,
                        ["Transparency"] = 0.3,
                        ["Thickness"] = 1,
                        ["ZIndex"] = 10,
                        ["Position"] = mouse_pos,
                        ["Visible"] = true
                    })
                    update_triggerbot_fov_circle()
                end
            else
                if triggerbot_fov_circle then
                    triggerbot_fov_circle:Destroy()
                    triggerbot_fov_circle = nil
                end
                if triggerbot_fov_circle_outline then
                    triggerbot_fov_circle_outline:Destroy()
                    triggerbot_fov_circle_outline = nil
                end
            end
        end

        create_connection(menu_references["triggerbot_angular_fov_x"]["on_slider_change"], function(value)
            triggerbot_angular_fov_x = value
        end

        create_connection(menu_references["triggerbot_angular_fov_y"]["on_slider_change"], function(value)
            triggerbot_angular_fov_y = value
        end

        create_connection(menu_references["triggerbot_angular_fov_z"]["on_slider_change"], function(value)
            triggerbot_angular_fov_z = value
        end
    end

    -- >> ( reduce shotgun spread )

    do
        local func_cache = {}
        local connection = nil
        local connection2 = nil
        local reduce_amount = 0.65

        local on_tool_added = function(tool)
            if not tool then
                return
            end

            local connection = getconnections(tool["Activated"])[1]

            if not connection then
                return
            end

            local old = connection["Function"]

            if not old or isourclosure(getfenv(old)["math"]["random"]) or not getinfo(old)["source"]:find("GunClientShotgun") then
                return
            end

            getfenv(old)["math"] = {
                ["random"] = newcclosure(function()
                    return math_random()*reduce_amount
                end
            }

            func_cache[#func_cache+1] = old
        end

        local reset = function()
            func_cache = {}
        end

        create_connection(menu_references["reduce_shotgun_spread"]["on_toggle_change"], function(value)
            for i = 1, #func_cache do
                getfenv(func_cache[i])["math"] = nil
                func_cache[i] = nil
            end

            if connection then
                connection:Disconnect()
                connection = nil
            end

            if connection2 then
                connection2:Disconnect()
                connection2 = nil
            end

            if value then
                for handle, data in local_guns do
                    local tool = handle["Parent"]

                    if tool then
                        on_tool_added(tool)
                    end
                end

                connection = create_connection(signals["on_local_tool_equipped"], on_tool_added)
                connection2 = create_connection(signals["on_local_character_added"], reset)
            end
        end

        create_connection(menu_references["reduce_shotgun_spread_amount"]["on_slider_change"], function(value)
            reduce_amount = (101-value)/100
        end
    end 

    -- >> ( backtrack )

    do
        local backtrack_material = Enum["Material"]["Neon"]
        local backtrack_color = flags["backtrack_color"]
        local backtrack_transparency = flags["backtrack_transparency"]
        backtrack_data = {}

        getgenv()["juju"]["get_backtrack_position"] = function(player)
            local type = typeof(player)

            if type ~= "Instance" then
                error("juju: get_backtrack_position arg #1 expected Instance got "..type)
                return
            end

            if player["ClassName"] ~= "Player" then
                error("juju: get_backtrack_position arg #1 expected Player got "..player["ClassName"])
                return
            end

            return backtrack_data[player] and backtrack_data[player][3] or nil
        end

        get_backtrack_models = function()
            local models = {}

            for player, data in backtrack_data do
                local model = data[1]
                if model then
                    models[#models+1] = model
                end
            end
            return models
        end

        local do_friendly = false
        local do_neutral = true
        local do_target = false
        local do_enemy = false

        local connection = nil
        local connection2 = nil
        local connection3 = nil
        local connection4 = nil
        local connection5 = nil

        local create_backtrack_model = function(player, character)
            local data = backtrack_data[player]

            if not data or data[1] then
                return
            end

            character["Archivable"] = true
            local new_model = clone(character)
            character["Archivable"] = false
            new_model["SetAttribute"](new_model, "1", "1")
            local children = get_children(new_model)

            local model_parts = {}

            for i = 1, #children do
                local part = children[i]
                local class_name = part["ClassName"]
                if class_name == "MeshPart" then
                    part["Material"] = backtrack_material
                    part["Color"] = backtrack_color
                    part["Transparency"] = backtrack_transparency
                    part["TextureID"] = ""
                    part["CanCollide"] = false
                    part["Anchored"] = true

                    local name = part["Name"]

                    if name == "Head" then
                        local face = find_first_child_of_class(part, "Decal")

                        if face then
                            destroy(face)
                        end
                    end

                    model_parts[name] = part
                else
                    destroy(part)
                end
            end
            data[1] = new_model
            data[2] = model_parts
            new_model["Parent"] = workspace["Players"]
        end

        local refresh_backtrack_data = function(player, character)
            local data = backtrack_data[player]

            if not data then
                return
            end

            local model = data[1]

            if model then
                destroy(model)
            end

            data[2] = {}
            data[3] = nil
            wait(0.5)

            if not character then
                return 
            end

            create_backtrack_model(player, character)
        end

        local hide_cframe = cframe_new(0,9e9,9e9)
        local last_reset_tick = clock()
        local last_backtrack_tick = clock()

        local do_backtrack = function(player, character)
            if clock() - last_backtrack_tick > 0.02 then
                last_backtrack_tick = clock()
                for player, bt_data in backtrack_data do
                    local data = player_data[player]

                    if not data then
                        local model = bt_data[1]
                        if model then
                            destroy(model)
                        end
                        backtrack_data[player] = nil
                        continue
                    end

                    local parts = bt_data[2]
                    local cframes = bt_data[3]
                    local player_parts = data[4]

                    local old_cframes = {}

                    for name, part in parts do
                        local player_part = player_parts[name]

                        if not player_part then
                            destroy(part)
                            parts[name] = nil
                            continue
                        end

                        old_cframes[part] = player_part["CFrame"]
                    end

                    local old_tick = bt_data[4]

                    delay(flags["backtrack_length"], function() 
                        if old_tick == bt_data[4] then
                            if not bt_data[3] then
                                bt_data[3] = {}
                            end
                            cframes = bt_data[3]
                            for name, part in parts do
                                cframes[part] = old_cframes[part]
                            end
                        end
                    end

                    if cframes then
                        for part, cframe in cframes do
                            local part_name = part["Name"]
                            local player_part = player_parts[part_name]

                            if not player_part then
                                local part = parts[part_name]
                                if part then
                                    destroy(part)
                                    parts[part_name] = nil
                                    cframes[part_name] = nil
                                end
                                continue
                            end

                            part["CFrame"] = cframe
                        end
                    else
                        for name, part in parts do
                            part["CFrame"] = hide_cframe
                        end
                    end
                end
            end
        end

        local create_backtrack_data = function()
            for player, data in player_data do
                local status = data[1]

                if status == 2 and do_friendly or status == 1 and do_neutral or status == 3 and do_enemy or (((legitbot_target and legitbot_target[1] == data) or (ragebot_target == data)) and do_target) then
                    if backtrack_data[player] then
                        return
                    end

                    local character = data[3]
                    
                    backtrack_data[player] = {
                        nil,
                        {},
                        nil,
                        clock()
                    }

                    if character then
                        create_backtrack_model(player, character)
                    end
                else
                    local bt_data = backtrack_data[player]

                    if bt_data then
                        local model = bt_data[1]

                        if model then
                            destroy(model)
                        end

                        backtrack_data[player] = nil
                    end
                end
            end
        end

        local reset_backtrack_data = function()
            for player, bt_data in backtrack_data do
                local model = bt_data[1]

                if model then
                    destroy(model)
                end
            end

            backtrack_data = {}
        end

        local on_backtrack_hit = function(player)            
            local bt_data = backtrack_data[player]

            if not bt_data then
                return 
            end

            bt_data[3] = nil
            bt_data[5] = clock()
        end

        create_connection(menu_references["backtrack"]["on_toggle_change"], function(value)
            for i = 1, #heartbeat do
                if heartbeat[i] == do_backtrack then
                    remove(heartbeat, i)
                    break
                end
            end

            reset_backtrack_data()

            if connection then
                connection["Disconnect"](connection)
                connection = nil
            end

            if connection2 then
                connection2["Disconnect"](connection2)
                connection2 = nil
            end

            if connection3 then
                connection3["Disconnect"](connection3)
                connection3 = nil
            end

            if connection4 then
                connection4["Disconnect"](connection4)
                connection4 = nil
            end

            if connection5 then
                connection5["Disconnect"](connection5)
                connection5 = nil
            end

            if value then
                create_backtrack_data()
                heartbeat[#heartbeat+1] = do_backtrack

                if flags["backtrack_reset_on_hit"] then
                    connection2 = create_connection(signals["on_local_bullet_confirmed"], on_backtrack_hit)
                end

                if do_target then
                    connection3 = create_connection(signals["on_legitbot_target_changed"], create_backtrack_data)
                end
                connection4 = create_connection(signals["on_player_status_changed"], create_backtrack_data)
                connection5 = create_connection(signals["on_player_added"], create_backtrack_data)
                connection = create_connection(signals["on_player_character_added"], refresh_backtrack_data)
            end
        end

        create_connection(menu_references["backtrack_reset_on_hit"]["on_toggle_change"], function(value)
            if connection2 then
                connection2["Disconnect"](connection2)
                connection2 = nil
            end

            if value and flags["backtrack_reset_on_hit"] then
                connection2 = create_connection(signals["on_local_bullet_confirmed"], on_backtrack_hit)
            end
        end

        create_connection(menu_references["backtrack_color"]["on_color_change"], function(color)
            backtrack_color = color

            for player, data in backtrack_data do
                for name, part in data[2] do
                    part["Color"] = color
                end
            end
        end

        create_connection(menu_references["backtrack_color"]["on_transparency_change"], function(transparency)
            backtrack_transparency = transparency

            for player, data in backtrack_data do
                for name, part in data[2] do
                    part["Transparency"] = transparency
                end
            end
        end

        create_connection(menu_references["backtrack_material"]["on_dropdown_change"], function(value)
            backtrack_material = value[1] == "neon" and Enum["Material"]["Neon"] or Enum["Material"]["ForceField"]
            for player, data in backtrack_data do
                for name, part in data[2] do
                    part["Material"] = backtrack_material
                end
            end
        end

        create_connection(menu_references["backtrack_target_statuses"]["on_dropdown_change"], function(value)
            do_target = false
            do_enemy = false
            do_neutral = false
            do_friendly = false

            for i = 1, #value do
                local status = value[i]
                if status == "friendly" then
                    do_friendly = true
                elseif status == "neutral" then
                    do_neutral = true
                elseif status == "target" then
                    do_target = true
                elseif status == "enemy" then
                    do_enemy = true
                end
            end

            if connection3 then
                connection3["Disconnect"](connection3)
                connection3 = nil
            end

            if connection then
                if do_target then
                    connection3 = create_connection(signals["on_legitbot_target_changed"], create_backtrack_data)
                end
                reset_backtrack_data()
                create_backtrack_data()
            end
        end
    end
end

-- > ( hitbox expander )

do
    local hitbox_expander_enabled = false
    local hitbox_expander_size_x = 2
    local hitbox_expander_size_y = 5
    local hitbox_expander_size_z = 2
    local hitbox_expander_visualize = false
    local hitbox_expander_team_check = false

    local function restore_hitboxes()
        for _, player in pairs(players_service:GetPlayers()) do
            if player ~= local_player and player["Character"] then
                local hrp = player["Character"]:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp["Size"] = Vector3["new"](2, 2, 1)
                    hrp["Transparency"] = 1
                    hrp["Material"] = Enum["Material"]["SmoothPlastic"]
                    hrp["CanCollide"] = false
                end
            end
        end
    end

    local do_hitbox_expander = function()
        for _, player in pairs(players_service:GetPlayers()) do
            if player ~= local_player and player["Character"] then
                if hitbox_expander_team_check and player["Team"] == local_player["Team"] then
                    continue
                end
                local hrp = player["Character"]:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp["Size"] = Vector3["new"](hitbox_expander_size_x, hitbox_expander_size_y, hitbox_expander_size_z)
                    if hitbox_expander_visualize then
                        hrp["Transparency"] = 0.7
                        hrp["BrickColor"] = BrickColor["new"]("Really blue")
                        hrp["Material"] = Enum["Material"]["Neon"]
                        hrp["CanCollide"] = false
                    else
                        hrp["Transparency"] = 1
                        hrp["CanCollide"] = false
                    end
                end
            end
        end
    end

    create_connection(menu_references["hitbox_expander"]["on_toggle_change"], function(value)
        hitbox_expander_enabled = value
        if not value then
            restore_hitboxes()
            for i = 1, #heartbeat do
                if heartbeat[i] == do_hitbox_expander then
                    remove(heartbeat, i)
                    break
                end
            end
        else
            heartbeat[#heartbeat + 1] = do_hitbox_expander
        end
    end

    create_connection(menu_references["hitbox_expander_size_x"]["on_slider_change"], function(value)
        hitbox_expander_size_x = value
    end

    create_connection(menu_references["hitbox_expander_size_y"]["on_slider_change"], function(value)
        hitbox_expander_size_y = value
    end

    create_connection(menu_references["hitbox_expander_size_z"]["on_slider_change"], function(value)
        hitbox_expander_size_z = value
    end

    create_connection(menu_references["hitbox_expander_visualize"]["on_toggle_change"], function(value)
        hitbox_expander_visualize = value
    end

    create_connection(menu_references["hitbox_expander_team_check"]["on_toggle_change"], function(value)
        hitbox_expander_team_check = value
    end
    local do_magnetic_aim = function(dt, local_hrp)
        if not magnetic_aim_enabled then return end
        if magnetic_aim_only_when_ads and local_gun == nil then return end
        if not local_hrp then return end

        local mouse_position = get_mouse_location(user_input_service)
        local fov_px = (camera["ViewportSize"]["Magnitude"]/(pi/2))*(magnetic_aim_fov_degrees/180)
        local best_target = nil
        local best_dist = fov_px

        for player, data in player_data do
            if not data[7] and not data[18] then
                local status = data[1]
                if magnetic_aim_team_check and status ~= 3 then continue end
                if not magnetic_aim_team_check and status == 2 then continue end
                local parts = data[4]
                if parts["FORCEFIELD"] or parts["ForceField"] then continue end
                local part = parts[magnetic_aim_hitbox]
                if part then
                    local pos, on_screen = world_to_viewport_point(camera, part["Position"])
                    if on_screen then
                        local dist = (vector2_new(pos["X"], pos["Y"]) - mouse_position)["Magnitude"]
                        if dist < best_dist then
                            best_dist = dist
                            best_target = pos
                        end
                    end
                end
            end
        end

        if best_target then
            local dx = best_target["X"] - mouse_position["X"]
            local dy = best_target["Y"] - mouse_position["Y"]
            local strength = magnetic_aim_strength / 100
            mousemoverel(dx * strength * 0.3, dy * strength * 0.3)
        end
    end

    create_connection(menu_references["magnetic_aim"]["on_toggle_change"], function(value)
        magnetic_aim_enabled = value
        if value then
            heartbeat[#heartbeat+1] = do_magnetic_aim
        else
            for i = 1, #heartbeat do
                if heartbeat[i] == do_magnetic_aim then
                    remove(heartbeat, i)
                    break
                end
            end
        end
    end
    create_connection(menu_references["magnetic_aim_fov"]["on_slider_change"], function(value)
        magnetic_aim_fov_degrees = value
    end
    create_connection(menu_references["magnetic_aim_strength"]["on_slider_change"], function(value)
        magnetic_aim_strength = value
    end
    create_connection(menu_references["magnetic_aim_hitbox"]["on_dropdown_change"], function(value)
        local v = value[1]
        magnetic_aim_hitbox = v == "head" and "Head" or v == "root" and "HumanoidRootPart" or "Head"
    end
    create_connection(menu_references["magnetic_aim_only_when_ads"]["on_toggle_change"], function(value)
        magnetic_aim_only_when_ads = value
    end
    create_connection(menu_references["magnetic_aim_team_check"]["on_toggle_change"], function(value)
        magnetic_aim_team_check = value
    end
end

-- > ( finalization )

do
    local data_ping = game:GetService("Stats")["Network"]["ServerStatsItem"]["Data Ping"]
    local last_ping_check = clock()
    local ping_data = {}

    local update_server_position = function(hrp)
        local_server_position = hrp["CFrame"]
    end

    local last_fps = clock()

    create_connection(game:GetService("RunService")["Heartbeat"], function(dt)
        if in_void then
            in_void = nil
        else
            in_void = false
        end

        local_fps = 1/(clock() - last_fps)
        last_fps = clock()

        if clock()-last_ping_check > 2 then
            last_ping_check = clock()

            if #ping_data >= 10 then
                remove(ping_data, 1)
            end

            local new_ping = data_ping:GetValue()
            ping_data[#ping_data+1] = new_ping

            local total = 0
            for _, ping in ping_data do
                total+=ping
            end
            local_ping = 3 + floor(total/#ping_data)
        end

        local hrp = vehicle or local_parts["HumanoidRootPart"]

        for i = 1, #heartbeat do
            spawn(heartbeat[i], dt, hrp)
        end

        if hrp then
            local_client_position = hrp["CFrame"]
        end

        for i = 1, #anti_aim do
            local func = anti_aim[i]
            if func then
                spawn(func, dt, hrp)
            end
        end

        if hrp then
            spawn(update_server_position, hrp)
        end
    end))

    local old_vehicle = nil

    create_connection(signals["on_vehicle_sat_in"], function(new_vehicle)
        if old_vehicle then
            setrawmetatable(old_vehicle, getrawmetatable(game))
        end
        if new_vehicle then
            local old = getrawmetatable(new_vehicle)
            local old_index = old["__index"]
            local old_new_index = old["__newindex"]

            local new = {
                ["__index"] = newcclosure(function(self, index)
                    if not checkcaller() and self then
                        local is_cframe = index == "CFrame" 
                        if is_cframe or index == "Position" and (#anti_aim ~= 0 or purchasing) then
                            return is_cframe and local_client_position or local_client_position["p"]
                        end
                    end
                    return old_index(self, index)
                end)),
                ["__newindex"] = newcclosure(function(self, index, value)
                    if checkcaller() and self and index == "CFrame" and (#anti_aim ~= 0 or purchasing) then
                        return old_new_index(self, index, value)
                    end
                    return old_new_index(self, index, value)
                end))
            }

            for _, v in old do
                if not new[_] then
                    new[_] = v
                end
            end

            setrawmetatable(new_vehicle, new)
        end
        old_vehicle = new_vehicle
    end
end

-- ============================================================
-- LINORIA UI
-- ============================================================

local repo = "https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/"

local library      = loadstring(game:HttpGet(repo .. "Library.lua"))()
local theme_manager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local save_manager  = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

-- > ( tween helper used by logic block for fov circles )
local hide_transparency = {["Transparency"] = 1}

local tween = function(object, properties, style, direction, duration)
    local info = TweenInfo.new(duration, style, direction)
    tween_service:Create(object, info, properties):Play()
end

-- ============================================================
-- WINDOW
-- ============================================================

local window = library:CreateWindow({
    Title   = "juju",
    Center  = true,
    AutoShow = true,
})

-- ============================================================
-- TAB: LEGITBOT
-- ============================================================

local tab_legitbot = window:AddTab("Legitbot")

-- ---- Target Selection ----
local box_target = tab_legitbot:AddLeftGroupbox("Target Selection")

box_target:AddToggle("LegitbotAutomatic", {
    Text    = "Automatic",
    Default = false,
    Callback = function(val)
        flags["legitbot_target_selection_automatic"] = val
        menu_references["legitbot_target_selection_automatic"].on_toggle_change:Fire(val)
    end
})

box_target:AddKeybind("LegitbotTargetBind", {
    Text    = "Target Key",
    Default = "F",
    Callback = function()
        menu_references["legitbot_target_selection_target_bind"].on_key_press:Fire()
    end
})

box_target:AddDropdown("LegitbotIgnoreIf", {
    Text       = "Ignore if",
    Values     = {"knocked", "invulnerable", "not visible"},
    Default    = {"knocked", "invulnerable", "not visible"},
    Multi      = true,
    Callback   = function(val)
        local list = {}
        for k, v in val do if v then list[#list+1] = k end end
        menu_references["legitbot_target_selection_ignore_if"].on_dropdown_change:Fire(list)
    end
})

box_target:AddDropdown("LegitbotUntargetWhen", {
    Text       = "Untarget when",
    Values     = {"knocked", "not visible", "better target", "off screen"},
    Default    = {"knocked", "not visible"},
    Multi      = true,
    Callback   = function(val)
        local list = {}
        for k, v in val do if v then list[#list+1] = k end end
        menu_references["legitbot_target_selection_untarget_when"].on_dropdown_change:Fire(list)
    end
})

box_target:AddSlider("LegitbotMaxDistance", {
    Text    = "Max Distance (0=auto)",
    Min     = 0,
    Max     = 2500,
    Default = 0,
    Rounding = 0,
    Callback = function(val)
        flags["legitbot_max_distance"] = val
        menu_references["legitbot_target_selection_max_target_distance"].on_slider_change:Fire(val)
    end
})

box_target:AddSlider("LegitbotSwitchCooldown", {
    Text    = "Switch Cooldown (s)",
    Min     = 0,
    Max     = 5,
    Default = 0,
    Rounding = 2,
    Callback = function(val)
        menu_references["legitbot_target_selection_target_switch_cooldown"].on_slider_change:Fire(val)
    end
})

box_target:AddSlider("LegitbotFOV", {
    Text    = "FOV (0=off)",
    Min     = 0,
    Max     = 180,
    Default = 180,
    Rounding = 0,
    Callback = function(val)
        menu_references["legitbot_field_of_view"].on_slider_change:Fire(val)
    end
})

box_target:AddToggle("LegitbotNotification", {
    Text    = "Target Notifications",
    Default = false,
    Callback = function(val)
        menu_references["legitbot_target_selection_notification"].on_toggle_change:Fire(val)
    end
})

-- ============================================================
-- TAB: AIM ASSIST
-- ============================================================

local tab_aim = window:AddTab("Aim Assist")

-- ---- Aim Assist ----
local box_aim = tab_aim:AddLeftGroupbox("Aim Assist")

box_aim:AddToggle("AimAssist", {
    Text    = "Enabled",
    Default = false,
    Callback = function(val)
        flags["aim_assist"] = val
        menu_references["aim_assist"].on_toggle_change:Fire(val)
    end
})

box_aim:AddDropdown("AimAssistHitbox", {
    Text     = "Hitbox",
    Values   = {"head", "root", "closest"},
    Default  = {"head"},
    Multi    = false,
    Callback = function(val)
        menu_references["aim_assist_hitbox"].on_dropdown_change:Fire({val})
    end
})

box_aim:AddDropdown("AimAssistMethod", {
    Text     = "Method",
    Values   = {"mouse", "camera"},
    Default  = {"mouse"},
    Multi    = false,
    Callback = function(val)
        menu_references["aim_assist_method"].on_dropdown_change:Fire({val})
    end
})

box_aim:AddSlider("AimAssistFOV", {
    Text    = "FOV (degrees)",
    Min     = 1,
    Max     = 180,
    Default = 30,
    Rounding = 0,
    Callback = function(val)
        flags["aim_assist_field_of_view"] = val
        menu_references["aim_assist_field_of_view"].on_slider_change:Fire(val)
    end
})

box_aim:AddSlider("AimAssistDeadZone", {
    Text    = "Dead Zone (%)",
    Min     = 0,
    Max     = 100,
    Default = 0,
    Rounding = 0,
    Callback = function(val)
        flags["aim_assist_dead_zone"] = val
        menu_references["aim_assist_dead_zone"].on_slider_change:Fire(val)
    end
})

box_aim:AddSlider("AimAssistMultipoint", {
    Text    = "Multipoint",
    Min     = 0,
    Max     = 100,
    Default = 15,
    Rounding = 0,
    Callback = function(val)
        flags["aim_assist_multipoint"] = val
        menu_references["aim_assist_multipoint"].on_slider_change:Fire(val)
    end
})

box_aim:AddSlider("AimAssistMaxDistance", {
    Text    = "Max Distance (0=auto)",
    Min     = 0,
    Max     = 2500,
    Default = 0,
    Rounding = 0,
    Callback = function(val)
        flags["aim_assist_max_distance"] = val
        menu_references["aim_assist_max_distance"].on_slider_change:Fire(val)
    end
})

-- ---- Smoothing ----
local box_smooth = tab_aim:AddLeftGroupbox("Smoothing")

box_smooth:AddToggle("AimAssistSmoothing", {
    Text    = "Enabled",
    Default = false,
    Callback = function(val)
        flags["aim_assist_smoothing"] = val
        menu_references["aim_assist_smoothing"].on_toggle_change:Fire(val)
    end
})

box_smooth:AddDropdown("AimAssistSmoothingType", {
    Text     = "Type",
    Values   = {"random", "constant", "exponential", "circular", "quad", "sine", "quart", "back"},
    Default  = {"random"},
    Multi    = false,
    Callback = function(val)
        menu_references["aim_assist_smoothing_type"].on_dropdown_change:Fire({val})
    end
})

box_smooth:AddSlider("AimAssistHSmooth", {
    Text    = "Horizontal Smoothing",
    Min     = 1,
    Max     = 100,
    Default = 45,
    Rounding = 0,
    Callback = function(val)
        flags["aim_assist_horizontal_smoothing_amount"] = val
        menu_references["aim_assist_horizontal_smoothing_amount"].on_slider_change:Fire(val)
    end
})

box_smooth:AddSlider("AimAssistVSmooth", {
    Text    = "Vertical Smoothing",
    Min     = 1,
    Max     = 100,
    Default = 45,
    Rounding = 0,
    Callback = function(val)
        flags["aim_assist_vertical_smoothing_amount"] = val
        menu_references["aim_assist_vertical_smoothing_amount"].on_slider_change:Fire(val)
    end
})

-- ---- FOV Circle ----
local box_fov = tab_aim:AddRightGroupbox("FOV Visualizer")

box_fov:AddToggle("AimAssistShowFOV", {
    Text    = "Show FOV",
    Default = false,
    Callback = function(val)
        flags["aim_assist_field_of_view_show_fov"] = val
        menu_references["aim_assist_field_of_view_show_fov"].on_toggle_change:Fire(val)
    end
})

box_fov:AddLabel("FOV Fill Color")
box_fov:AddColorPicker("AimFOVColor", {
    Default  = flags["aim_assist_field_of_view_color"],
    Callback = function(val)
        flags["aim_assist_field_of_view_color"] = val
        menu_references["aim_assist_field_of_view_show_fov"].on_color_change:Fire(val)
    end
})

box_fov:AddSlider("AimFOVTransparency", {
    Text    = "Fill Transparency",
    Min     = 0,
    Max     = 100,
    Default = 80,
    Rounding = 0,
    Callback = function(val)
        local t = val/100
        flags["aim_assist_field_of_view_transparency"] = t
        menu_references["aim_assist_field_of_view_show_fov"].on_transparency_change:Fire(1-t)
    end
})

box_fov:AddLabel("Outline Color")
box_fov:AddColorPicker("AimFOVOutlineColor", {
    Default  = flags["aim_assist_field_of_view_outline_color"],
    Callback = function(val)
        flags["aim_assist_field_of_view_outline_color"] = val
        menu_references["aim_assist_field_of_view_outline"].on_color_change:Fire(val)
    end
})

box_fov:AddSlider("AimFOVOutlineTransparency", {
    Text    = "Outline Transparency",
    Min     = 0,
    Max     = 100,
    Default = 40,
    Rounding = 0,
    Callback = function(val)
        local t = val/100
        flags["aim_assist_field_of_view_outline_transparency"] = t
        menu_references["aim_assist_field_of_view_outline"].on_transparency_change:Fire(1-t)
    end
})

box_fov:AddLabel("Dead Zone Color")
box_fov:AddColorPicker("AimFOVDeadZoneColor", {
    Default  = flags["aim_assist_field_of_view_dead_zone_color"],
    Callback = function(val)
        flags["aim_assist_field_of_view_dead_zone_color"] = val
        menu_references["aim_assist_field_of_view_dead_zone"].on_color_change:Fire(val)
    end
})

box_fov:AddSlider("AimFOVDeadZoneTransparency", {
    Text    = "Dead Zone Transparency",
    Min     = 0,
    Max     = 100,
    Default = 80,
    Rounding = 0,
    Callback = function(val)
        local t = val/100
        flags["aim_assist_field_of_view_dead_zone_transparency"] = t
        menu_references["aim_assist_field_of_view_dead_zone"].on_transparency_change:Fire(1-t)
    end
})

-- ---- Don't Aim If ----
local box_dontaim = tab_aim:AddRightGroupbox("Conditions")

box_dontaim:AddDropdown("AimAssistDontAimIf", {
    Text     = "Don't aim if",
    Values   = {"no gun equipped", "reloading"},
    Default  = {"no gun equipped", "reloading"},
    Multi    = true,
    Callback = function(val)
        local list = {}
        for k, v in val do if v then list[#list+1] = k end end
        menu_references["aim_assist_dont_aim_if"].on_dropdown_change:Fire(list)
    end
})

-- ---- Magnetic Aim ----
local box_mag = tab_aim:AddRightGroupbox("Magnetic Aim")

box_mag:AddToggle("MagneticAim", {
    Text    = "Enabled",
    Default = false,
    Callback = function(val)
        flags["magnetic_aim"] = val
        menu_references["magnetic_aim"].on_toggle_change:Fire(val)
    end
})

box_mag:AddSlider("MagneticAimFOV", {
    Text    = "FOV (degrees)",
    Min     = 1,
    Max     = 180,
    Default = 30,
    Rounding = 0,
    Callback = function(val)
        flags["magnetic_aim_fov"] = val
        menu_references["magnetic_aim_fov"].on_slider_change:Fire(val)
    end
})

box_mag:AddSlider("MagneticAimStrength", {
    Text    = "Strength",
    Min     = 1,
    Max     = 100,
    Default = 50,
    Rounding = 0,
    Callback = function(val)
        flags["magnetic_aim_strength"] = val
        menu_references["magnetic_aim_strength"].on_slider_change:Fire(val)
    end
})

box_mag:AddDropdown("MagneticAimHitbox", {
    Text     = "Hitbox",
    Values   = {"head", "root"},
    Default  = {"head"},
    Multi    = false,
    Callback = function(val)
        menu_references["magnetic_aim_hitbox"].on_dropdown_change:Fire({val})
    end
})

box_mag:AddToggle("MagneticAimADS", {
    Text    = "Only when ADS",
    Default = true,
    Callback = function(val)
        flags["magnetic_aim_only_when_ads"] = val
        menu_references["magnetic_aim_only_when_ads"].on_toggle_change:Fire(val)
    end
})

box_mag:AddToggle("MagneticAimTeamCheck", {
    Text    = "Team Check",
    Default = false,
    Callback = function(val)
        flags["magnetic_aim_team_check"] = val
        menu_references["magnetic_aim_team_check"].on_toggle_change:Fire(val)
    end
})

-- ============================================================
-- TAB: SILENT AIM
-- ============================================================

local tab_silent = window:AddTab("Silent Aim")

local box_sa = tab_silent:AddLeftGroupbox("Silent Aim")

box_sa:AddToggle("SilentAim", {
    Text    = "Enabled",
    Default = false,
    Callback = function(val)
        flags["silent_aim"] = val
        menu_references["silent_aim"].on_toggle_change:Fire(val)
    end
})

box_sa:AddDropdown("SilentAimHitbox", {
    Text     = "Hitbox",
    Values   = {"head", "root", "closest"},
    Default  = {"head"},
    Multi    = false,
    Callback = function(val)
        menu_references["silent_aim_hitbox"].on_dropdown_change:Fire({val})
    end
})

box_sa:AddSlider("SilentAimFOV", {
    Text    = "FOV (degrees)",
    Min     = 1,
    Max     = 180,
    Default = 30,
    Rounding = 0,
    Callback = function(val)
        flags["silent_aim_fov"] = val
        menu_references["silent_aim_field_of_view"].on_slider_change:Fire(val)
    end
})

box_sa:AddSlider("SilentAimMultipoint", {
    Text    = "Multipoint",
    Min     = 0,
    Max     = 100,
    Default = 15,
    Rounding = 0,
    Callback = function(val)
        flags["silent_aim_multipoint"] = val
        menu_references["silent_aim_multipoint"].on_slider_change:Fire(val)
    end
})

box_sa:AddSlider("SilentAimMaxCurve", {
    Text    = "Max Curve (100=off)",
    Min     = 1,
    Max     = 100,
    Default = 100,
    Rounding = 0,
    Callback = function(val)
        flags["silent_aim_max_curve"] = val
        menu_references["silent_aim_max_curve"].on_slider_change:Fire(val)
    end
})

box_sa:AddToggle("SilentAimDontCurveVertically", {
    Text    = "Don't Curve Vertically",
    Default = false,
    Callback = function(val)
        flags["silent_aim_dont_curve_vertically"] = val
        menu_references["silent_aim_dont_curve_vertically"].on_toggle_change:Fire(val)
    end
})

box_sa:AddSlider("SilentAimRedirectChance", {
    Text    = "Redirect Chance (%)",
    Min     = 0,
    Max     = 100,
    Default = 100,
    Rounding = 0,
    Callback = function(val)
        flags["silent_aim_redirect_chance"] = val
        menu_references["silent_aim_redirect_chance"].on_slider_change:Fire(val)
    end
})

box_sa:AddSlider("SilentAimMaxDistance", {
    Text    = "Max Distance (0=auto)",
    Min     = 0,
    Max     = 2500,
    Default = 0,
    Rounding = 0,
    Callback = function(val)
        flags["silent_aim_max_distance"] = val
        menu_references["silent_aim_max_distance"].on_slider_change:Fire(val)
    end
})

-- ---- Silent Aim FOV Circle ----
local box_sa_fov = tab_silent:AddRightGroupbox("FOV Visualizer")

box_sa_fov:AddToggle("SilentAimShowFOV", {
    Text    = "Show FOV",
    Default = false,
    Callback = function(val)
        flags["silent_aim_field_of_view_show_fov"] = val
        menu_references["silent_aim_field_of_view_show_fov"].on_toggle_change:Fire(val)
    end
})

box_sa_fov:AddLabel("Fill Color")
box_sa_fov:AddColorPicker("SilentAimFOVColor", {
    Default  = color3_fromrgb(181, 255, 246),
    Callback = function(val)
        flags["silent_aim_field_of_view_color"] = val
        menu_references["silent_aim_field_of_view_show_fov"].on_color_change:Fire(val)
    end
})

box_sa_fov:AddSlider("SilentAimFOVTransparency", {
    Text    = "Fill Transparency",
    Min     = 0,
    Max     = 100,
    Default = 80,
    Rounding = 0,
    Callback = function(val)
        local t = val/100
        flags["silent_aim_field_of_view_transparency"] = t
        menu_references["silent_aim_field_of_view_show_fov"].on_transparency_change:Fire(1-t)
    end
})

box_sa_fov:AddLabel("Outline Color")
box_sa_fov:AddColorPicker("SilentAimFOVOutlineColor", {
    Default  = color3_fromrgb(181, 255, 246),
    Callback = function(val)
        flags["silent_aim_field_of_view_outline_color"] = val
        menu_references["silent_aim_field_of_view_outline"].on_color_change:Fire(val)
    end
})

box_sa_fov:AddSlider("SilentAimFOVOutlineTransparency", {
    Text    = "Outline Transparency",
    Min     = 0,
    Max     = 100,
    Default = 40,
    Rounding = 0,
    Callback = function(val)
        local t = val/100
        flags["silent_aim_field_of_view_outline_transparency"] = t
        menu_references["silent_aim_field_of_view_outline"].on_transparency_change:Fire(1-t)
    end
})

-- ============================================================
-- TAB: TRIGGERBOT
-- ============================================================

local tab_tb = window:AddTab("Triggerbot")

local box_tb = tab_tb:AddLeftGroupbox("Triggerbot")

box_tb:AddToggle("Triggerbot", {
    Text    = "Enabled",
    Default = false,
    Callback = function(val)
        flags["triggerbot"] = val
        menu_references["triggerbot"].on_toggle_change:Fire(val)
    end
})

box_tb:AddDropdown("TriggerbotHitboxes", {
    Text     = "Hitboxes",
    Values   = {"head", "torso", "arms", "legs"},
    Default  = {"head", "torso"},
    Multi    = true,
    Callback = function(val)
        local list = {}
        for k, v in val do if v then list[#list+1] = k end end
        menu_references["triggerbot_hitboxes"].on_dropdown_change:Fire(list)
    end
})

box_tb:AddSlider("TriggerbotMaxDistance", {
    Text    = "Max Distance (0=auto)",
    Min     = 0,
    Max     = 2500,
    Default = 0,
    Rounding = 0,
    Callback = function(val)
        flags["triggerbot_max_distance"] = val
        menu_references["triggerbot_max_distance"].on_slider_change:Fire(val)
    end
})

box_tb:AddSlider("TriggerbotCooldown", {
    Text    = "Cooldown (s)",
    Min     = 0,
    Max     = 5,
    Default = 0,
    Rounding = 2,
    Callback = function(val)
        flags["triggerbot_cooldown"] = val
        menu_references["triggerbot_cooldown"].on_slider_change:Fire(val)
    end
})

box_tb:AddSlider("TriggerbotDelay", {
    Text    = "Delay (s)",
    Min     = 0,
    Max     = 1,
    Default = 0,
    Rounding = 3,
    Callback = function(val)
        flags["triggerbot_delay"] = val
        menu_references["triggerbot_delay"].on_slider_change:Fire(val)
    end
})

box_tb:AddSlider("TriggerbotHoverTime", {
    Text    = "Hover Time (s)",
    Min     = 0,
    Max     = 2,
    Default = 0,
    Rounding = 2,
    Callback = function(val)
        flags["triggerbot_hover_time"] = val
        menu_references["triggerbot_hover_time"].on_slider_change:Fire(val)
    end
})

box_tb:AddSlider("TriggerbotRefreshRate", {
    Text    = "Refresh Rate (0=every frame)",
    Min     = 0,
    Max     = 0.1,
    Default = 0,
    Rounding = 4,
    Callback = function(val)
        flags["triggerbot_refresh_rate"] = val
        menu_references["triggerbot_refresh_rate"].on_slider_change:Fire(val)
    end
})

-- ---- Angular FOV ----
local box_tb_afov = tab_tb:AddRightGroupbox("Angular FOV")

box_tb_afov:AddToggle("TriggerbotAngularFOV", {
    Text    = "Enabled",
    Default = false,
    Callback = function(val)
        flags["triggerbot_angular_fov"] = val
        menu_references["triggerbot_angular_fov"].on_toggle_change:Fire(val)
    end
})

box_tb_afov:AddSlider("TriggerbotAngularFOVValue", {
    Text    = "Degrees",
    Min     = 1,
    Max     = 180,
    Default = 30,
    Rounding = 0,
    Callback = function(val)
        flags["triggerbot_angular_fov_value"] = val
        menu_references["triggerbot_angular_fov_value"].on_slider_change:Fire(val)
    end
})

box_tb_afov:AddToggle("TriggerbotAngularFOVVisualize", {
    Text    = "Visualize",
    Default = false,
    Callback = function(val)
        flags["triggerbot_angular_fov_visualize"] = val
        menu_references["triggerbot_angular_fov_visualize"].on_toggle_change:Fire(val)
    end
})

box_tb_afov:AddSlider("TriggerbotAngularFOVX", {
    Text    = "Hitbox X",
    Min     = 0.5,
    Max     = 20,
    Default = 2,
    Rounding = 1,
    Callback = function(val)
        flags["triggerbot_angular_fov_x"] = val
        menu_references["triggerbot_angular_fov_x"].on_slider_change:Fire(val)
    end
})

box_tb_afov:AddSlider("TriggerbotAngularFOVY", {
    Text    = "Hitbox Y",
    Min     = 0.5,
    Max     = 20,
    Default = 5,
    Rounding = 1,
    Callback = function(val)
        flags["triggerbot_angular_fov_y"] = val
        menu_references["triggerbot_angular_fov_y"].on_slider_change:Fire(val)
    end
})

box_tb_afov:AddSlider("TriggerbotAngularFOVZ", {
    Text    = "Hitbox Z",
    Min     = 0.5,
    Max     = 20,
    Default = 2,
    Rounding = 1,
    Callback = function(val)
        flags["triggerbot_angular_fov_z"] = val
        menu_references["triggerbot_angular_fov_z"].on_slider_change:Fire(val)
    end
})

-- ============================================================
-- TAB: MISC
-- ============================================================

local tab_misc = window:AddTab("Misc")

-- ---- Jump / Velocity Prediction ----
local box_pred = tab_misc:AddLeftGroupbox("Prediction")

box_pred:AddToggle("JumpPrediction", {
    Text    = "Jump Prediction",
    Default = false,
    Callback = function(val)
        flags["jump_prediction"] = val
    end
})

box_pred:AddSlider("JumpPredictionStrength", {
    Text    = "Jump Strength",
    Min     = 1,
    Max     = 100,
    Default = 50,
    Rounding = 0,
    Callback = function(val)
        flags["jump_prediction_strength"] = val
    end
})

box_pred:AddSlider("JumpPredictionMaxY", {
    Text    = "Jump Max Y",
    Min     = 1,
    Max     = 20,
    Default = 5,
    Rounding = 0,
    Callback = function(val)
        flags["jump_prediction_max_y"] = val
    end
})

box_pred:AddToggle("VelocityPrediction", {
    Text    = "Velocity Prediction",
    Default = false,
    Callback = function(val)
        flags["velocity_prediction"] = val
    end
})

box_pred:AddSlider("VelocityPredictionStrength", {
    Text    = "Velocity Strength",
    Min     = 1,
    Max     = 100,
    Default = 50,
    Rounding = 0,
    Callback = function(val)
        flags["velocity_prediction_strength"] = val
    end
})

-- ---- Shotgun ----
local box_sg = tab_misc:AddLeftGroupbox("Shotgun")

box_sg:AddToggle("ReduceShotgunSpread", {
    Text    = "Reduce Spread",
    Default = false,
    Callback = function(val)
        flags["reduce_shotgun_spread"] = val
        menu_references["reduce_shotgun_spread"].on_toggle_change:Fire(val)
    end
})

box_sg:AddSlider("ReduceShotgunSpreadAmount", {
    Text    = "Reduce Amount (%)",
    Min     = 1,
    Max     = 100,
    Default = 50,
    Rounding = 0,
    Callback = function(val)
        flags["reduce_shotgun_spread_amount"] = val
        menu_references["reduce_shotgun_spread_amount"].on_slider_change:Fire(val)
    end
})

-- ---- Backtrack ----
local box_bt = tab_misc:AddRightGroupbox("Backtrack")

box_bt:AddToggle("Backtrack", {
    Text    = "Enabled",
    Default = false,
    Callback = function(val)
        flags["backtrack"] = val
        menu_references["backtrack"].on_toggle_change:Fire(val)
    end
})

box_bt:AddToggle("BacktrackResetOnHit", {
    Text    = "Reset on Hit",
    Default = false,
    Callback = function(val)
        flags["backtrack_reset_on_hit"] = val
        menu_references["backtrack_reset_on_hit"].on_toggle_change:Fire(val)
    end
})

box_bt:AddSlider("BacktrackLength", {
    Text    = "Length (s)",
    Min     = 0.05,
    Max     = 1,
    Default = 0.2,
    Rounding = 2,
    Callback = function(val)
        flags["backtrack_length"] = val
    end
})

box_bt:AddDropdown("BacktrackTargetStatuses", {
    Text     = "Target Statuses",
    Values   = {"enemy", "neutral", "friendly", "target"},
    Default  = {"neutral"},
    Multi    = true,
    Callback = function(val)
        local list = {}
        for k, v in val do if v then list[#list+1] = k end end
        menu_references["backtrack_target_statuses"].on_dropdown_change:Fire(list)
    end
})

box_bt:AddDropdown("BacktrackMaterial", {
    Text     = "Material",
    Values   = {"neon", "forcefield"},
    Default  = {"neon"},
    Multi    = false,
    Callback = function(val)
        menu_references["backtrack_material"].on_dropdown_change:Fire({val})
    end
})

box_bt:AddLabel("Color")
box_bt:AddColorPicker("BacktrackColor", {
    Default  = color3_fromrgb(255, 50, 50),
    Callback = function(val)
        flags["backtrack_color"] = val
        menu_references["backtrack_color"].on_color_change:Fire(val)
    end
})

box_bt:AddSlider("BacktrackTransparency", {
    Text    = "Transparency",
    Min     = 0,
    Max     = 100,
    Default = 50,
    Rounding = 0,
    Callback = function(val)
        local t = val/100
        flags["backtrack_transparency"] = t
        menu_references["backtrack_color"].on_transparency_change:Fire(t)
    end
})

-- ---- Hitbox Expander ----
local box_hbe = tab_misc:AddRightGroupbox("Hitbox Expander")

box_hbe:AddToggle("HitboxExpander", {
    Text    = "Enabled",
    Default = false,
    Callback = function(val)
        flags["hitbox_expander"] = val
        menu_references["hitbox_expander"].on_toggle_change:Fire(val)
    end
})

box_hbe:AddSlider("HitboxExpanderX", {
    Text    = "Size X",
    Min     = 0.5,
    Max     = 20,
    Default = 2,
    Rounding = 1,
    Callback = function(val)
        flags["hitbox_expander_size_x"] = val
        menu_references["hitbox_expander_size_x"].on_slider_change:Fire(val)
    end
})

box_hbe:AddSlider("HitboxExpanderY", {
    Text    = "Size Y",
    Min     = 0.5,
    Max     = 20,
    Default = 5,
    Rounding = 1,
    Callback = function(val)
        flags["hitbox_expander_size_y"] = val
        menu_references["hitbox_expander_size_y"].on_slider_change:Fire(val)
    end
})

box_hbe:AddSlider("HitboxExpanderZ", {
    Text    = "Size Z",
    Min     = 0.5,
    Max     = 20,
    Default = 2,
    Rounding = 1,
    Callback = function(val)
        flags["hitbox_expander_size_z"] = val
        menu_references["hitbox_expander_size_z"].on_slider_change:Fire(val)
    end
})

box_hbe:AddToggle("HitboxExpanderVisualize", {
    Text    = "Visualize",
    Default = false,
    Callback = function(val)
        flags["hitbox_expander_visualize"] = val
        menu_references["hitbox_expander_visualize"].on_toggle_change:Fire(val)
    end
})

box_hbe:AddToggle("HitboxExpanderTeamCheck", {
    Text    = "Team Check",
    Default = false,
    Callback = function(val)
        flags["hitbox_expander_team_check"] = val
        menu_references["hitbox_expander_team_check"].on_toggle_change:Fire(val)
    end
})

-- ============================================================
-- TAB: SETTINGS
-- ============================================================

local tab_settings = window:AddTab("Settings")
local box_settings = tab_settings:AddLeftGroupbox("UI")

theme_manager:SetLibrary(library)
save_manager:SetLibrary(library)
save_manager:IgnoreThemeSettings()
save_manager:SetIgnoreIndexes({})
save_manager:SetFolder("juju")

theme_manager:ApplyToGroupbox(box_settings)
save_manager:BuildConfigSection(tab_settings:AddLeftGroupbox("Config"))

-- ============================================================
-- KEYBIND: toggle menu with RightShift
-- ============================================================

library:SetOpenKey(Enum.KeyCode.RightShift)

-- ============================================================
-- FIRE INITIAL VALUES so logic block locals are correct on load
-- ============================================================

-- aim assist defaults
menu_references["aim_assist_hitbox"].on_dropdown_change:Fire({"head"})
menu_references["aim_assist_method"].on_dropdown_change:Fire({"mouse"})
menu_references["aim_assist_dont_aim_if"].on_dropdown_change:Fire({"no gun equipped", "reloading"})
menu_references["aim_assist_smoothing_type"].on_dropdown_change:Fire({"random"})
menu_references["aim_assist_field_of_view"].on_slider_change:Fire(flags["aim_assist_field_of_view"])
menu_references["aim_assist_dead_zone"].on_slider_change:Fire(0)
menu_references["aim_assist_multipoint"].on_slider_change:Fire(15)
menu_references["aim_assist_horizontal_smoothing_amount"].on_slider_change:Fire(45)
menu_references["aim_assist_vertical_smoothing_amount"].on_slider_change:Fire(45)

-- silent aim defaults
menu_references["silent_aim_hitbox"].on_dropdown_change:Fire({"head"})
menu_references["silent_aim_field_of_view"].on_slider_change:Fire(flags["silent_aim_fov"])
menu_references["silent_aim_multipoint"].on_slider_change:Fire(15)
menu_references["silent_aim_max_curve"].on_slider_change:Fire(100)
menu_references["silent_aim_redirect_chance"].on_slider_change:Fire(100)

-- triggerbot defaults
menu_references["triggerbot_hitboxes"].on_dropdown_change:Fire({"head", "torso"})
menu_references["triggerbot_angular_fov_x"].on_slider_change:Fire(2)
menu_references["triggerbot_angular_fov_y"].on_slider_change:Fire(5)
menu_references["triggerbot_angular_fov_z"].on_slider_change:Fire(2)
menu_references["triggerbot_angular_fov_value"].on_slider_change:Fire(30)

-- legitbot defaults
menu_references["legitbot_target_selection_ignore_if"].on_dropdown_change:Fire({"knocked", "invulnerable", "not visible"})
menu_references["legitbot_target_selection_untarget_when"].on_dropdown_change:Fire({"knocked", "not visible"})

-- magnetic aim defaults
menu_references["magnetic_aim_hitbox"].on_dropdown_change:Fire({"head"})
menu_references["magnetic_aim_fov"].on_slider_change:Fire(30)
menu_references["magnetic_aim_strength"].on_slider_change:Fire(50)

-- backtrack defaults
menu_references["backtrack_target_statuses"].on_dropdown_change:Fire({"neutral"})
menu_references["backtrack_material"].on_dropdown_change:Fire({"neon"})

-- hitbox expander defaults
menu_references["hitbox_expander_size_x"].on_slider_change:Fire(2)
menu_references["hitbox_expander_size_y"].on_slider_change:Fire(5)
menu_references["hitbox_expander_size_z"].on_slider_change:Fire(2)
