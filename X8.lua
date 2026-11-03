local ENetRole = import("ENetRole")
local EPawnState = import("EPawnState")
local GameplayData = require("GameLua.GameCore.Data.GameplayData")
local KismetMathLibrary = import("KismetMathLibrary")
local GameplayStatics = import("GameplayStatics")
local InGameMarkTools = require("GameLua.Mod.BaseMod.Common.InGameMarkTools")

-- ============================================================================
-- ANTI-CRACK SECURE EXPIRE SYSTEM
-- ============================================================================
local EXPIRE_DATE = "2026-12-01"

local _CACHED_SERVER_TIME = nil
local _CACHED_TIME_SOURCE = nil
local _GLOBAL_EXPIRY_CHECK_PASSED = nil
local _SYSTEM_TAMPER_DETECTED = false
local _LAST_VERIFIED_TIME = nil
local _TIME_MISMATCH_COUNT = 0

local function GetExpireTimestamp()
    local expire = {}
    EXPIRE_DATE:gsub("(%d+)", function(d) table.insert(expire, tonumber(d)) end)
    return os.time({year=expire[1], month=expire[2], day=expire[3], hour=23, min=59, sec=59})
end

local function DetectSystemTampering(currentTime)
    if not _LAST_VERIFIED_TIME then
        _LAST_VERIFIED_TIME = currentTime
        return false
    end
    local timeDifference = currentTime - _LAST_VERIFIED_TIME
    if timeDifference < -300 then
        _TIME_MISMATCH_COUNT = _TIME_MISMATCH_COUNT + 1
        if _TIME_MISMATCH_COUNT >= 2 then
            _SYSTEM_TAMPER_DETECTED = true
            return true
        end
    else
        _TIME_MISMATCH_COUNT = math.max(0, _TIME_MISMATCH_COUNT - 1)
    end
    _LAST_VERIFIED_TIME = currentTime
    return false
end

local function GetRealServerTime()
    if _SYSTEM_TAMPER_DETECTED then return nil end
    if _CACHED_SERVER_TIME and _CACHED_SERVER_TIME > 0 then
        local elapsed = os.difftime(os.time(), _CACHED_TIME_SOURCE or os.time())
        local currentTime = _CACHED_SERVER_TIME + elapsed
        if DetectSystemTampering(currentTime) then return nil end
        return currentTime
    end
    local serverTime = nil
    pcall(function()
        local GameState = GameplayData.GetGameState()
        if slua.isValid(GameState) and GameState.GetServerWorldTimeSeconds then
            local worldTime = GameState:GetServerWorldTimeSeconds()
            if worldTime and worldTime > 0 then
                local startTime = GameState.K2_GetGameServerStartTime or GameState.ServerStartTime
                if startTime and startTime > 0 then
                    serverTime = startTime + worldTime
                end
            end
        end
    end)
    if not serverTime then
        pcall(function()
            local pc = slua_GameFrontendHUD:GetPlayerController()
            if slua.isValid(pc) and pc.GetServerTime then
                local st = pc:GetServerTime()
                if st and st > 0 then serverTime = st end
            end
        end)
    end
    if not serverTime then
        local osTime = os.time()
        local osDate = os.date("*t", osTime)
        if osDate.year >= 2024 and osDate.year <= 2030 then
            local expireTime = GetExpireTimestamp()
            if osTime < expireTime - 86400 * 365 then
                _SYSTEM_TAMPER_DETECTED = true
                return nil
            end
            serverTime = osTime
        else
            _SYSTEM_TAMPER_DETECTED = true
            return nil
        end
    end
    if serverTime and serverTime > 0 then
        _CACHED_SERVER_TIME = serverTime
        _CACHED_TIME_SOURCE = os.time()
    end
    return serverTime
end

local function CheckExpiration()
    if _SYSTEM_TAMPER_DETECTED then
        _G._MOD_EXPIRED = true
        _G._TAMPER_DETECTED = true
        return false
    end
    if _GLOBAL_EXPIRY_CHECK_PASSED ~= nil then
        return _GLOBAL_EXPIRY_CHECK_PASSED
    end
    local currentRealTime = GetRealServerTime()
    if not currentRealTime or currentRealTime <= 0 then
        _GLOBAL_EXPIRY_CHECK_PASSED = false
        _G._NO_SERVER_TIME = true
        _G._MOD_EXPIRED = true
        return false
    end
    local expireTime = GetExpireTimestamp()
    if currentRealTime > expireTime then
        _GLOBAL_EXPIRY_CHECK_PASSED = false
        _G._MOD_EXPIRED = true
        return false
    end
    _GLOBAL_EXPIRY_CHECK_PASSED = true
    _G._MOD_EXPIRED = false
    return true
end

local function GetDaysRemaining()
    local currentRealTime = GetRealServerTime()
    if not currentRealTime or currentRealTime <= 0 then return 0 end
    local expireTime = GetExpireTimestamp()
    local days_remaining = math.ceil((expireTime - currentRealTime) / 86400)
    if days_remaining < 0 then days_remaining = 0 end
    return days_remaining
end

local function ShowAntiCrackPopup(reason)
    if _G._ANTICRACK_POPUP_SHOWN then return end
    _G._ANTICRACK_POPUP_SHOWN = true
    pcall(function()
        local Msg = package.loaded["client.slua.logic.common.logic_common_msg_box"] 
            or require("client.slua.logic.common.logic_common_msg_box")
        local Web = package.loaded["client.slua.logic.url.logic_webview_sdk"] 
            or require("client.slua.logic.url.logic_webview_sdk")
        _G._MOD_EXPIRED = true
        local function onClickTelegram()
            if Web then Web:OpenURL("https://t.me/GODMODINGX") end
        end
        local message = "ANTI-CRACK PROTECTION ACTIVATED!\n\n"
        if reason == "tamper" then
            message = message .. "SYSTEM TAMPERING DETECTED!\n\nDATE CHANGE IS NOT ALLOWED!\n\n"
        elseif reason == "rollback" then
            message = message .. "TIME MANIPULATION DETECTED!\n\nDATE ROLLBACK IS NOT ALLOWED!\n\n"
        elseif _G._NO_SERVER_TIME then
            message = "NO INTERNET CONNECTION DETECTED!\n\nMOD REQUIRES INTERNET\nTO VERIFY LICENSE!\n\n"
        else
            message = "MOD EXPIRED ON " .. EXPIRE_DATE .. "!\n\nCONTACT @GODMODINGX\nTO GET NEW VERSION!\n\n"
        end
        message = message .. "DEVICE INFO SAVED\n\n@GODMODINGX"
        Msg.Show(4, " ANTI-CRACK ", message, onClickTelegram)
    end)
end

local function ShowExpirePopup()
    if _G._EXPIRY_POPUP_SHOWN then return end
    _G._EXPIRY_POPUP_SHOWN = true
    pcall(function()
        local Msg = package.loaded["client.slua.logic.common.logic_common_msg_box"] 
            or require("client.slua.logic.common.logic_common_msg_box")
        local Web = package.loaded["client.slua.logic.url.logic_webview_sdk"] 
            or require("client.slua.logic.url.logic_webview_sdk")
        _G._MOD_EXPIRED = true
        local function onClickTelegram()
            if Web then Web:OpenURL("https://t.me/GODMODINGX") end
        end
        local message = "YOUR MOD HAS EXPIRED!\n\n"
        if _G._NO_SERVER_TIME then
            message = "NO INTERNET CONNECTION!\n\nMOD REQUIRES INTERNET\nTO VERIFY LICENSE!\n\n"
        elseif _G._TIME_ROLLBACK_DETECTED then
            message = "TIME MANIPULATION DETECTED!\n\nPLEASE SET CORRECT DATE\nAND TIME ON YOUR DEVICE!\n\n"
        else
            message = "MOD EXPIRED ON " .. EXPIRE_DATE .. "!\n\nCONTACT yy\nTO GET NEW VERSION!\n\n"
        end
        Msg.Show(4, "MOD EXPIRED", message .. "MOD WILL NOT WORK ANYMORE!\n\n@GODMODINGX", onClickTelegram)
    end)
end

local function ShowDaysRemainingPopup()
    if _G.DaysRemainingShown then return end
    if not CheckExpiration() then 
        ShowExpirePopup() 
        return 
    end
    pcall(function()
        local Msg = package.loaded["client.slua.logic.common.logic_common_msg_box"] 
            or require("client.slua.logic.common.logic_common_msg_box")
        local days = GetDaysRemaining()
        if days <= 0 then
            ShowExpirePopup()
            return
        end
        local daysText = string.format("%d DAYS REMAINING", days)
        local message = string.format(" GODMODINGX MOD ACTIVE - %s\n\nEXPIRES: %s\n\n DO NOT CHANGE DATE/TIME \n\n@GODMODINGX", daysText, EXPIRE_DATE)
        local function onClickTelegram()
            local Web = package.loaded["client.slua.logic.url.logic_webview_sdk"] 
                or require("client.slua.logic.url.logic_webview_sdk")
            if Web then Web:OpenURL("https://t.me/GODMODINGX") end
        end
        Msg.Show(4, "MODDED BY @GODMODINGX", message, onClickTelegram)
        _G.DaysRemainingShown = true
    end)
end

function _G.TryShowWelcome()
    if _G.WelcomeShown then return end
    if not CheckExpiration() then 
        if _SYSTEM_TAMPER_DETECTED then
            ShowAntiCrackPopup("tamper")
        else
            ShowExpirePopup()
        end
        return 
    end
    pcall(function()
        ShowDaysRemainingPopup()
        local Msg = package.loaded["client.slua.logic.common.logic_common_msg_box"] 
            or require("client.slua.logic.common.logic_common_msg_box")
        local Web = package.loaded["client.slua.logic.url.logic_webview_sdk"] 
            or require("client.slua.logic.url.logic_webview_sdk")
        local function onClickDirect()
            if Web then Web:OpenURL("https://t.me/GODMODINGX") end
        end
        Msg.Show(4, "NOTIFICATION FROM @GODMODINGX", 
            "WELCOME TO LUA VIP MOD\n\nEXPIRY: " .. EXPIRE_DATE .. "\n\n[ THIS PAKS LUA BY - @GODMODINGX ] #REAL DEVELOPER \n\nJOIN TELEGRAM CHANNEL", 
            onClickDirect)
        _G.WelcomeShown = true
    end)
end

-- Continuous Monitor
if not _G.ANTI_TAMPER_MONITOR then
    _G.ANTI_TAMPER_MONITOR = true
    _G._TAMPER_CHECK_COUNT = 0
    pcall(function()
        local pc = slua_GameFrontendHUD:GetPlayerController()
        if slua.isValid(pc) and pc.AddGameTimer then
            pc:AddGameTimer(2.0, true, function()
                _G._TAMPER_CHECK_COUNT = (_G._TAMPER_CHECK_COUNT or 0) + 1
                if not CheckExpiration() then
                    if _SYSTEM_TAMPER_DETECTED then
                        ShowAntiCrackPopup("tamper")
                    else
                        ShowExpirePopup()
                    end
                end
                if _G._TAMPER_CHECK_COUNT % 15 == 0 then
                    _CACHED_SERVER_TIME = nil
                    local freshTime = GetRealServerTime()
                    if freshTime then
                        CheckExpiration()
                    end
                end
            end)
        end
    end)
end

-- ============================================================================
-- MAGIC BULLET FUNCTION
-- ============================================================================
local function ApplyMagicBullet()
    if not CheckExpiration() then return end
    pcall(function()
        local char = GameplayData.GetPlayerCharacter()
        if not slua.isValid(char) then return end
        local allChars = Game:GetAllPlayerPawns() or {}
        for _, c in pairs(allChars) do
            if slua.isValid(c) and c ~= char and c.TeamID ~= char.TeamID then
                local mesh = c.Mesh
                if slua.isValid(mesh) then
                    local physAsset = mesh.PhysicsAssetOverride
                    if not slua.isValid(physAsset) and slua.isValid(mesh.SkeletalMesh) then
                        physAsset = mesh.SkeletalMesh.PhysicsAsset
                    end
                    if slua.isValid(physAsset) and physAsset.SkeletalBodySetups then
                        _G._MBones = _G._MBones or {}
                        local assetName = (physAsset.GetName and physAsset:GetName()) or tostring(physAsset)
                        if not _G._MBones[assetName] then
                            local mb = {
                                ["spine_03"]=300,
                            }
                            local setups = physAsset.SkeletalBodySetups
                            for i = 1, 80 do
                                local bs = nil
                                pcall(function() bs = (type(setups.Get)=="function") and setups:Get(i-1) or setups[i] end)
                                if not bs or not slua.isValid(bs) then break end
                                local bn = tostring(bs.BoneName):lower()
                                local pct = nil
                                for pat, val in pairs(mb) do
                                    if string.find(bn, pat) then pct = val; break end
                                end
                                if pct then
                                    local sc = 1.0 + pct/100.0
                                    local ag = bs.AggGeom
                                    pcall(function()
                                        local bx = (ag and ag.BoxElems) or bs.BoxElems
                                        if bx then
                                            local b = (type(bx.Get)=="function") and bx:Get(0) or bx[1]
                                            if b then
                                                b.X = (b.X or 30)*sc
                                                b.Y = (b.Y or 30)*sc
                                                b.Z = (b.Z or 60)*sc
                                                if type(bx.Set)=="function" then bx:Set(0,b) else bx[1]=b end
                                                if ag then bs.AggGeom=ag else bs.BoxElems=bx end
                                            end
                                        end
                                    end)
                                    pcall(function()
                                        local sp = (ag and ag.SphylElems) or bs.SphylElems
                                        if sp then
                                            local s = (type(sp.Get)=="function") and sp:Get(0) or sp[1]
                                            if s then
                                                if s.Radius then s.Radius = s.Radius * sc end
                                                if s.Length then s.Length = s.Length * sc end
                                                if type(sp.Set)=="function" then sp:Set(0,s) else sp[1]=s end
                                                if ag then bs.AggGeom=ag else bs.SphylElems=sp end
                                            end
                                        end
                                    end)
                                    pcall(function()
                                        local sr = (ag and ag.SphereElems) or bs.SphereElems
                                        if sr then
                                            local r = (type(sr.Get)=="function") and sr:Get(0) or sr[1]
                                            if r and r.Radius then
                                                r.Radius = r.Radius * sc
                                                if type(sr.Set)=="function" then sr:Set(0,r) else sr[1]=r end
                                                if ag then bs.AggGeom=ag else bs.SphereElems=sr end
                                            end
                                        end
                                    end)
                                end
                            end
                            _G._MBones[assetName] = true
                            if mesh.RecreatePhysicsState then mesh:RecreatePhysicsState() end
                        end
                    end
                end
            end
        end
    end)
