-- Saved design: Isaac keeps D6, optionally adds Knife + Soy Milk.
-- Mode lives in the existing mod save, not in the browser design notebook.
local Presets = { mode = "normal" }

function Presets:ApplyIsaac(player)
    if player:GetPlayerType() ~= PlayerType.PLAYER_ISAAC then return end
    local items = { CollectibleType.COLLECTIBLE_D6 }
    if self.mode == "knife" then
        table.insert(items, CollectibleType.COLLECTIBLE_MOMS_KNIFE)
        table.insert(items, CollectibleType.COLLECTIBLE_SOY_MILK)
    end
    for _, id in ipairs(items) do
        if not player:HasCollectible(id) then
            local config = Isaac.GetItemConfig():GetCollectible(id)
            player:AddCollectible(id, config and config.MaxCharges or 0, false)
        end
    end
end

function Presets:OnGameStart(continued)
    self.mode = self.tracker.data._isaacLoadoutMode == "knife" and "knife" or "normal"
    -- Do not alter an existing Continue inventory. Reset re-applies the preset.
    if not continued then
        for i = 0, Game():GetNumPlayers() - 1 do self:ApplyIsaac(Isaac.GetPlayer(i)) end
    end
end

function Presets:Init(mod, setups, tracker)
    self.tracker = tracker
    local original = setups.ApplySetup
    setups.ApplySetup = function(player)
        if player:GetPlayerType() == PlayerType.PLAYER_ISAAC then
            self:ApplyIsaac(player)
        else
            original(player)
        end
    end
    mod:AddCallback(ModCallbacks.MC_EXECUTE_CMD, function(_, command, parameters)
        if command ~= "trk" then return end
        if parameters == "loadout knife" or parameters == "loadout normal" then
            self.mode = parameters == "loadout knife" and "knife" or "normal"
            tracker.data._isaacLoadoutMode = self.mode
            tracker:Save()
            Isaac.ConsoleOutput("Isaac preset: " .. self.mode .. ". Applies on fresh run / Twisted reset.\n")
        elseif parameters == "loadout apply" then
            self:ApplyIsaac(Isaac.GetPlayer(0))
            Isaac.ConsoleOutput("Isaac preset granted (existing acquired items untouched).\n")
        elseif parameters == "loadout status" then
            local p = Isaac.GetPlayer(0)
            local report = "mode=" .. self.mode .. " player=" .. p:GetPlayerType()
                .. " D6=" .. p:GetCollectibleNum(CollectibleType.COLLECTIBLE_D6)
                .. " Knife=" .. p:GetCollectibleNum(CollectibleType.COLLECTIBLE_MOMS_KNIFE)
                .. " Soy=" .. p:GetCollectibleNum(CollectibleType.COLLECTIBLE_SOY_MILK)
            Isaac.ConsoleOutput(report .. "\n")
            Isaac.DebugString("[TRK loadout] " .. report)
        else
            Isaac.ConsoleOutput("trk loadout normal | knife | apply | status\n")
        end
    end)
end

return Presets