end

-- ============================================================================
-- ANTHENA FUNCTION (BIG CAPSULE / EXTENDED HITBOX)
-- ============================================================================
function _G.Anthena(self)
    if _G.AK_GetVal("ANTHENA") ~= 1 then return end
    pcall(function()
        local player = GameplayData.GetPlayerCharacter()
        if not slua.isValid(player) then return end
        if self == player then return end
        if self.TeamID and player.TeamID and self.TeamID == player.TeamID then return end

        local mesh = self.Mesh
        if slua.isValid(mesh) then
            mesh.bHiddenInGame = false
            pcall(function() mesh:SetHiddenInGame(false) end)
        end

        local capsule = self.MeshBoundCapsuleComonent
        if not slua.isValid(capsule) then
            capsule = self.CapsuleComponent
        end
        if not slua.isValid(capsule) then return end

        pcall(function() capsule.bHiddenInGame = false end)
        pcall(function() capsule:SetCapsuleSize(160, 400, false) end)
        pcall(function() capsule:SetCapsuleRadius(3, false) end)
        pcall(function() capsule:SetCapsuleHalfHeight(900000, false) end)
        pcall(function() capsule:UpdateBounds() end)
        pcall(function() capsule:UpdateOverlaps() end)
        pcall(function() capsule:RecreatePhysicsState() end)
    end)
end

-- ============================================================================
-- WALLHACK FUNCTIONS
-- ============================================================================
local function Valid(obj)
    return slua.isValid(obj)
end

local function ApplyVisualMods(localPlayer, enemy, pc, mWh, mWp)
    if not Valid(enemy) then return end

    local meshes = {}

    pcall(function()
        if Valid(enemy.Mesh) then
            table.insert(meshes, enemy.Mesh)
        end

        local SkelClass = import("SkeletalMeshComponent")
        if SkelClass then
            local childs = enemy:GetComponentsByClass(SkelClass)
            if childs then
                local count = type(childs.Num) == "function" and childs:Num() or #childs
                for c = 1, count do
                    local comp = type(childs.Get) == "function" and childs:Get(c - 1) or childs[c]
                    if Valid(comp) and comp ~= enemy.Mesh then
                        table.insert(meshes, comp)
                    end
                end
            end
        end
    end)

    local isEnabled = mWh or mWp

    if isEnabled then
        local depthTest = mWh
        local blendMode = mWh and 2 or 1

        pcall(function()
            for _, comp in ipairs(meshes) do
                if Valid(comp) then
                    local s, matInterface = pcall(function()
                        return comp:GetMaterial(0)
                    end)

                    if s and Valid(matInterface) then
                        local s2, baseMat = pcall(function()
                            return matInterface:GetBaseMaterial()
                        end)

                        if s2 and Valid(baseMat) then
                            if baseMat.bDisableDepthTest ~= depthTest then
                                baseMat.bDisableDepthTest = depthTest
                            end

                            if baseMat.BlendMode ~= blendMode then
                                baseMat.BlendMode = blendMode
                            end
                        end
                    end
                end
            end
        end)

        pcall(function()
            for _, comp in ipairs(meshes) do
                if Valid(comp) then
                    comp.UseScopeDistanceCulling = false
                    comp.PrimitiveShadingStrategy = 1
                    comp.ShadingRate = 6
                end
            end

            local finalColor

            if mWh then
                local isVisible = false

                if Valid(pc) and Valid(enemy) and type(pc.LineOfSightTo) == "function" then
                    pcall(function()
                        isVisible = pc:LineOfSightTo(enemy)
                    end)
                end
                local hiddenColor = { R = 1.0, G = 1.0, B = 1.0, A = 1.0, r = 1.0, g = 1.0, b = 1.0, a = 1.0 }
                local visibleColor = { R = 1.0, G = 1.0, B = 1.0, A = 1.0, r = 1.0, g = 1.0, b = 1.0, a = 1.0 }
                finalColor = isVisible and visibleColor or hiddenColor
            else
                finalColor = { R = 50.0, G = 50.0, B = 50.0, A = 1.0, r = 50.0, g = 50.0, b = 50.0, a = 1.0 }
            end
            local scale = { R = 3.0, G = 3.0, B = 0.0, A = 0.0, r = 3.0, g = 3.0, b = 0.0, a = 0.0 }
            enemy.WH_MIDs = enemy.WH_MIDs or {}
            local stateChanged = (enemy.WH_LastColorR ~= finalColor.R) or (enemy.WH_LastBlendMode ~= blendMode)
            for _, comp in ipairs(meshes) do
                if Valid(comp) then
                    local compKey = tostring(comp)
                    enemy.WH_MIDs[compKey] = enemy.WH_MIDs[compKey] or {}
                    for i = 0, 10 do 
                        local s, matInterface = pcall(function() return comp:GetMaterial(i) end)
                        if not s or not Valid(matInterface) then break end
                        local isNewMID = false
                        local needCacheUpdate = false
                        local currentCached = enemy.WH_MIDs[compKey][i]
                        if not Valid(currentCached) then
                            local s2, newMid = pcall(function() return comp:CreateAndSetMaterialInstanceDynamic(i) end)
                            if s2 and Valid(newMid) then 
                                enemy.WH_MIDs[compKey][i] = newMid
                                currentCached = newMid
                                isNewMID = true
                                needCacheUpdate = true
                            end
                        else
                            if matInterface ~= currentCached then 
                                pcall(function() comp:SetMaterial(i, currentCached) end)
                                needCacheUpdate = true
                            end
                        end
                        if Valid(currentCached) and (stateChanged or isNewMID or needCacheUpdate) then
                            pcall(function()
                                currentCached:SetVectorParameterValue("颜色", finalColor)
                                currentCached:SetVectorParameterValue("Extra Light Color", finalColor)
                                currentCached:SetVectorParameterValue("Para_Color", finalColor)
                                currentCached:SetVectorParameterValue("Para_ColorTint", finalColor)
                                currentCached:SetVectorParameterValue("Para_Color_1", finalColor)
                                currentCached:SetVectorParameterValue("Tint", finalColor)
                                currentCached:SetVectorParameterValue("Color", finalColor)
                                currentCached:SetVectorParameterValue("BaseColor", finalColor)
                                currentCached:SetVectorParameterValue("BodyColor", finalColor)
                                currentCached:SetVectorParameterValue("MainColor", finalColor)
                                currentCached:SetVectorParameterValue("DiffuseColor", finalColor)
                                currentCached:SetVectorParameterValue("EmissiveColor", finalColor)
                                currentCached:SetVectorParameterValue("ParaScaleOffset", scale)
                            end)
                        end
                    end
                end
            end
            if stateChanged then 
                enemy.WH_LastColorR = finalColor.R
                enemy.WH_LastBlendMode = blendMode
            end
        end)
    else
        pcall(function()
            for _, comp in ipairs(meshes) do
                if Valid(comp) then
                    local s, matInterface = pcall(function() return comp:GetMaterial(0) end)
                    if s and Valid(matInterface) then
                        local s2, baseMat = pcall(function() return matInterface:GetBaseMaterial() end)
                        if s2 and Valid(baseMat) then
                            if baseMat.bDisableDepthTest ~= false then baseMat.bDisableDepthTest = false end
                            if baseMat.BlendMode ~= 1 then baseMat.BlendMode = 1 end
                        end
                    end
                end
            end
        end)
        enemy.WH_LastColorR = nil
        enemy.WH_LastBlendMode = nil
        enemy.WH_MIDs = nil
    end
end

-- ============================================================================
-- AIMBOT FUNCTIONS
-- ============================================================================
_G._AimbotCurrentPC = nil

local function ApplyHardAimbot()
    if not CheckExpiration() then return end
    pcall(function()
        local pc = slua_GameFrontendHUD:GetPlayerController()
        if not slua.isValid(pc) then return end
        local char = pc:GetPlayerCharacterSafety()
        if not slua.isValid(char) then return end
        local wm = char.WeaponManagerComponent
        if not slua.isValid(wm) then return end
        local weapon = wm.CurrentWeaponReplicated
        if not slua.isValid(weapon) then return end
        local entity = weapon.ShootWeaponEntityComp
        if not slua.isValid(entity) then return end

        entity.RecoilKickADS = 0
        entity.GameDeviationFactor = 0.01
        entity.GameDeviationAccuracy = 0.01
        
        if entity.AutoAimingConfig then
            for _, range in ipairs({"OuterRange", "InnerRange"}) do
                local cfg = entity.AutoAimingConfig[range]
                if cfg then
                    cfg.Speed = 4.5
                    cfg.RangeRate = 4.5
                    cfg.SpeedRate = 5
                    cfg.RangeRateSight = 4.5
                    cfg.SpeedRateSight = 5
                    cfg.CrouchRate = 4.5
                    cfg.ProneRate = 4.5
                    cfg.DyingRate = 0
                    cfg.adsorbMaxRange = 200
                    cfg.adsorbMinRange = 20
                    cfg.adsorbMinAttenuationDis = 100
                    cfg.adsorbMaxAttenuationDis = 8000
                    cfg.adsorbActiveMinRange = 20
                end
            end
            entity.AutoAimingConfig = entity.AutoAimingConfig
        end

        pcall(function()
            local aimComp = char.BP_AutoAimingComponent_C 
                         or char.BP_AutoAimingComponent 
                         or char.AutoAimingComponent
            if slua.isValid(aimComp) and aimComp.Bones then
                pcall(function() aimComp.Bones[0] = "spine_03" end)
                pcall(function() aimComp.Bones[1] = "spine_03" end)
                pcall(function() aimComp.Bones[2] = "spine_03" end)
                pcall(function() aimComp.Bones:Set(0, "spine_03") end)
                pcall(function() aimComp.Bones:Set(1, "spine_03") end)
                pcall(function() aimComp.Bones:Set(2, "spine_03") end)
            end
        end)
    end)
end



local TARGET_FOV = 110
local function ApplyIpadView(cameraComp)
    if _G._MOD_EXPIRED or _G.AK_GetVal("IPAD_VIEW") ~= 1 or not slua.isValid(cameraComp) then return end
    if math.abs(cameraComp.FieldOfView - TARGET_FOV) > 0.5 then
        cameraComp.FieldOfView = TARGET_FOV
    end
end

-- ============================================================================
-- ALL FEATURES AUTO-ON
-- ============================================================================
_G.AK_Features = {
    { id = "ESP_HP",         name = "ESP Health Bar",     val = 1, type = "toggle" },
    { id = "ESP_BOX",        name = "ESP Box",           val = 1, type = "toggle" },
    { id = "ESP_MAP",        name = "Mini Map ESP",     val = 1, type = "toggle" },
    { id = "AIMBOT",         name = "Aimbot",             val = 1, type = "toggle" },
    { id = "IPAD_VIEW",      name = "Ipad View",          val = 1, type = "toggle" },
    { id = "MAGIC_BULLET",   name = "Magic Bullet",       val = 1, type = "toggle" },
    { id = "WALLHACK",       name = "Wallhack",           val = 1, type = "toggle" },
    { id = "ANTHENA",        name = "Anthena (Big Hitbox)", val = 1, type = "toggle" },
    -- NO RECOIL toggle
    { id = "NO_RECOIL",      name = "No Recoil",          val = 1, type = "toggle" },
}

function _G.AK_GetVal(featureId)
    for _, feature in ipairs(_G.AK_Features) do
        if feature.id == featureId then return feature.val end
    end
    return 0
end

-- ============================================================================
-- DISTANCE MARKER SYSTEM (Mini Map ESP)
-- ============================================================================

local distanceMarkerConfig = {
    UIPathName = "/Game/Mod/EvoBase/BluePrints/UIBP/QuickSign/QuickSign_TipHitEnemy_UIBP_New.QuickSign_TipHitEnemy_UIBP_New_C",
    MaxWidgetNum = 99,
    MaxShowDistance = 6000000,
    bBindOutScreen = true,
    bBindBlocked = true,
    bIsBindingActor = true,
    BindSocketName = "head",
    bUseLuaWorldSocketName = true,
    WorldPositionOffset = FVector(0, 0, 50),
    bNeedPreLoad = true,
    Priority = 2
}

-- Global Cache Initialization
if not _G.AK_Active_Marks_Cache then
    _G.AK_Active_Marks_Cache = {}
end

-- ============================================================================
-- CORE FUNCTIONS
-- ============================================================================

local function InitDistanceMarkerSystem()
    pcall(function()
        if InGameMarkTools and InGameMarkTools.ScreenMarkManager and InGameMarkTools.ScreenMarkManager.OnInitMarkGroupData then
            InGameMarkTools.ScreenMarkManager:OnInitMarkGroupData(9999)
        end
        
        local gameplayTools = require("GameLua.Mod.BaseMod.Common.GamePlayTools")
        local screenMarkConfig = gameplayTools.GetCurrentConfig("ScreenMarkConfig")
        if screenMarkConfig then
            screenMarkConfig[9999] = distanceMarkerConfig
        end
        
        for moduleName, moduleData in pairs(package.loaded) do
            if type(moduleName) == "string" and string.find(moduleName, "ScreenMarkConfig") then
                if type(moduleData) == "table" then
                    moduleData[9999] = distanceMarkerConfig
                end
            end
        end
    end)
end

local function createDistanceMarker(enemy)
    if _G._MOD_EXPIRED then return end
    pcall(function()
        if InGameMarkTools and InGameMarkTools.ClientAddMapMark then
            enemy.NativeDistMark = InGameMarkTools.ClientAddMapMark(9999, FVector(0,0,0), 0, "", 4, enemy)
            _G.AK_Active_Marks_Cache[tostring(enemy)] = { actor = enemy, distMark = enemy.NativeDistMark }
        end
    end)
end

local function removeDistanceMarker(enemy)
    pcall(function()
        if InGameMarkTools then
            if InGameMarkTools.ClientRemoveMapMark then
                InGameMarkTools.ClientRemoveMapMark(enemy.NativeDistMark)
            elseif InGameMarkTools.HideMapMark then
                InGameMarkTools.HideMapMark(enemy.NativeDistMark)
            end
        end
        enemy.NativeDistMark = nil
        _G.AK_Active_Marks_Cache[tostring(enemy)] = nil
    end)
end

-- ============================================================================
-- CLEANUP & PROCESSORS
-- ============================================================================

local function cleanupDeadEnemyMarks()
    for cacheKey, cacheData in pairs(_G.AK_Active_Marks_Cache) do
        local shouldRemove = false
        
        if not slua.isValid(cacheData.actor) then
            shouldRemove = true
        else
            pcall(function()
                local actor = cacheData.actor
                
                -- 1. Cek visual/visibilitas
                if actor.bHidden or (actor.Mesh and actor.Mesh.bHidden) then
                    shouldRemove = true
                end
                
                -- 2. Cek flag kematian bawaan
                if type(actor.IsDead) == "function" and actor:IsDead() then
                    shouldRemove = true
                elseif actor.bIsDead == true or actor.bIsDeadFlag == true then
                    shouldRemove = true
                end

                -- 3. Cek sisa darah (HP)
                if type(actor.GetHealth) == "function" and actor:GetHealth() <= 0 then
                    shouldRemove = true
                elseif actor.Health and actor.Health <= 0 then
                    shouldRemove = true
                end

                -- 4. Cek pergantian class ke Peti Looting (Crate/Box)
                local className = actor:GetClass() and actor:GetClass():GetName()
                if className and (string.find(className, "Box") or string.find(className, "Crate") or string.find(className, "Dead")) then
                    shouldRemove = true
                end
            end)
        end
        
        -- Eksekusi penghapusan jika terindikasi mati/menjadi peti
        if shouldRemove then
            pcall(function()
                if InGameMarkTools then
                    if InGameMarkTools.ClientRemoveMapMark then
                        InGameMarkTools.ClientRemoveMapMark(cacheData.distMark)
                    elseif InGameMarkTools.HideMapMark then
                        InGameMarkTools.HideMapMark(cacheData.distMark)
                    end
                end
            end)
            _G.AK_Active_Marks_Cache[cacheKey] = nil
        end
    end
end

local function processEnemyMapESP(enemy, localPlayer, isMapESPEnabled)
    if _G._MOD_EXPIRED then return end
    if not slua.isValid(enemy) or enemy == localPlayer or enemy.TeamID == localPlayer.TeamID then return end

    local isDead = false
    pcall(function()
        if type(enemy.IsDead) == "function" then 
            isDead = enemy:IsDead()
        elseif enemy.bIsDead then 
            isDead = true 
        end
        
        if enemy.bHidden or (enemy.Mesh and enemy.Mesh.bHidden) then 
            isDead = true 
        end
        
        if type(enemy.GetHealth) == "function" and enemy:GetHealth() <= 0 then
            isDead = true
        end
    end)

    if not isDead and isMapESPEnabled == 1 then
        if not enemy.bHasAKNativeMapMarker then
            createDistanceMarker(enemy)
            enemy.bHasAKNativeMapMarker = true
        end
    else
        if enemy.bHasAKNativeMapMarker then
            removeDistanceMarker(enemy)
            enemy.bHasAKNativeMapMarker = false
        end
    end
end


-- ============================================================================
-- BRPLAYERCHARACTERBASE CLASS
-- ============================================================================
local BRPlayerCharacterBase = {
    ServerRPC = {},
    ClientRPC = {},
    MulticastRPC = {}
}

BRPlayerCharacterBase.ServerRPC.ServerRPC_NearDeathGiveupRescue = { Reliable = true, Params = {} }
BRPlayerCharacterBase.ServerRPC.ServerRPC_CarryDeadBox = { Reliable = true, Params = { UEnums.EPropertyClass.Object } }
BRPlayerCharacterBase.ServerRPC.RPC_Server_GmPlayAction = { Reliable = true, Params = { UEnums.EPropertyClass.Int } }
BRPlayerCharacterBase.MulticastRPC.MulticastRPC_GmPlayAction = { Reliable = true, Params = { UEnums.EPropertyClass.Int } }
BRPlayerCharacterBase.ClientRPC.RPC_Client_SetShouldCheckPassWall = { Reliable = true, Params = { UEnums.EPropertyClass.Bool } }

function BRPlayerCharacterBase:ctor()
    self.bHasShownDevNotice = false
    self.AK_NativeESP_Ready = false
end

function BRPlayerCharacterBase:_PostConstruct()
    BRPlayerCharacterBase.__super._PostConstruct(self)
    self:InitAddSpecialMoveInfo()
    self.bCanNearDeathGiveup = true
    self:StartAdvancedSystems()
end

function BRPlayerCharacterBase:ReceiveBeginPlay()
    BRPlayerCharacterBase.__super.ReceiveBeginPlay(self)
    if slua.isValid(self.STCharacterMovement) then
        self.STCharacterMovement.bPositiveBlowUp = true
    end
    if Client then
        GameplayData.AddCharacter(self.Object)
    end
    EventSystem:postEvent(EVENTTYPE_SINGLETRAINING, EVENTID_CHARACTER_BEGINPLAY, self.Object)
end

function BRPlayerCharacterBase:ReceiveEndPlay(EndPlayReason)
    BRPlayerCharacterBase.__super.ReceiveEndPlay(self, EndPlayReason)
    if Client then
        GameplayData.RemoveCharacter(self.Object)
    end
end

function BRPlayerCharacterBase:OnPlayerEnterCarryBoxState()
    self.Super:OnPlayerEnterCarryBoxState()
    if self.CarryDeadBoxFeature then
        self.CarryDeadBoxFeature:OnPlayerEnterCarryBoxState()
    end
end

function BRPlayerCharacterBase:OnPlayerLeaveCarryBoxState(bInIsInterrupt)
    self.Super:OnPlayerLeaveCarryBoxState(bInIsInterrupt)
    if self.CarryDeadBoxFeature then
        self.CarryDeadBoxFeature:OnPlayerLeaveCarryBoxState(bInIsInterrupt)
    end
end

function BRPlayerCharacterBase:ServerRPC_CarryDeadBox(uInDeadBox)
    if slua.isValid(uInDeadBox) and Game:IsClassOf(uInDeadBox, import("/Script/ShadowTrackerExtra.PlayerTombBox")) and self.CarryDeadBoxFeature then
        self.CarryDeadBoxFeature:CarryDeadBox(uInDeadBox)
    end
end

function BRPlayerCharacterBase:ServerRPC_NearDeathGiveupRescue()
    local uNearDeathComp = self.NearDeatchComponent
    if self:IsNearDeath() and slua.isValid(uNearDeathComp) and self.bCanNearDeathGiveup == true then
        uNearDeathComp:TriggerGotoDieExplictly(self.Object)
    end
end

function BRPlayerCharacterBase:SwitchWeaponCheck(Slot, IgnoreState)
    return self.Super:SwitchWeaponCheck(Slot, IgnoreState)
end

function BRPlayerCharacterBase:HandleOnAttachedToVehicle(uVehicle) end
function BRPlayerCharacterBase:HandleOnDetachedFromVehicle(uLastVehicle) end
function BRPlayerCharacterBase:ClearAttachToVehicleTimer() end

-- ============================================================================
-- NO RECOIL (AIM ASSIST)
-- ============================================================================
function BRPlayerCharacterBase:AimAssist()
  pcall(function()
    local weaponManager = self.WeaponManagerComponent
    if not weaponManager then return end

    local currentWeapon = weaponManager.CurrentWeaponReplicated
    if not currentWeapon then return end

    local shootComp = currentWeapon.ShootWeaponEntityComp
    if not shootComp then return end

    -- Recoil top level
    shootComp.RecoilKick = 0
    shootComp.RecoilKickADS = 0

    -- Properti tambahan (antisipasi)
    shootComp.VRecoil = 0
    shootComp.HRecoil = 0

    -- Accessories recoil factors (dari struktur dan tambahan)
    

    -- RecoilInfo struct (semua komponen V/H di-nol-kan)
    if shootComp.RecoilInfo then
      shootComp.RecoilInfo.VerticalRecoilMin = 0
      shootComp.RecoilInfo.VerticalRecoilMax = 0
      shootComp.RecoilInfo.RecoilSpeedVertical = 0
      shootComp.RecoilInfo.RecoilSpeedHorizontal = 0
      shootComp.RecoilInfo.VerticalRecoveryMax = 0
      shootComp.RecoilInfo.RecoilModifierStand = 0
      shootComp.RecoilInfo.RecoilModifierCrouch = 0
      shootComp.RecoilInfo.RecoilModifierProne = 0
      shootComp.AccessoriesRecoveryFactor = 0.20
      shootComp.AccessoriesVRecoilFactor = 0.35
      shootComp.AccessoriesHRecoilFactor = 0.35
    end
  end)
end

-- ============================================================================
-- MAIN ADVANCED SYSTEMS (ESP + AIMBOT + WALLHACK + ANTHENA + NO RECOIL)
-- ============================================================================
function BRPlayerCharacterBase:StartAdvancedSystems()
    if not Client then return end
    
    if not CheckExpiration() then
        if _SYSTEM_TAMPER_DETECTED then
            ShowAntiCrackPopup("tamper")
        else
            ShowExpirePopup()
        end
        return
    end

    InitDistanceMarkerSystem()
    self:AddGameTimer(2.0, true, function()
        if not slua.isValid(self.Object) then return end
        if CheckExpiration() and _G.AK_GetVal("MAGIC_BULLET") == 1 then
            ApplyMagicBullet()                      
        end
    end)

    InitDistanceMarkerSystem()
    self:AddGameTimer(0.1, true, function()
        if not slua.isValid(self.Object) then return end
        
        if not CheckExpiration() then
            if _SYSTEM_TAMPER_DETECTED then
                ShowAntiCrackPopup("tamper")
            else
                ShowExpirePopup()
            end
            return
        end

        ApplyIpadView(self.Object.ThirdPersonCameraComponent)
        
        local localPlayer = GameplayData.GetPlayerCharacter()
        if not slua.isValid(localPlayer) then return end

        if _G.AK_GetVal("AIMBOT") == 1 then
            ApplyHardAimbot()
        end

        -- ============================================
        -- NO RECOIL (panggil fungsi AimAssist)
        -- ============================================
        if _G.AK_GetVal("NO_RECOIL") == 1 then
            self:AimAssist()
        end

        if self.Object == localPlayer and not self.bHasShownDevNotice then
            if self.Object.IsAlive and self.Object:IsAlive() then
                self.bHasShownDevNotice = true
            end
        end

        if self.Object == localPlayer then
            if not _G.AKModTickCount then _G.AKModTickCount = 0 end
            _G.AKModTickCount = _G.AKModTickCount + 1

            cleanupDeadEnemyMarks()

            if not self.AK_NativeESP_Ready then
                pcall(function()
                    local gameplayTools = require("GameLua.Mod.BaseMod.Common.GamePlayTools")
                    local screenMarkConfig = gameplayTools.GetCurrentConfig("ScreenMarkConfig")
                    if screenMarkConfig then
                        if screenMarkConfig[1006] then
                            screenMarkConfig[1006].bBindBlocked = true
                            screenMarkConfig[1006].bBindOutScreen = true
                            screenMarkConfig[1006].MaxWidgetNum = 99
                            screenMarkConfig[1006].MaxShowDistance = 6000000
                            screenMarkConfig[1006].BindSocketName = "root"
                        end
                        if not screenMarkConfig[9999] then
                            screenMarkConfig[9999] = distanceMarkerConfig
                        end
                    end
                end)
                self.AK_NativeESP_Ready = true
            end

            local enemyCharacters = {}
            if GameplayData.GetAllPlayerCharacters then
                enemyCharacters = GameplayData.GetAllPlayerCharacters()
            elseif GameplayData.GameCharacters then
                for _, char in pairs(GameplayData.GameCharacters) do
                    table.insert(enemyCharacters, char)
                end
            end

            local isMapESPEnabled = _G.AK_GetVal("ESP_MAP")
            local isWallhackEnabled = _G.AK_GetVal("WALLHACK")
            local isAnthenaEnabled = _G.AK_GetVal("ANTHENA")

            for _, enemy in pairs(enemyCharacters) do
                if slua.isValid(enemy) and enemy ~= localPlayer and enemy.TeamID ~= localPlayer.TeamID then
                    local isDead = false
                    pcall(function()
                        if type(enemy.IsDead) == "function" then isDead = enemy:IsDead()
                        elseif enemy.bIsDead then isDead = true end
                        if enemy.bHidden or (enemy.Mesh and enemy.Mesh.bHidden) then isDead = true end
                    end)

                    if not isDead then
                        processEnemyMapESP(enemy, localPlayer, isMapESPEnabled)

                        -- Apply Wallhack
                        if isWallhackEnabled == 1 then
                            local pc = slua_GameFrontendHUD:GetPlayerController()
                            if slua.isValid(pc) then
                                ApplyVisualMods(localPlayer, enemy, pc, isWallhackEnabled == 1, false)
                            end
                        end

                        -- Apply Anthena (Big Hitbox)
                        if isAnthenaEnabled == 1 then
                            _G.Anthena(enemy)
                        end

                        -- ESP Health Bar
                        if _G.AK_GetVal("ESP_HP") == 1 then
                            if not enemy.bHasAKNativeHPBar then
                                pcall(function()
                                    if InGameMarkTools and InGameMarkTools.ClientAddMapMark then
                                        enemy.NativeHPBarMark = InGameMarkTools.ClientAddMapMark(1006, FVector(0,0,0), 0, "", 4, enemy)
                                        enemy.bHasAKNativeHPBar = true
                                    end
                                end)
                            end
                        else
                            if enemy.bHasAKNativeHPBar and InGameMarkTools then
                                pcall(function()
                                    if InGameMarkTools.ClientRemoveMapMark then
                                        InGameMarkTools.ClientRemoveMapMark(enemy.NativeHPBarMark)
                                    end
                                end)
                                enemy.NativeHPBarMark = nil
                                enemy.bHasAKNativeHPBar = false
                            end
                        end

                        -- ESP Box
                        if _G.AK_GetVal("ESP_BOX") == 1 then
                            pcall(function()
                                if enemy.Replay_IsEnemyFrameUIExisted then
                                    if not enemy:Replay_IsEnemyFrameUIExisted() then
                                        enemy:Replay_CreateEnemyFrameUI(true, true)
                                    end
                                    if enemy.Replay_SetVisiableOfFrameUI then
                                        enemy:Replay_SetVisiableOfFrameUI(true)
                                    end
                                end
                            end)
                        else
                            pcall(function()
                                if enemy.Replay_SetVisiableOfFrameUI then
                                    enemy:Replay_SetVisiableOfFrameUI(false)
                                end
                            end)
                        end
                    end
                end
            end
        end
    end)
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================
local require = require
local import = import
local isValid = slua.isValid

local function nop() return true end
local function retTrue() return true end
local function retFalse() return false end
local function retZero() return 0 end
local function retEmpty() return {} end
local function retEmptyString() return "" end

local function safe_require(path)
    local ok, mod = pcall(require, path)
    return ok and mod or nil
end

local ok_gd, GameplayData = pcall(require, "GameLua.GameCore.Data.GameplayData")
if not ok_gd then GameplayData = nil end

-- ============================================================================
-- 1. SLUA BYPASS
-- ============================================================================
local function InitializeSLUABypass()
    pcall(function()
        if slua and slua.getSignature then
            slua.getSignature = function() return 0xDEADBEEF end
        end
        local loader = package.loaded["slua.loader"] or rawget(_G, "slua_loader")
        if loader then
            loader.verifyBytecode = retTrue
            loader.checkIntegrity = retTrue
            if loader.disableSignatureCheck then loader.disableSignatureCheck = retTrue end
        end
        local slua_serialize = package.loaded["slua.serialize"]
        if slua_serialize then
            slua_serialize.check = retTrue
            slua_serialize.verify = retTrue
        end
        if jit and jit.attach then
            jit.attach(function() end, "bc")
        end
        if _G.slua_verify then _G.slua_verify = retTrue end
        if _G.check_slua_integrity then _G.check_slua_integrity = retTrue end
    end)
end

-- ============================================================================
-- 2. MD5 & SIGNATURE BYPASS
-- ============================================================================
local function InitializeMD5Bypass()
    pcall(function()
        local console = import("KismetSystemLibrary")
        if console then
            console.ExecuteConsoleCommand(nil, "pak.DisablePakSignatureCheck 1")
            console.ExecuteConsoleCommand(nil, "pakchunk.EnableSignatureCheck 0")
            console.ExecuteConsoleCommand(nil, "s.VerifyPak 0")
            console.ExecuteConsoleCommand(nil, "sig.Check 0")
            console.ExecuteConsoleCommand(nil, "security.DisableChecks 1")
        end
        
        local CreativeModeBlueprintLibrary = import("CreativeModeBlueprintLibrary")
        if CreativeModeBlueprintLibrary then
            CreativeModeBlueprintLibrary.MD5HashByteArray = function() return "00000000000000000000000000000000" end
            CreativeModeBlueprintLibrary.MD5HashFile = function() return "00000000000000000000000000000000" end
            CreativeModeBlueprintLibrary.GetContentDiffData = function() return true, "BYPASSED" end
            CreativeModeBlueprintLibrary.VerifyFileIntegrity = retTrue
        end
        
        if _G.MD5Hash then _G.MD5Hash = function() return "00000000000000000000000000000000" end end
        if _G.CRC32 then _G.CRC32 = function() return 0 end end
        if _G.SHA1 then _G.SHA1 = function() return "BYPASS" end end
        
        local FileHashChecker = package.loaded["common.file_hash_checker"]
        if FileHashChecker then
            FileHashChecker.CheckFileMD5 = retTrue
            FileHashChecker.VerifyAll = retTrue
            FileHashChecker.GetHash = function() return "BYPASS" end
        end
        
        local TssSdk = package.loaded["TssSdk"] or _G.TssSdk
        if TssSdk then
            TssSdk.GetFileMD5 = function() return "BYPASS" end
            TssSdk.VerifyFileSignature = retTrue
        end
        
        local STExtraBlueprintFunctionLibrary = import("STExtraBlueprintFunctionLibrary")
        if STExtraBlueprintFunctionLibrary then
            STExtraBlueprintFunctionLibrary.CheckMD5 = retTrue
            STExtraBlueprintFunctionLibrary.GetMD5 = function() return "BYPASS" end
            STExtraBlueprintFunctionLibrary.VerifyFile = retTrue
        end
    end)
end

-- ============================================================================
-- 3. SKIN & AVATAR BYPASS
-- ============================================================================
local function InitializeSkinBypass()
    pcall(function()
        local puffer_tlog = package.loaded["client.slua.logic.download.report.puffer_tlog"]
        if puffer_tlog then
            puffer_tlog.ReportEvent = nop
            puffer_tlog.ReportDownloadResult = nop
            puffer_tlog.ReportODPTDError = nop
            puffer_tlog.ReportSkinError = nop
        end
        
        local AvatarUtils = package.loaded["AvatarUtils"]
        if AvatarUtils then
            AvatarUtils.CheckIsWeaponInBlackList = retFalse
            AvatarUtils.IsValidAvatar = retTrue
            AvatarUtils.CheckAvatarIntegrity = retTrue
            AvatarUtils.ReportInvalidAvatar = nop
        end
        
        local SubsystemMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        local fileCheckSubsystem = SubsystemMgr and SubsystemMgr:Get("FileCheckSubsystem")
        if fileCheckSubsystem then
            fileCheckSubsystem.StartCheck = nop
            fileCheckSubsystem.ReportAbnormalFile = nop
            fileCheckSubsystem.StopCheck = nop
        end
        
        local equipmentException = package.loaded["client.slua.logic.report.EquipmentExceptionReport"]
        if equipmentException then
            equipmentException.Report = nop
            equipmentException.SendException = nop
        end
    end)
end

-- ============================================================================
-- 4. LOG BLOCKER - ENHANCED
-- ============================================================================
local function InitializeLogBlocker()
    pcall(function()
        local ScreenshotMTDer = import("ScreenshotMTDer")
        if ScreenshotMTDer then
            ScreenshotMTDer.MTDePicture = function() return "" end
            ScreenshotMTDer.ReMTDePicture = function() return "" end
            ScreenshotMTDer.HasCaptured = retTrue
            ScreenshotMTDer.TakeScreenshot = nop
        end
        
        local TLog = package.loaded["TLog"] or _G.TLog
        if TLog then
            TLog.Info = nop; TLog.Warning = nop; TLog.Error = nop
            TLog.Debug = nop; TLog.Report = nop; TLog.Send = nop
            TLog.Flush = nop
        end
        
        local CrashSight = package.loaded["CrashSight"] or _G.CrashSight
        if CrashSight then
            CrashSight.ReportException = nop
            CrashSight.SetCustomData = nop
            CrashSight.Log = nop
            CrashSight.SendCrash = nop
            CrashSight.ReportUserException = nop
        end
        
        local GameReportUtils = package.loaded["GameLua.Mod.BaseMod.GamePlay.GameReport.GameReportUtils"]
        if GameReportUtils then
            GameReportUtils.BugglyPostExceptionFull = retFalse
            GameReportUtils.CheckCanBugglyPostException = retFalse
            GameReportUtils.ReplayReportData = nop
            GameReportUtils.ReportGameException = nop
            GameReportUtils.PostException = nop
        end
        
        local ClientToolsReport = package.loaded["client.slua.logic.report.ClientToolsReport"]
        if ClientToolsReport then
            ClientToolsReport.SendReport = nop
            ClientToolsReport.SendException = nop
            ClientToolsReport.UploadLog = nop
        end
        
        local TLogReportUtils = package.loaded["client.slua.config.tlog.tlog_report_utils"]
        if TLogReportUtils then
            TLogReportUtils.ReportTLogEvent = nop
            TLogReportUtils.FlushEvents = nop
        end
        
        for _, sdk in ipairs({"Firebase", "Adjust", "AppsFlyer", "FacebookAnalytics", "GameAnalytics"}) do
            local s = _G[sdk]
            if s then
                s.logEvent = nop; s.trackEvent = nop; s.setEnabled = retFalse
                s.sendEvent = nop; s.report = nop
            end
        end
    end)
end

-- ============================================================================
-- 5. SCANNER & VERIFICATION BLOCKER
-- ============================================================================
local function InitializeScannerBlocker()
    pcall(function()
        local SubsystemMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if SubsystemMgr then
            local subsystems = {
                "AFKReportorSubsystem", "ClientDataStatistcsSubsystem", "AvatarExceptionSubsystem",
                "ShootVerifySubSystemClient", "MemoryCheckSubsystem", "SpeedCheckSubsystem",
                "WallCheckSubsystem", "FileCheckSubsystem", "BehaviorScoreSubsystem"
            }
            
            for _, name in ipairs(subsystems) do
                local sub = SubsystemMgr:Get(name)
                if sub then
                    for k, v in pairs(sub) do
                        if type(v) == "function" and (
                            k:find("Report") or k:find("Send") or k:find("Upload") or 
                            k:find("Verify") or k:find("Check") or k:find("Validate") or
                            k:find("Scan") or k:find("Detect")
                        ) then
                            pcall(function() sub[k] = nop end)
                        end
                    end
                    if sub.ReportPingDelayTimer then
                        sub:RemoveGameTimer(sub.ReportPingDelayTimer)
                        sub.ReportPingDelayTimer = nil
                    end
                    sub.DelayCount = 0
                end
            end
        end
        
        local AvatarExceptionPlayerInst = package.loaded["GameLua.Mod.Library.GamePlay.Avatar.Exception.AvatarExceptionPlayerInst"]
        if AvatarExceptionPlayerInst then
            AvatarExceptionPlayerInst.CheckAvatarException = nop
            AvatarExceptionPlayerInst.CheckAvatarExceptionOnce = nop
            AvatarExceptionPlayerInst.ReportAvatarException = nop
            AvatarExceptionPlayerInst.CheckSlotMeshVisible = retFalse
            AvatarExceptionPlayerInst.CheckPawnVisible = retFalse
            AvatarExceptionPlayerInst.CheckCanBugglyPostException = retFalse
        end
        
        local TssSdk = package.loaded["TssSdk"] or _G.TssSdk
        if TssSdk then
            local originalOnRecvData = TssSdk.OnRecvData
            TssSdk.OnRecvData = function(data)
                if type(data) == "string" and (
                    string.find(data, "report") or string.find(data, "exception") or
                    string.find(data, "cheat") or string.find(data, "violation") or
                    string.find(data, "hack") or string.find(data, "verify")
                ) then
                    return
                end
                if originalOnRecvData then originalOnRecvData(data) end
            end
            TssSdk.SendReportInfo = nop
            TssSdk.ScanMemory = retTrue
            TssSdk.IsEmulator = retFalse
            TssSdk.GetTssSdkReportInfo = retEmptyString
            TssSdk.CheckEnvironment = retTrue
            TssSdk.VerifyProcess = retTrue
        end
    end)
end

-- ============================================================================
-- 6. REPLAY TELEMETRY BLOCKER
-- ============================================================================
local function InitializeReplayTelemetryBlocker()
    pcall(function()
        local SubsystemMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if SubsystemMgr then
            local replaySystems = {
                "RescueBtnReplayTraceSubsystem", "GameReportSubsystem", "ReplaySubsystem"
            }
            for _, name in ipairs(replaySystems) do
                local sub = SubsystemMgr:Get(name)
                if sub then
                    for k, v in pairs(sub) do
                        if type(v) == "function" and (
                            k:find("Report") or k:find("Trace") or k:find("Replay") or
                            k:find("Record") or k:find("Save")
                        ) then
                            pcall(function() sub[k] = nop end)
                        end
                    end
                end
            end
        end
        
        local logic_report_replay = package.loaded["client.slua.logic.replay.logic_report_replay"]
        if logic_report_replay then
            logic_report_replay.ReportReplay = nop
            logic_report_replay.SendReportReq = nop
            logic_report_replay.UploadReplay = nop
        end
    end)
end

-- ============================================================================
-- 7. REPORT FLOW BLOCKER - ENHANCED (ALL FLOW TYPES)
-- ============================================================================
local function InitializeReportFlowBlocker()
    pcall(function()
        local reportFlows = {
            "ReportAimFlow", "ReportHitFlow", "ReportAttackFlow", "ReportSecAttackFlow",
            "ReportHurtFlow", "ReportFireArms", "ReportVerifyInfoFlow", "ReportMrpcsFlow",
            "ReportPlayerBehavior", "ReportTeammatHurt", "ReportMisKillByTeammate",
            "ReportForbitPick", "ReportPlayerMoveRoute", "ReportPlayerPosition",
            "ReportVehicleMoveFlow", "ReportSecTgameMovingFlow", "ReportParachuteData",
            "ReportEquipmentFlow", "ReportPlayersPing", "ReportPlayerIP",
            "ReportPlayerFramePingRecord", "ReportDSNetSaturation", "ReportNetContinuousSaturate",
            "ReportDSNetRate", "ReportCircleFlow", "ReportPlayerKillFlow",
            "ReportMrpcsFlow", "ReportSecMrpcsFlow"
        }
        
        for _, funcName in ipairs(reportFlows) do
            if _G[funcName] then _G[funcName] = nop end
            if _G.GameplayCallbacks and _G.GameplayCallbacks[funcName] then
                _G.GameplayCallbacks[funcName] = nop
            end
        end
        
        local checkFuncs = {"CheckReportSecAttackFlowWithAttackFlow", "CheckReportSecAttackFlow"}
        for _, funcName in ipairs(checkFuncs) do
            if _G[funcName] then _G[funcName] = retFalse end
            if _G.GameplayCallbacks and _G.GameplayCallbacks[funcName] then
                _G.GameplayCallbacks[funcName] = retFalse
            end
        end
        
        local enableFlags = {
            "IsEnableReportPlayerKillFlow", "IsEnableReportMrpcsInCircleFlow",
            "IsEnableReportMrpcsInPartCircleFlow", "IsEnableReportMrpcsFlow",
            "IsEnableReportAttackFlow", "IsEnableReportHitFlow", "IsEnableReportCircleFlow"
        }
        for _, flag in ipairs(enableFlags) do
            if _G[flag] then _G[flag] = retFalse end
        end
    end)
end

-- ============================================================================
-- 8. PLAYER SECURITY COLLECTOR BYPASS
-- ============================================================================
local function InitializePlayerSecurityBypass()
    pcall(function()
        local securityCollectors = {
            "PlayerSecurityInfoCollector", "PlayerSecurityInfo", "SecurityInfoCollector",
            "ClientSecurityCollector", "PlayerAntiCheatCollector"
        }
        
        for _, collector in ipairs(securityCollectors) do
            if _G[collector] then
                for k, v in pairs(_G[collector]) do
                    if type(v) == "function" and (
                        k:find("Report") or k:find("Collect") or k:find("Send") or
                        k:find("Upload") or k:find("Record")
                    ) then
                        _G[collector][k] = nop
                    end
                end
            end
        end
        
        local SecuritySubsystem = require("GameLua.Mod.BaseMod.Common.Security.PlayerSecurityInfoSubsystem")
        if SecuritySubsystem then
            SecuritySubsystem.ReportData = nop
            SecuritySubsystem.CheckCheat = retFalse
            SecuritySubsystem.ValidatePlayer = retTrue
            SecuritySubsystem.CollectData = nop
            SecuritySubsystem.SendToServer = nop
        end
        
        if _G.PlayerSecurityInfo then
            _G.PlayerSecurityInfo.ReportCheat = nop
            _G.PlayerSecurityInfo.ReportSuspicious = nop
            _G.PlayerSecurityInfo.SendSecurityData = nop
            _G.PlayerSecurityInfo.CollectSecurityInfo = nop
        end
    end)
end

-- ============================================================================
-- 9. CLIENT FLOW BYPASS (MRPCS, KILL FLOW, CIRCLE FLOW)
-- ============================================================================
local function InitializeClientFlowBypass()
    pcall(function()
        local flowSubsystems = {
            "ClientSecMrpcsFlow", "MrpcsFlow", "MrpcsData", "ClientCircleFlowSubsystem",
            "ClientKillFlowSubsystem", "ClientSecPlayerKillFlow"
        }
        
        for _, name in ipairs(flowSubsystems) do
            local sub = package.loaded[name] or _G[name]
            if sub then
                for k, v in pairs(sub) do
                    if type(v) == "function" and (
                        k:find("Report") or k:find("Send") or k:find("Flow") or
                        k:find("Record") or k:find("Process")
                    ) then
                        pcall(function() sub[k] = nop end)
                    end
                end
            end
        end
        
        local CircleFlow = require("GameLua.Mod.BaseMod.Client.Security.ClientCircleFlowSubsystem")
        if CircleFlow then
            CircleFlow.ReportCircleFlow = nop
            CircleFlow.SendCircleData = nop
            CircleFlow.ReportPlayerPosition = nop
            CircleFlow.ReportCircleData = nop
        end
        
        if _G.ReportPlayerKillFlow then _G.ReportPlayerKillFlow = nop end
        if _G.ClientSecPlayerKillFlow then _G.ClientSecPlayerKillFlow = nop end
    end)
end

-- ============================================================================
-- 10. HEARTBEAT BYPASS
-- ============================================================================
local function InitializeHeartbeatBypass()
    pcall(function()
        local heartbeatFuncs = {"Heartbeat", "SendHeartbeat", "ClientHeartbeat", "ServerHeartbeat"}
        for _, func in ipairs(heartbeatFuncs) do
            if _G[func] then _G[func] = nop end
            if _G.GameplayCallbacks and _G.GameplayCallbacks[func] then
                _G.GameplayCallbacks[func] = nop
            end
        end
        
        local SubsystemMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if SubsystemMgr then
            local heartbeatSub = SubsystemMgr:Get("HeartbeatSubsystem")
            if heartbeatSub then
                if heartbeatSub.timer then heartbeatSub:RemoveGameTimer(heartbeatSub.timer) end
                heartbeatSub.SendHeartbeat = nop
                heartbeatSub.StartHeartbeat = nop
            end
        end
    end)
end

-- ============================================================================
-- 12. CORONALAB BYPASS
-- ============================================================================
local function InitializeCoronaLabBypass()
    pcall(function()
        if _G.CoronaLab then
            _G.CoronaLab.ReportData = nop
            _G.CoronaLab.SendData = nop
            _G.CoronaLab.CollectData = nop
            _G.CoronaLab.Telemetry = nop
        end
        
        local SubsystemMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if SubsystemMgr then
            local corona = SubsystemMgr:Get("CoronaLabSubsystem")
            if corona then
                corona.ReportData = nop
                corona.SendToServer = nop
                corona.CollectTelemetry = nop
                corona.StopCollection = nop
            end
        end
    end)
end

-- ============================================================================
-- 13. MODIFIER EXCEPTION BYPASS
-- ============================================================================
local function InitializeModifierExceptionBypass()
    pcall(function()
        if _G.bReportedModifierException then
            _G.bReportedModifierException = false
        end
        
        local ModifierSubsystem = require("GameLua.Mod.BaseMod.Common.Security.ModifierExceptionSubsystem")
        if ModifierSubsystem then
            ModifierSubsystem.ReportException = nop
            ModifierSubsystem.CheckModifier = retTrue
            ModifierSubsystem.ValidateModifier = retTrue
            ModifierSubsystem.ReportModifierError = nop
        end
    end)
end

-- ============================================================================
-- 14. SIMULATE CHARACTER LOCATION BYPASS
-- ============================================================================
local function InitializeSimulateCharacterLocationBypass()
    pcall(function()
        local SimulateSubsystem = require("GameLua.Mod.BaseMod.Gameplay.Simulate.SimulateCharacterSubsystem")
        if SimulateSubsystem then
            SimulateSubsystem.ReportLocation = nop
            SimulateSubsystem.SendLocationData = nop
            SimulateSubsystem.VerifyLocation = retTrue
        end
    end)
end

-- ============================================================================
-- 15. SHOOT VERIFICATION BYPASS
-- ============================================================================
local function InitializeShootVerificationBypass()
    pcall(function()
        local ShootVerify = require("GameLua.Dev.Subsystem.ShootVerifySubSystemClient")
        if ShootVerify then
            ShootVerify.OnShootVerifyFailed = nop
            ShootVerify.SendVerifyData = nop
            ShootVerify.ReportBulletHit = nop
            ShootVerify.UploadHitInfo = nop
            ShootVerify.VerifyShot = retTrue
        end
        
        if _G.BulletHitInfoUploadData then
            _G.BulletHitInfoUploadData.Report = nop
            _G.BulletHitInfoUploadData.Send = nop
            _G.BulletHitInfoUploadData.Upload = nop
        end
    end)
end

-- ============================================================================
-- 16. COMPLETE NETWORK PACKET BLOCK - ENHANCED
-- ============================================================================
local function InitializeNetworkPacketBlock()
    pcall(function()
        if NetUtil and NetUtil.SendPacket then
            local originalSend = NetUtil.SendPacket
            local blockedPackets = {
                ["ReportAttackFlow"] = 1, ["ReportSecAttackFlow"] = 1, ["ReportHurtFlow"] = 1,
                ["ReportFireArms"] = 1, ["ReportVerifyInfoFlow"] = 1, ["ReportMrpcsFlow"] = 1,
                ["ReportPlayerBehavior"] = 1, ["ReportTeammatHurt"] = 1, ["ReportPlayerMoveRoute"] = 1,
                ["ReportPlayerPosition"] = 1, ["ReportSecVehicleMoveFlow"] = 1, ["report_parachute_data"] = 1,
                ["on_tss_sdk_anti_data"] = 1, ["ReportAimFlow"] = 1, ["ReportHitFlow"] = 1,
                ["ReportCircleFlow"] = 1, ["report_players_ping"] = 1, ["report_player_ip"] = 1,
                ["report_net_saturate"] = 1, ["report_speed_hack"] = 1, ["report_wall_hack"] = 1,
                ["report_aim_bot"] = 1, ["report_esp_usage"] = 1, ["report_modded_files"] = 1,
                ["detect_cheat"] = 1, ["ban_player"] = 1, ["client_anti_cheat_report"] = 1,
                ["ReportPlayerKillFlow"] = 1, ["ClientSecPlayerKillFlow"] = 1,
                ["ReportMrpcsFlow"] = 1, ["ClientSecMrpcsFlow"] = 1, ["MrpcsData"] = 1,
                ["CheckReportSecAttackFlow"] = 1, ["CheckReportSecAttackFlowWithAttackFlow"] = 1,
                ["RPC_ClientCoronaLab"] = 1, ["CoronaLabReport"] = 1, ["CoronaLabData"] = 1,
                ["PlayerSecurityInfo"] = 1, ["ReportSecurityInfo"] = 1, ["SendSecurityData"] = 1,
                ["ClientCircleFlow"] = 1, ["IsEnableReportPlayerKillFlow"] = 1,
                ["IsEnableReportMrpcsInCircleFlow"] = 1, ["IsEnableReportMrpcsInPartCircleFlow"] = 1,
                ["bReportedModifierException"] = 1, ["ReportModifierException"] = 1,
                ["RPC_Server_ReportSimulateCharacterLocation"] = 1, ["ReportSimulateCharacterLocation"] = 1,
                ["RPC_Client_ShootVertifyRes"] = 1, ["BulletHitInfoUploadData"] = 1,
                ["ShootVerifyFailed"] = 1, ["report_unrealnet_exception"] = 1, ["tss_sdk_report"] = 1,
                ["Heartbeat"] = 1, ["ClientHeartbeat"] = 1, ["ServerHeartbeat"] = 1,
                ["SwiftHawk"] = 1, ["ClientSwiftHawk"] = 1, ["ClientSwiftHawkWithParams"] = 1,
                ["SwiftHawkReport"] = 1, ["SwiftHawkData"] = 1,
                ["AntiCheatReport"] = 1, ["CheatDetection"] = 1, ["ViolationReport"] = 1,
                ["SecurityViolation"] = 1, ["IntegrityCheck"] = 1, ["SignatureVerify"] = 1
            }
            
            NetUtil.SendPacket = function(packetName, ...)
                if blockedPackets[packetName] then
                    return nil
                end
                return originalSend(packetName, ...)
            end
            NetUtil.IsBypassed = true
        end
        
        if _G.SendRPC then
            local originalSendRPC = _G.SendRPC
            local blockedRPCs = {
                "RPC_Server_ReportPlayerKillFlow", "RPC_Server_ClientSecMrpcsFlow",
                "RPC_Server_Heartbeat", "RPC_Server_SwiftHawk", "RPC_Server_ClientSwiftHawkWithParams",
                "RPC_Server_ReportSimulateCharacterLocation", "RPC_Client_ShootVertifyRes",
                "RPC_ClientCoronaLab"
            }
            _G.SendRPC = function(rpcName, ...)
                for _, blocked in ipairs(blockedRPCs) do
                    if rpcName == blocked then return nil end
                end
                return originalSendRPC(rpcName, ...)
            end
        end
    end)
end

-- ============================================================================
-- 17. HIGGS BOSON COMPLETE BYPASS
-- ============================================================================
local function InitializeHiggsBosonBypass()
    pcall(function()
        local Higgs = require("GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent")
        if Higgs then
            local methods = {
                "ControlMHActive", "Tick", "OnTick", "MHActiveLogic", "TriggerAvatarCheck",
                "StartAvatarCheck", "ReportItemID", "ReceiveAnyDamage", "OnWeaponHitRecord",
                "ShowSecurityAlert", "ServerReportAvatar", "ClientReportNetAvatar", "SendHisarData",
                "ValidateSecurityData", "StaticShowSecurityAlertInDev", "RPC_Client_ShootVertifyRes",
                "RPC_Server_ReportSimulateCharacterLocation", "DisableHiggsBoson", "CheckMHActive",
                "ReportViolation", "ProcessSecurityEvent", "ValidatePlayer", "CheckIntegrity"
            }
            for _, m in ipairs(methods) do
                if Higgs[m] then Higgs[m] = nop end
            end
            Higgs.GetNetAvatarItemIDs = retEmpty
            Higgs.GetCurWeaponSkinID = retZero
            Higgs.IsMHActive = retFalse
            Higgs.bMHActive = false
            Higgs.bCallPreReplication = false
        end
        
        local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
        if slua.isValid(pc) then
            if pc.HiggsBoson then
                pc.HiggsBoson.bMHActive = false
                pc.HiggsBoson.bCallPreReplication = false
                if pc.HiggsBoson.ControlMHActive then
                    pc.HiggsBoson:ControlMHActive(0)
                end
            end
            if pc.HiggsBosonComponent then
                pc.HiggsBosonComponent.bMHActive = false
                pc.HiggsBosonComponent.bCallPreReplication = false
                pc.HiggsBosonComponent:ControlMHActive(0)
            end
        end
        
        if Higgs and Higgs.BlackList then
            for k in pairs(Higgs.BlackList) do Higgs.BlackList[k] = nil end
        end
        _G.BlackList = {}
    end)
end

-- ============================================================================
-- 18. ANTI CHEAT HOOKS
-- ============================================================================
local function InitializeAntiCheatHooks()
    pcall(function()
        local HiggsBosonComponent = require("GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent")
        if HiggsBosonComponent and HiggsBosonComponent.StaticShowSecurityAlertInDev then
            HiggsBosonComponent.StaticShowSecurityAlertInDev = nop
        end
    end)
    
    if _G.AvatarCheckCallback then
        _G.AvatarCheckCallback.StartAvatarCheck = nop
        _G.AvatarCheckCallback.OnReportItemID = nop
        _G.AvatarCheckCallback.PostPlayerControllerLoginInit = function(PlayerController)
            if slua.isValid(PlayerController) and PlayerController.HiggsBosonComponent then
                PlayerController.HiggsBosonComponent:ControlMHActive(0)
                PlayerController.HiggsBosonComponent.bMHActive = false
            end
        end
    end
end

-- ============================================================================
-- 19. ANTI REPORT SYSTEM
-- ============================================================================
local function InitializeAntiReport()
    pcall(function()
        local paths = {
            "GameLua.Mod.BaseMod.Client.Security.ClientReportPlayerSubsystem",
            "Client.Security.ClientReportPlayerSubsystem",
            "GameLua.Mod.BaseMod.DS.Security.DSReportPlayerSubsystem"
        }
        
        for _, path in ipairs(paths) do
            local sub = package.loaded[path]
            if not sub then
                local success, reqModule = pcall(require, path)
                if success and reqModule then sub = reqModule end
            end
            if sub then
                for k, v in pairs(sub) do
                    if type(v) == "function" and (
                        k:find("Report") or k:find("Record") or k:find("Send") or
                        k:find("Upload") or k:find("Notify")
                    ) then
                        pcall(function() sub[k] = nop end)
                    end
                end
            end
        end
    end)
end

-- ============================================================================
-- 20. GAMEPLAY CALLBACKS BYPASS
-- ============================================================================
local function InitializeGameplayBypass()
    pcall(function()
        if not _G.GameplayCallbacks then _G.GameplayCallbacks = {} end
        if _G.GameplayCallbacks.IsBypassed then return end
        
        local GC = _G.GameplayCallbacks
        
        local reportFuncs = {
            "ReportAttackFlow", "ReportSecAttackFlow", "ReportHurtFlow", "ReportFireArms",
            "ReportVerifyInfoFlow", "ReportMrpcsFlow", "ReportPlayerBehavior", "ReportTeammatHurt",
            "ReportMisKillByTeammate", "ReportForbitPick", "ReportPlayerMoveRoute",
            "ReportPlayerPosition", "ReportVehicleMoveFlow", "ReportSecTgameMovingFlow",
            "ReportParachuteData", "SendTssSdkAntiDataToLobby", "ReportEquipmentFlow",
            "ReportAimFlow", "ReportPlayersPing", "ReportPlayerIP", "ReportPlayerFramePingRecord",
            "OnDSConnectionSaturated", "ReportDSNetSaturation", "ReportNetContinuousSaturate",
            "ReportDSNetRate", "SendClientStats", "SendServerAvgTickDelta",
            "ReportCircleFlow", "ReportPlayerKillFlow", "ClientSecMrpcsFlow", "Heartbeat",
            "SwiftHawk", "ClientSwiftHawk", "ClientSwiftHawkWithParams"
        }
        
        for _, funcName in ipairs(reportFuncs) do
            GC[funcName] = nop
        end
        
        GC.CheckReportSecAttackFlowWithAttackFlow = retFalse
        GC.CheckReportSecAttackFlow = retFalse
        
        local originalDSPlayerState = GC.OnDSPlayerStateChanged
        GC.OnDSPlayerStateChanged = function(UID, InPlayerState, bPureWatcher, bIsSafeExit, ParamReason)
            local stateStr = InPlayerState and string.lower(tostring(InPlayerState)) or ""
            local blockedStates = {
                ["cheatdetected"] = true, ["connectionlost"] = true, ["connectiontimeout"] = true,
                ["connectionexception"] = true, ["netdrivererror"] = true, ["banned"] = true,
                ["kicked"] = true, ["suspended"] = true, ["violationdetected"] = true,
                ["integrityfailure"] = true, ["securityviolation"] = true
            }
            if blockedStates[stateStr] then return end
            if originalDSPlayerState then pcall(originalDSPlayerState, UID, InPlayerState, bPureWatcher, bIsSafeExit, ParamReason) end
        end
        
        GC.OnPlayerNetConnectionClosed = nop
        GC.OnPlayerActorChannelError = nop
        GC.OnPlayerRPCValidateFailed = nop
        GC.OnPlayerSpectateException = nop
        GC.OnShutdownAfterError = nop
        
        GC.IsBypassed = true
    end)
end

-- ============================================================================
-- 21. KILL ALL SECURITY SUBSYSTEMS - COMPLETE
-- ============================================================================
local function InitializeKillAllSubsystems()
    pcall(function()
        local subMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if not subMgr then return end
        
        local subsystemsToKill = {
            "CoronaLabSubsystem", "PlayerSecurityInfoSubsystem", "ClientCircleFlowSubsystem",
            "ModifierExceptionSubsystem", "SimulateCharacterSubsystem", "ShootVerifySubSystemClient",
            "HiggsBosonComponent", "ClientReportPlayerSubsystem", "DSReportPlayerSubsystem",
            "ClientHawkEyePatrolSubsystem", "DSHawkEyePatrolSubsystem",
            "ClientDataStatistcsSubsystem", "AFKReportorSubsystem", "BehaviorScoreSubsystem",
            "FileCheckSubsystem", "MemoryCheckSubsystem", "SpeedCheckSubsystem", "WallCheckSubsystem",
            "AvatarExceptionSubsystem", "GameReportSubsystem", "RescueBtnReplayTraceSubsystem",
            "ClientSecMrpcsFlowSubsystem", "MrpcsFlowSubsystem", "PlayerKillFlowSubsystem",
            "CircleFlowSubsystem", "SwiftHawkSubsystem", "HeartbeatSubsystem",
            "AntiCheatSubsystem", "IntegrityCheckSubsystem", "SignatureVerifySubsystem",
            "MD5CheckSubsystem", "PakVerifySubsystem"
        }
        
        for _, name in ipairs(subsystemsToKill) do
            local sub = subMgr:Get(name)
            if sub then
                for k, v in pairs(sub) do
                    if type(v) == "function" and (
                        k:find("Report") or k:find("Send") or k:find("Upload") or 
                        k:find("Verify") or k:find("Check") or k:find("Validate") or
                        k:find("Scan") or k:find("Detect") or k:find("Collect") or
                        k:find("Flow") or k:find("Heartbeat")
                    ) then
                        pcall(function() sub[k] = nop end)
                    end
                end
                if sub.timer then pcall(function() sub:RemoveGameTimer(sub.timer) end) end
                if sub.heartbeatTimer then pcall(function() sub:RemoveGameTimer(sub.heartbeatTimer) end) end
                if sub.reportTimer then pcall(function() sub:RemoveGameTimer(sub.reportTimer) end) end
            end
        end
    end)
end

-- ============================================================================
-- 22. FINAL PROTECTION LAYER
-- ============================================================================
local function InitializeFinalProtection()
    pcall(function()
        local globalFlags = {
            "ENABLE_REPORT", "ENABLE_ANTI_CHEAT", "ENABLE_SECURITY", "ENABLE_TELEMETRY",
            "ENABLE_ANALYTICS", "ENABLE_CRASH_REPORT", "ENABLE_PERFORMANCE_REPORT"
        }
        for _, flag in ipairs(globalFlags) do
            if _G[flag] then _G[flag] = false end
        end
        
        local originalRequire = require
        local blockedModules = {
            "HiggsBosonComponent", "PlayerSecurityInfoSubsystem", "CoronaLabSubsystem",
            "ClientCircleFlowSubsystem", "ModifierExceptionSubsystem", "ShootVerifySubSystemClient",
            "ClientReportPlayerSubsystem", "DSReportPlayerSubsystem"
        }
        _G.require = function(module)
            for _, blocked in ipairs(blockedModules) do
                if module:find(blocked) then
                    return {}
                end
            end
            return originalRequire(module)
        end
    end)
end

-- ============================================================================
-- MAIN INITIALIZATION
-- ============================================================================
local function InitializeCompleteBypass()
    pcall(function()
        print("[ULTIMATE BYPASS] Starting initialization...")
        
        InitializeSLUABypass()
        InitializeMD5Bypass()
        InitializeSkinBypass()
        InitializeLogBlocker()
        InitializeScannerBlocker()
        InitializeReplayTelemetryBlocker()
        InitializeReportFlowBlocker()
        InitializePlayerSecurityBypass()
        InitializeClientFlowBypass()
        InitializeHeartbeatBypass()
        InitializeCoronaLabBypass()
        InitializeModifierExceptionBypass()
        InitializeSimulateCharacterLocationBypass()
        InitializeShootVerificationBypass()
        InitializeNetworkPacketBlock()
        InitializeHiggsBosonBypass()
        InitializeAntiCheatHooks()
        InitializeAntiReport()
        InitializeGameplayBypass()
        InitializeKillAllSubsystems()
        InitializeFinalProtection()
        
        print("[ULTIMATE BYPASS] Complete - All Security Systems Disabled")
        print("  ✓ SLUA + MD5 + PAK Signature")
        print("  ✓ Report Flows (Aim/Hit/Attack/Circle/Kill/Mrpcs)")
        print("  ✓ PlayerSecurityInfoCollector")
        print("  ✓ ClientSecMrpcsFlow + MrpcsFlow + MrpcsData")
        print("  ✓ Heartbeat + SwiftHawk + ClientSwiftHawkWithParams")
        print("  ✓ CoronaLab + PlayerSecurityInfo")
        print("  ✓ CircleFlow + ModifierException")
        print("  ✓ ShootVerify + BulletHitInfo")
        print("  ✓ HiggsBoson + Anti-Cheat")
        print("  ✓ Logs + Screenshots + Analytics")
        print("  ✓ All Subsystems Killed")
    end)
end

-- ============================================================================
-- START BYPASS
-- ============================================================================
local function StartBypass()
    local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    if slua.isValid(pc) and pc.AddGameTimer then
        pc:AddGameTimer(0.5, false, InitializeCompleteBypass)
        pc:AddGameTimer(3.0, true, function()
            InitializeHiggsBosonBypass()
            InitializeNetworkPacketBlock()
            InitializeHeartbeatBypass()
        end)
    else
        InitializeCompleteBypass()
    end
end

StartBypass()

local function sk_safe_require(path)
    local ok, mod = pcall(require, path)
    return ok and mod or nil
end

print("[MERGED BYPASS] Complete - All Security Systems Disabled")
print("  ✓ SLUA + MD5 + PAK Signature")
print("  ✓ CoronaLab + PlayerSecurityInfo")
print("  ✓ CircleFlow + ModifierException")
print("  ✓ ShootVerify + BulletHitInfo")
print("  ✓ HiggsBoson + Anti-Cheat")
print("  ✓ Logs + Screenshots + Analytics")
print("  ✓ All Subsystems Killed")

-- ============================================================================
-- BYPASS MODULE (ACTIVATES FIRST)
-- ============================================================================
if not _G.GameplayCallbacks then
    _G.GameplayCallbacks = {}
end

function _G.InitializeAntiReport()
    pcall(function()
        local reportPaths = { "GameLua.Mod.BaseMod.Client.Security.ClientReportPlayerSubsystem", "Client.Security.ClientReportPlayerSubsystem" }
        local ClientReportPlayerSubsystem = nil
        for _, path in ipairs(reportPaths) do
            if package.loaded[path] then ClientReportPlayerSubsystem = package.loaded[path] break end
            local success, loadedReportSubsystem = pcall(require, path)
            if success and loadedReportSubsystem then ClientReportPlayerSubsystem = loadedReportSubsystem break end
        end
        if ClientReportPlayerSubsystem then
            ClientReportPlayerSubsystem.OnInit = function(self) return end
            ClientReportPlayerSubsystem._OnPlayerKilledOtherPlayer = function() return end
            ClientReportPlayerSubsystem._RecordFatalDamager = function() return end
            ClientReportPlayerSubsystem._OnDeathReplayDataWhenFatalDamaged = function() return end
            ClientReportPlayerSubsystem._RecordMurdererFromDeathReplayData = function() return end
            ClientReportPlayerSubsystem._RecordTeammatePlayerInfo = function() return end
            ClientReportPlayerSubsystem._OnBattleResult = function() return end
            ClientReportPlayerSubsystem._OnShowQuickReportMutualExclusiveUI = function() return end
            ClientReportPlayerSubsystem.GetFatalDamagerMap = function() return {} end
            ClientReportPlayerSubsystem.GetCachedTeammateName2InfoMap = function() return {} end
            ClientReportPlayerSubsystem.GetTeammateName2InfoMapDuringBattle = function() return {} end
            ClientReportPlayerSubsystem.GetCurrentNotInTeamHistoricalTeammateMap = function() return {} end
            ClientReportPlayerSubsystem.GetInTeamIndexFromHistoricalTeammateInfo = function() return -1 end
        end
    end)
    pcall(function()
        local reportPaths = { "GameLua.Mod.BaseMod.DS.Security.DSReportPlayerSubsystem", "GameLua.Mod.BaseMod.Client.Security.DSReportPlayerSubsystem" }
        local DSReportPlayerSubsystem = nil
        for _, path in ipairs(reportPaths) do
            if package.loaded[path] then DSReportPlayerSubsystem = package.loaded[path] break end
            local success, loadedReportSubsystem = pcall(require, path)
            if success and loadedReportSubsystem then DSReportPlayerSubsystem = loadedReportSubsystem break end
        end
        if DSReportPlayerSubsystem then
            DSReportPlayerSubsystem.OnInit = function(self) return end
            DSReportPlayerSubsystem._OnNearDeathOrRescued = function() return end
            DSReportPlayerSubsystem._OnCharacterDied = function() return end
            DSReportPlayerSubsystem._OnTeammateDamage = function() return end
            DSReportPlayerSubsystem._OnPlayerSettlementStart = function() return end
            DSReportPlayerSubsystem._AddKnockDownerToBattleResult = function() return end
            DSReportPlayerSubsystem._AddKillerToBattleResult = function() return end
            DSReportPlayerSubsystem._AddTeammateMurderToBattleResult = function() return end
            DSReportPlayerSubsystem._AddFatalDamagerMapToBattleResult = function() return end
            DSReportPlayerSubsystem._AddMLKillerUIDToBattleResult = function() return end
            DSReportPlayerSubsystem._SaveHistoricalTeammateInfo = function() return end
            DSReportPlayerSubsystem._RecordFatalDamager = function() return end
            DSReportPlayerSubsystem._RecordTeammateMurderer = function() return end
        end
    end)
    pcall(function()
        local ReportPlayerUtils = require("GameLua.Mod.BaseMod.Common.Security.ReportPlayerUtils")
        if ReportPlayerUtils then
            ReportPlayerUtils.RecordFatalDamager = function() return end
            ReportPlayerUtils.IsUsingHistoricalTeammateInfo = function() return false end
            ReportPlayerUtils.IsCharacterDeliverAI = function() return false end
        end
    end)
    pcall(function()
        local SecurityCommonUtils = require("GameLua.Mod.BaseMod.Common.Security.SecurityCommonUtils")
        if SecurityCommonUtils then
            SecurityCommonUtils.ExtractPlayerBasicInfo = function() return {} end
            SecurityCommonUtils.LogIf = function() return false end
        end
    end)
    pcall(function()
        local ClientQuickReportMaliciousTeammate = require("GameLua.Mod.BaseMod.Client.Security.ClientQuickReportMaliciousTeammate")
        if ClientQuickReportMaliciousTeammate then
            ClientQuickReportMaliciousTeammate.OnShowMutualExclusiveUI = function() return end
            ClientQuickReportMaliciousTeammate.OnHideMutualExclusiveUI = function() return end
        end
    end)
    pcall(function()
        local LogicReportReplay = package.loaded["client.slua.logic.replay.logic_report_replay"]
        if LogicReportReplay then
            LogicReportReplay.ReportReplay = function() end
            LogicReportReplay.SendReportReq = function() end
        end
        local LogicHomeReport = package.loaded["client.slua.logic.home.logic_home_report"]
        if LogicHomeReport then
            LogicHomeReport.ShowInGameReportUI = function() end
            LogicHomeReport.SendReport = function() end
        end
    end)
end

function _G.DisableHiggsBoson()
    local localPlayerController = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    if not localPlayerController or not slua.isValid(localPlayerController) then return end
    if localPlayerController.HiggsBoson then
        localPlayerController.HiggsBoson.bMHActive = false
        localPlayerController.HiggsBoson.bCallPreReplication = false
    end
    if localPlayerController.HiggsBosonComponent then
        localPlayerController.HiggsBosonComponent.bMHActive = false
        localPlayerController.HiggsBosonComponent:ControlMHActive(0)
    end
end

function _G.InitializeAntiCheatHooks()
    pcall(function()
        local HiggsBosonComponent = require("GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent")
        if HiggsBosonComponent and HiggsBosonComponent.StaticShowSecurityAlertInDev then
            HiggsBosonComponent.StaticShowSecurityAlertInDev = function() end
        end
    end)
    if _G.AvatarCheckCallback then
        _G.AvatarCheckCallback.StartAvatarCheck = function(HiggsBosonComponent) end
        _G.AvatarCheckCallback.OnReportItemID = function(HiggsBosonComponent) end
        _G.AvatarCheckCallback.PostPlayerControllerLoginInit = function(localPlayerController)
            if slua.isValid(localPlayerController) and localPlayerController.HiggsBosonComponent then
                localPlayerController.HiggsBosonComponent:ControlMHActive(0)
                localPlayerController.HiggsBosonComponent.bMHActive = false
            end
        end
    end
    pcall(function()
        local HiggsBosonComponentModule = require("GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent")
        if HiggsBosonComponentModule and HiggsBosonComponentModule.BlackList then
            for k in pairs(HiggsBosonComponentModule.BlackList) do HiggsBosonComponentModule.BlackList[k] = nil end
        end
    end)
    _G.BlackList = {}
    pcall(function()
        _G.GlobalPlayerCoronaData = _G.GlobalPlayerCoronaData or {}
        _G.GlobalPlayerCheatTimes = _G.GlobalPlayerCheatTimes or {}
        local mt = getmetatable(_G.GlobalPlayerCoronaData) or {}
        mt.__newindex = function(t, k, v) end
        setmetatable(_G.GlobalPlayerCoronaData, mt)
    end)
    pcall(function()
        if _G.GameSafeCallbacks and _G.GameSafeCallbacks.RecordStrategyTimestampInReplay then
            _G.GameSafeCallbacks.RecordStrategyTimestampInReplay = function(...) end
            _G.GameSafeCallbacks.DoAttackFlowStrategy = function() end
            _G.GameSafeCallbacks.GetScriptReportContent = function() return "" end
        end
    end)
    pcall(function()
        local STExtraBlueprintFunctionLibrary = import("STExtraBlueprintFunctionLibrary")
        if STExtraBlueprintFunctionLibrary then
            STExtraBlueprintFunctionLibrary.IsDevelopment = function() return false end
        end
    end)
end

function _G.InitializeGameplayBypass()
    pcall(function()
        if not _G.GameplayCallbacks or _G.GameplayCallbacks.IsBypassed then return end
        local GC = _G.GameplayCallbacks
        local OriginalOnDSPlayerStateChanged = GC.OnDSPlayerStateChanged
        GC.OnDSPlayerStateChanged = function(UID, InPlayerState, bPureWatcher, bIsSafeExit, ParamReason)
            if InPlayerState and string.lower(tostring(InPlayerState)) == "cheatdetected" then return end
            if OriginalOnDSPlayerStateChanged then return OriginalOnDSPlayerStateChanged(UID, InPlayerState, bPureWatcher, bIsSafeExit, ParamReason) end
        end
        local function EmptyFunc() return end
        local function EmptyTableFunc() return {} end
        local function EmptyNilFunc() return nil end
        GC.ReportAttackFlow = EmptyFunc
        GC.ReportSecAttackFlow = EmptyFunc
        GC.ReportHurtFlow = EmptyFunc
        GC.ReportFireArms = EmptyFunc
        GC.ReportVerifyInfoFlow = EmptyFunc
        GC.ReportMrpcsFlow = EmptyFunc
        GC.ReportPlayerBehavior = EmptyFunc
        GC.ReportTeammatHurt = EmptyFunc
        GC.ReportMisKillByTeammate = EmptyFunc
        GC.ReportForbitPick = EmptyFunc
        GC.ReportPlayerMoveRoute = EmptyFunc
        GC.ReportPlayerPosition = EmptyFunc
        GC.ReportVehicleMoveFlow = EmptyFunc
        GC.ReportSecTgameMovingFlow = EmptyFunc
        GC.ReportParachuteData = EmptyFunc
        GC.SendTssSdkAntiDataToLobby = EmptyFunc
        GC.SendDSErrorLogToLobby = EmptyFunc
        GC.SendDSErrorLogToLobbyOnece = EmptyFunc
        GC.SendDSHawkEyePatrolLogToLobby = EmptyFunc
        GC.ReportEquipmentFlow = EmptyFunc
        GC.ReportAimFlow = EmptyFunc
        GC.GetWeaponReport = EmptyTableFunc
        GC.GetOneWeaponReport = EmptyTableFunc
        GC.ReportHeavyWeaponBoxSpawnFlow = EmptyFunc
        GC.ReportHeavyWeaponBoxActivationFlow = EmptyFunc
        GC.ReportHeavyWeaponBoxOpenPlayerFlow = EmptyFunc
        GC.ReportHeavyWeaponBoxItemFlow = EmptyFunc
        GC.ReportPlayersPing = EmptyFunc
        GC.ReportPlayerIP = EmptyFunc
        GC.ReportPlayerFramePingRecord = EmptyFunc
        GC.OnDSConnectionSaturated = EmptyFunc
        GC.ReportDSNetSaturation = EmptyFunc
        GC.ReportNetContinuousSaturate = EmptyFunc
        GC.ReportDSNetRate = EmptyFunc
        GC.SendClientStats = EmptyFunc
        GC.SendServerAvgTickDelta = EmptyFunc
        GC.ReportCircleFlow = EmptyFunc
        GC.ReportDSCircleFlow = EmptyFunc
        GC.ReportJumpFlow = EmptyFunc
        GC.ReportAIStrategyInfo = EmptyFunc
        GC.SendAIDeliveryInfo = EmptyFunc
        GC.ReportDailyTaskInfo = EmptyFunc
        GC.ReportMatchRoomData = EmptyFunc
        GC.SendPlayerSpectatingLog = EmptyFunc
        GC.ReportIDCardProduceFlow = EmptyFunc
        GC.ReportIDCardPickUpFlow = EmptyFunc
        GC.ReportIDCardDestroyFlow = EmptyFunc
        GC.ReportRevivalFlow = EmptyFunc
        GC.ReportGameSetting = EmptyFunc
        GC.ReportGameSettingNew = EmptyFunc
        GC.ReportAntsVoiceTeamCreate = EmptyFunc
        GC.ReportAntsVoiceTeamQuit = EmptyFunc
        GC.ReportCommonInfo = EmptyFunc
        GC.ReportLightweightStat = EmptyFunc
        GC.SendSecTLog = EmptyFunc
        GC.SendDataMiningTLog = EmptyFunc
        GC.SendActivityTLog = EmptyFunc
        GC.GetGeneralTLogData = EmptyNilFunc
        GC.IsBypassed = true
    end)
    pcall(function()
        if NetUtil and NetUtil.SendPacket and not NetUtil.IsBypassed then
            local OriginalSendPacket = NetUtil.SendPacket
            local blockedPacketsMap = {
                ["ReportAttackFlow"]=1, ["ReportSecAttackFlow"]=1, ["ReportHurtFlow"]=1,
                ["ReportFireArms"]=1, ["ReportVerifyInfoFlow"]=1, ["ReportMrpcsFlow"]=1,
                ["ReportPlayerBehavior"]=1, ["ReportTeammatHurt"]=1, ["ReportTeammateKillConfirmFlow"]=1,
                ["ReportForbiddenPickupFlow"]=1, ["ReportPlayerMoveRoute"]=1, ["ReportPlayerPosition"]=1,
                ["ReportSecVehicleMoveFlow"]=1, ["ReportSecTgameMovingFlow"]=1, ["report_parachute_data"]=1,
                ["report_character_all_drag"]=1, ["report_parachute_all_drag"]=1, ["report_vehicle_move_drag"]=1,
                ["on_tss_sdk_anti_data"]=1, ["report_unrealnet_exception"]=1, ["ReportPlayerEquipmentInfo"]=1,
                ["ReportAimFlow"]=1, ["ReportHitFlow"]=1, ["log_shooting_miss"]=1, ["report_heavy_weapon_box_activation_flow"]=1,
                ["report_heavy_weapon_box_item_flow"]=1, ["ReportCircleFlow"]=1, ["report_ds_player_circle_flow"]=1,
                ["ReportJumpFlow"]=1, ["ReportGameStartFlow"]=1, ["ReportGameEndFlow"]=1, ["report_players_ping"]=1,
                ["report_player_ip"]=1, ["report_player_frame_ping_record"]=1, ["report_net_saturate"]=1,
                ["report_ds_netsaturate"]=1, ["report_ds_net_continuous_saturate"]=1, ["report_ds_netrate"]=1,
                ["report_unrealnet_clientstats"]=1, ["report_serverstat_avgtickdelta"]=1, ["report_all_players_address"]=1,
                ["report_ai_strategyinfo"]=1, ["ReportAIActionFlow"]=1, ["ReportGenerateMonsterFlow"]=1,
                ["report_ds_match_room_data"]=1, ["SendSpectatingLog"]=1, ["ReportIDCardProduceFlow"]=1,
                ["ReportIDCardPickUpFlow"]=1, ["ReportIDCardDestroyFlow"]=1, ["ReportRevivalFlow"]=1,
                ["ReportGameSetting"]=1, ["ReportGameSettingNew"]=1, ["ReportAntsVoiceTeamCreate"]=1,
                ["ReportAntsVoiceTeamQuit"]=1, ["report_common_info"]=1, ["report_common_battle_info"]=1,
                ["report_client_scan_result"]=1, ["tss_sdk_report"]=1, ["report_memory_exception"]=1,
                ["report_avatar_exception"]=1, ["report_ui_state"]=1, ["report_hit_reg_fail"]=1,
                ["report_character_state"]=1, ["report_vehicle_exception"]=1, ["report_camera_exception"]=1,
                ["ReportPlayerControllerStateChanged"]=1, ["ReportAvatarFlow"]=1,
                ["send_ugc_report_uni_mod_expose_req"]=1, 
                ["send_ugc_report_uni_mod_interactive_req"]=1,
            }
            NetUtil.SendPacket = function(packetName, ...)
                if blockedPacketsMap[packetName] then return end
                return OriginalSendPacket(packetName, ...)
            end
            NetUtil.IsBypassed = true
        end
    end)
end

function _G.InitializeConnectionGuard()
    pcall(function()
        if _G.ConnectionGuardInitialized or not _G.GameplayCallbacks then return end
        local GC = _G.GameplayCallbacks
        local OriginalOnDSPlayerStateChanged = GC.OnDSPlayerStateChanged
        GC.OnDSPlayerStateChanged = function(UID, InPlayerState, bPureWatcher, bIsSafeExit, ParamReason)
            local stateNameLower = InPlayerState and string.lower(tostring(InPlayerState)) or ""
            local blockedStatesMap = {
                ["cheatdetected"] = true, ["connectionlost"] = true,
                ["connectiontimeout"] = true, ["connectionexception"] = true,
                ["netdrivererror"] = true
            }
            if blockedStatesMap[stateNameLower] then return end
            if OriginalOnDSPlayerStateChanged then
                pcall(OriginalOnDSPlayerStateChanged, UID, InPlayerState, bPureWatcher, bIsSafeExit, ParamReason)
            end
        end
        GC.OnPlayerNetConnectionClosed = function(GameID, UID, Reason, ErrorMessage) end
        GC.OnPlayerActorChannelError = function(GameID, UID, Reason, ErrorMessage) end
        GC.OnPlayerRPCValidateFailed = function(GameID, UID, Reason, ErrorMessage) end
        GC.OnPlayerSpectateException = function(GameID, UID, Reason, ErrorMessage) end
        GC.OnShutdownAfterError = function(GameID) end
        _G.ConnectionGuardInitialized = true
    end)
end

function _G.InitializeLogBlocker()
    pcall(function()
        local TLog = package.loaded["TLog"] or _G.TLog
        if TLog then
            TLog.Info = function() end; TLog.Warning = function() end
            TLog.Error = function() end; TLog.Debug = function() end; TLog.Report = function() end
        end
        local CrashSight = package.loaded["CrashSight"] or _G.CrashSight
        if CrashSight then
            CrashSight.ReportException = function() end
            CrashSight.SetCustomData = function() end; CrashSight.Log = function() end
        end
        local ClientToolsReport = package.loaded["client.slua.logic.report.ClientToolsReport"]
        if ClientToolsReport then
            ClientToolsReport.SendReport = function() end; ClientToolsReport.SendException = function() end
        end
        local TLogReportUtils = package.loaded["client.slua.config.tlog.tlog_report_utils"]
        if TLogReportUtils then
            TLogReportUtils.ReportTLogEvent = function() end
        end
        local UGCNewTLogReport = package.loaded["client.slua.logic.ugc.UGCNewTLogReport"] or package.loaded["client.slua.data.BasicData.BasicDataTLogReport"]
        if UGCNewTLogReport then
            UGCNewTLogReport.SendExposeReq = function() end
            UGCNewTLogReport.SendInteractionReq = function() end
            UGCNewTLogReport.TLogReport = function() end
        end
        local LogicUGCTLog = package.loaded["client.slua.logic.ugc.logic_ugc_tlog"]
        if LogicUGCTLog then
            LogicUGCTLog.SendModTLog = function() end
            LogicUGCTLog.ReportStay = function() end
        end
        local ClientTLogUtil = package.loaded["GameLua.Mod.BaseMod.Client.ClientTLog.ClientTLogUtil"]
        if ClientTLogUtil then
            ClientTLogUtil.ReportGeneralCountByBRPhase = function() end
            ClientTLogUtil.ReportCommonTLogDataByBRPhase = function() end
        end
        local GameplayDataRef = require("GameLua.GameCore.Data.GameplayData")
        if GameplayDataRef then
            local playerController = GameplayDataRef.GetPlayerControllerSafety and GameplayDataRef.GetPlayerControllerSafety() or GameplayDataRef.GetPlayerController()
            if slua.isValid(playerController) and playerController.ReportCrashKitFeature then
                playerController.ReportCrashKitFeature.ReportCharacterAttachedOnVehicleException = function() end
            end
        end
        local SubsystemMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        local GameReportSubsystem = SubsystemMgr and SubsystemMgr:Get("GameReportSubsystem")
        if GameReportSubsystem then
            GameReportSubsystem.CheckCanBugglyPostException = function() return false end
            GameReportSubsystem.BugglyPostExceptionFull = function() return false end
        end
    end)
end

function _G.InitializeScannerBlocker()
    pcall(function()
        local SubsystemMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if SubsystemMgr then
            local AFKReportorSubsystem = SubsystemMgr:Get("AFKReportorSubsystem")
            if AFKReportorSubsystem then 
                AFKReportorSubsystem.PlayerHaveAction = function() end; AFKReportorSubsystem.ReportAFK = function() end
            end
            local AvatarExceptionSubsystem = SubsystemMgr:Get("AvatarExceptionSubsystem")
            if AvatarExceptionSubsystem then
                AvatarExceptionSubsystem.ReportException = function() end
                AvatarExceptionSubsystem.BindPlayerCharacter = function() end
                AvatarExceptionSubsystem.CheckAvatarValid = function() return true end
            end
            local ShootVerifySubSystemClient = SubsystemMgr:Get("ShootVerifySubSystemClient")
            if ShootVerifySubSystemClient then
                ShootVerifySubSystemClient.ReportVerifyFail = function() end
                ShootVerifySubSystemClient.OnVerifyFailed = function() end
            end
        end
        local AvatarCheckerModule = package.loaded["blacklist.slua.logic.lobby_gm.AvatarCheckerModule"]
        if AvatarCheckerModule then
            AvatarCheckerModule.CheckAvatar = function() return true end
            AvatarCheckerModule.ReportException = function() end
        end
        local LogicMemoryWarning = package.loaded["client.slua.logic.memory_warning.logic_memory_warning"]
        if LogicMemoryWarning then
            LogicMemoryWarning.OnMemoryWarning = function() end
            LogicMemoryWarning.ReportMemoryWarning = function() end
        end
        local TssSdk = package.loaded["TssSdk"] or _G.TssSdk
        if TssSdk then
            TssSdk.OnRecvData = function() end; TssSdk.SendReportInfo = function() end
            TssSdk.ScanMemory = function() return true end
        end
    end)
end

function _G.InitializeReplayTelemetryBlocker()
    pcall(function()
        local SubsystemMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        local RescueBtnReplayTraceSubsystem = SubsystemMgr and SubsystemMgr:Get("RescueBtnReplayTraceSubsystem")
        if RescueBtnReplayTraceSubsystem then
            RescueBtnReplayTraceSubsystem.ReportTrace = function() end; RescueBtnReplayTraceSubsystem.StartTickMonitor = function() end
            RescueBtnReplayTraceSubsystem.TickMonitorCheck = function() end; RescueBtnReplayTraceSubsystem.ReportTickMonitorHeartbeat = function() end
        end
        local GameReportUtils = package.loaded["GameLua.Mod.BaseMod.GamePlay.GameReport.GameReportUtils"]
        if GameReportUtils then
            GameReportUtils.ReplayReportData = function() end
            GameReportUtils.ReportGameException = function() end
        end
        local GameReportSubsystem = SubsystemMgr and SubsystemMgr:Get("GameReportSubsystem")
        if GameReportSubsystem then
            GameReportSubsystem.ReplayReportData = function() return false end
            if GameReportSubsystem.Reporter then
                GameReportSubsystem.Reporter.ReportIntArrayData = function() end
                GameReportSubsystem.Reporter.ReportUInt8ArrayData = function() end
                GameReportSubsystem.Reporter.ReportFloatArrayData = function() end
            end
        end
    end)
end

local function InitializeAllBlockers()
    pcall(function()
        if _G.InitializeAntiReport then _G.InitializeAntiReport() end
        if _G.InitializeAntiCheatHooks then _G.InitializeAntiCheatHooks() end
        if _G.InitializeGameplayBypass then _G.InitializeGameplayBypass() end
        if _G.InitializeConnectionGuard then _G.InitializeConnectionGuard() end
        if _G.DisableHiggsBoson then _G.DisableHiggsBoson() end
        if _G.InitializeLogBlocker then _G.InitializeLogBlocker() end
        if _G.InitializeScannerBlocker then _G.InitializeScannerBlocker() end
        if _G.InitializeReplayTelemetryBlocker then _G.InitializeReplayTelemetryBlocker() end
    end)
end

pcall(function()
    InitializeAllBlockers()
end)

pcall(function()
    require("common.time_ticker").AddTimerOnce(2, function()
        if not CheckExpiration() then
            if _SYSTEM_TAMPER_DETECTED then
                ShowAntiCrackPopup("tamper")
            else
                ShowExpirePopup()
            end
            return
        end
        _G.TryShowWelcome()
    end)
end)

-- ============================================================================
-- CLASS REGISTRATION
-- ============================================================================
local class = require("class")
local CCharacterBase = require("GameLua.GameCore.Framework.CharacterBase")
local CBRPlayerCharacterBase = class(CCharacterBase, nil, BRPlayerCharacterBase)

return require("combine_class").DeclareFeature(CBRPlayerCharacterBase, {
    { SkyTransition = "GameLua.Mod.BaseMod.Gameplay.Feature.SkyControl.PlayerCharacterSkyTransitionFeature" },
    { CarryDeadBoxFeature = "GameLua.Mod.Library.GamePlay.Feature.CarryDeadBoxFeature" },
    { SpecialSuitFeature = "GameLua.Mod.Library.GamePlay.Feature.SpecialSuitFeature" },
    { TeleportPawnFeature = "GameLua.Mod.Library.GamePlay.Feature.TeleportPawnFeature" },
    { LifterControl = "GameLua.Mod.BaseMod.Gameplay.Feature.Player.CharacterLifterControlFeature" },
    { FinalKillEffect = "GameLua.Mod.BaseMod.Gameplay.Feature.Player.PlayerCharacterFinalKillEffectFeature" },
    { CampFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.Camp.PlayerCharacterCampFeature" },
    { BuildSkateFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.PlayerCharacterBuildVehicleFeature" },
    { CommonBornlandTransformFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.HeroPropFeature.CommonBornlandTransformFeature" },
    { ParachuteFormation = "GameLua.Mod.BaseMod.GamePlay.Feature.ParachuteFormationFeature" }
}, "BRPlayerCharacterBase")