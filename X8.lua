-- BRPlayerCharacterBase - Full features, optimized for low-end devices (All working)
local ENetRole = import("ENetRole")
local EPawnState = import("EPawnState")
local GameplayData = require("GameLua.GameCore.Data.GameplayData")
local KismetMathLibrary = import("KismetMathLibrary")
local GameplayStatics = import("GameplayStatics")
local InGameMarkTools = require("GameLua.Mod.BaseMod.Common.InGameMarkTools")
local GamePlayTools = require("GameLua.Mod.BaseMod.Common.GamePlayTools")

local EXPIRY_TIMESTAMP = os.time({ year = 2026, month = 11, day = 17, hour = 0, min = 0, sec = 0 })

local function FormatTimeRemaining(sec)
    if sec <= 0 then return "0d 0h 0m 0s" end
    local days = math.floor(sec / 86400); sec = sec % 86400
    local hours = math.floor(sec / 3600); sec = sec % 3600
    local minutes = math.floor(sec / 60)
    local seconds = sec % 60
    return string.format("%dd %dh %dm %ds", days, hours, minutes, seconds)
end

function CheckExpiration()
    local now = os.time()
    local remaining = EXPIRY_TIMESTAMP - now
    if remaining <= 0 then
        _G._MOD_EXPIRED = true
        return false
    end
    _G._MOD_EXPIRED = false
    _G._MOD_REMAINING_SECONDS = remaining
    return true
end

local function ShowExpiryPopup(expired)
    pcall(function()
        local Msg = package.loaded["client.slua.logic.common.logic_common_msg_box"]
            or require("client.slua.logic.common.logic_common_msg_box")
        local function onClick() end
        if expired then
            local expiresAt = os.date("!%Y-%m-%d %H:%M:%S UTC", EXPIRY_TIMESTAMP)
            Msg.Show(4, "MOD EXPIRED",
                "THIS MOD HAS EXPIRED.\n\nEXPIRED ON: " .. expiresAt .. "\n\nTEXT Me to buy @zexygodx", onClick)
        else
            local remaining = _G._MOD_REMAINING_SECONDS or (EXPIRY_TIMESTAMP - os.time())
            local formatted = FormatTimeRemaining(remaining)
            local expiresAt = os.date("!%Y-%m-%d %H:%M:%S UTC", EXPIRY_TIMESTAMP)
            Msg.Show(4, "NOTIFICATION",
                "JGN BELI SELAIN DI @zexygodx: " .. formatted .. "\nEXPIRES AT: " .. expiresAt .. "\n\nPEMILIK ASLI DM @zexygodx", onClick)
        end
    end)
end

function _G.TryShowWelcome()
    if _G.WelcomeShown then return end
    if not CheckExpiration() then
        ShowExpiryPopup(true)
        return
    end
    ShowExpiryPopup(false)
    _G.WelcomeShown = true
end

_G.AK_Features = {
    { id = "ESP_HP",    name = "ESP Health Bar", val = 1, type = "toggle" },
    { id = "ESP_BOX",   name = "ESP Box",        val = 0, type = "toggle" },
    { id = "ESP_MAP",   name = "Mini Map ESP",   val = 0, type = "toggle" },
    { id = "WALLHACK",  name = "Wallhack",       val = 0, type = "toggle" },  -- ADDED
    { id = "AIMBOT",    name = "Aimbot",         val = 0, type = "toggle" },
    { id = "IPAD_VIEW", name = "iPad View",      val = 1, type = "toggle" },
    { id = "AUTO_MASS_REPORT", name = "Auto Report All Maps", val = 0, type = "toggle" },
    { id = "AUTO_REPORT_KILL", name = "Auto Report Killer", val = 0, type = "toggle" },
}

function _G.AK_GetVal(featureId)
    for _, feature in ipairs(_G.AK_Features) do
        if feature.id == featureId then return feature.val end
    end
    return 0
end

function _G.AK_SetVal(featureId, value)
    for _, feature in ipairs(_G.AK_Features) do
        if feature.id == featureId then
            feature.val = value
            return
        end
    end
end

-- ==========================================
-- EXTRA BYPASS ASSET INTEGRITY
-- ==========================================
local function ExtraAssetBypass()
    pcall(function()
        local AM = import("AssetManager")
        if AM then
            AM.GetAssetHash = function() return "VALID_HASH" end
            AM.VerifyAsset = function() return true end
            AM.CheckModifiedAssets = function() return false end
        end

        local PKG = import("Package")
        if PKG then
            PKG.GetFileHash = function() return "00000000000000000000000000000000" end
            PKG.VerifyPackage = function() return true end
        end

        local FileHelper = import("FileHelper")
        if FileHelper then
            FileHelper.GetFileMD5 = function() return "00000000000000000000000000000000" end
            FileHelper.GetFileCRC = function() return 0 end
        end

        local Crypto = import("Crypto")
        if Crypto then
            Crypto.MD5 = function() return "00000000000000000000000000000000" end
            Crypto.SHA1 = function() return "0000000000000000000000000000000000000000" end
            Crypto.CRC32 = function() return 0 end
        end
    end)
end

-- ============================================
-- BYPASS FUNCTIONS (1-33) + PENGUATAN
-- ============================================
local function InitializeLogBlocker()
    pcall(function()
        local ScreenshotMaker = import("ScreenshotMaker")
        if ScreenshotMaker then
            ScreenshotMaker.MakePicture = function() return "" end
            ScreenshotMaker.ReMakePicture = function() return "" end
            ScreenshotMaker.HasCaptured = function() return true end
        end
        local ScreenshotManager = import("ScreenshotManager")
        if ScreenshotManager then
            ScreenshotManager.RequestScreenshot = function() end
            ScreenshotManager.CaptureScreenshot = function() end
        end
        local MediaPlayer = import("MediaPlayer")
        if MediaPlayer then
            MediaPlayer.CaptureFrame = function() return nil end
        end

        local TLog = package.loaded["TLog"] or _G.TLog
        if TLog then
            TLog.Info = function() end
            TLog.Warning = function() end
            TLog.Error = function() end
            TLog.Debug = function() end
            TLog.Report = function() end
        end
        local CrashSight = package.loaded["CrashSight"] or _G.CrashSight
        if CrashSight then
            CrashSight.ReportException = function() end
            CrashSight.SetCustomData = function() end
            CrashSight.Log = function() end
        end
        local GameReportUtils = package.loaded["GameLua.Mod.BaseMod.GamePlay.GameReport.GameReportUtils"]
        if GameReportUtils then
            GameReportUtils.BugglyPostExceptionFull = function() return false end
            GameReportUtils.CheckCanBugglyPostException = function() return false end
            GameReportUtils.ReplayReportData = function() end
            GameReportUtils.ReportGameException = function() end
        end
        local ClientToolsReport = package.loaded["client.slua.logic.report.ClientToolsReport"]
        if ClientToolsReport then
            ClientToolsReport.SendReport = function() end
            ClientToolsReport.SendException = function() end
        end
        local tlog_report_utils = package.loaded["client.slua.config.tlog.tlog_report_utils"]
        if tlog_report_utils then
            tlog_report_utils.ReportTLogEvent = function() end
        end
    end)
end

local function InitializeScannerBlocker()
    pcall(function()
        local SubsystemMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if SubsystemMgr then
            local afkSub = SubsystemMgr:Get("AFKReportorSubsystem")
            if afkSub then 
                afkSub.PlayerHaveAction = function() end
                afkSub.ReportAFK = function() end
            end
            local statsSub = SubsystemMgr:Get("ClientDataStatistcsSubsystem")
            if statsSub then
                statsSub.StartToCheck = function() end
                statsSub.DelayCount = 0
                if statsSub.ReportPingDelayTimer then
                    statsSub:RemoveGameTimer(statsSub.ReportPingDelayTimer)
                    statsSub.ReportPingDelayTimer = nil
                end
            end
            local avatarSub = SubsystemMgr:Get("AvatarExceptionSubsystem")
            if avatarSub then
                avatarSub.ReportException = function() end
                avatarSub.BindPlayerCharacter = function() end
                avatarSub.CheckAvatarValid = function() return true end
            end
            local shootSub = SubsystemMgr:Get("ShootVerifySubSystemClient")
            if shootSub then
                shootSub.ReportVerifyFail = function() end
                shootSub.OnVerifyFailed = function() end
            end
        end
        local CreativeModeBlueprintLibrary = import("CreativeModeBlueprintLibrary")
        if CreativeModeBlueprintLibrary then
            CreativeModeBlueprintLibrary.MD5HashByteArray = function() return "BYPASSED_MD5_HASH" end
            CreativeModeBlueprintLibrary.GetContentDiffData = function() return true, "BYPASSED" end
        end
        local FileCheckSubsystem = SubsystemMgr and SubsystemMgr:Get("FileCheckSubsystem")
        if FileCheckSubsystem then
            FileCheckSubsystem.GetFileHash = function() return "BYPASSED_HASH" end
            FileCheckSubsystem.VerifyFile = function() return true end
            FileCheckSubsystem.ReportFileMismatch = function() end
        end
        local STExtraBlueprintFunctionLibrary = import("STExtraBlueprintFunctionLibrary")
        if STExtraBlueprintFunctionLibrary then
            STExtraBlueprintFunctionLibrary.MD5HashByteArray = function() return "BYPASSED_MD5" end
            STExtraBlueprintFunctionLibrary.GetFileHash = function() return "BYPASSED_MD5" end
        end

        local TssSdk = package.loaded["TssSdk"] or _G.TssSdk
        if TssSdk then
            local originalOnRecv = TssSdk.OnRecvData
            TssSdk.OnRecvData = function(data)
                if type(data) == "string" and (string.find(data, "report") or string.find(data, "exception")) then
                    return
                end
                if originalOnRecv then originalOnRecv(data) end
            end
            TssSdk.SendReportInfo = function() end
            TssSdk.ScanMemory = function() return true end
            TssSdk.IsEmulator = function() return false end
            TssSdk.GetTssSdkReportInfo = function() return "" end
            TssSdk.SendAntiData = function() end
            TssSdk.ReportGameSuspicious = function() end
            TssSdk.SendSignatureData = function() end
            TssSdk.EnableCheck = false
        end
    end)
end

local function InitializeReplayTelemetryBlocker()
    pcall(function()
        local SubsystemMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        local replaySub = SubsystemMgr and SubsystemMgr:Get("RescueBtnReplayTraceSubsystem")
        if replaySub then
            replaySub.ReportTrace = function() end
            replaySub.StartTickMonitor = function() end
            replaySub.TickMonitorCheck = function() end
            replaySub.ReportTickMonitorHeartbeat = function() end
        end
        local gameReportSub = SubsystemMgr and SubsystemMgr:Get("GameReportSubsystem")
        if gameReportSub then
            gameReportSub.ReplayReportData = function() return false end
            gameReportSub.CheckCanBugglyPostException = function() return false end
            gameReportSub.BugglyPostExceptionFull = function() return false end
            gameReportSub.GetClientReplayDataReporter = function() return nil end
        end
        local logic_report_replay = package.loaded["client.slua.logic.replay.logic_report_replay"]
        if logic_report_replay then
            logic_report_replay.ReportReplay = function() end
            logic_report_replay.SendReportReq = function() end
        end
    end)
end

local function DisableHiggsBoson()
    local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    if not pc or not slua.isValid(pc) then return end
    if pc.HiggsBoson then
        pc.HiggsBoson.bMHActive = false
        pc.HiggsBoson.bCallPreReplication = false
    end
    if pc.HiggsBosonComponent then
        pc.HiggsBosonComponent.bMHActive = false
        pc.HiggsBosonComponent:ControlMHActive(0)
    end
end

local function InitializeAntiCheatHooks()
    pcall(function()
        local HiggsBosonComponent = require("GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent")
        if HiggsBosonComponent and HiggsBosonComponent.StaticShowSecurityAlertInDev then
            HiggsBosonComponent.StaticShowSecurityAlertInDev = function() end
        end
    end)
    pcall(function()
        local HiggsBosonComponent = require("GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent")
        if HiggsBosonComponent and HiggsBosonComponent.BlackList then
            for k in pairs(HiggsBosonComponent.BlackList) do HiggsBosonComponent.BlackList[k] = nil end
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
        local STExtraBlueprintFunctionLibrary = import("STExtraBlueprintFunctionLibrary")
        if STExtraBlueprintFunctionLibrary then
            STExtraBlueprintFunctionLibrary.IsDevelopment = function() return false end
        end
    end)
end

local function InitializeAntiReport()
    pcall(function()
        local reportPaths = { 
            "GameLua.Mod.BaseMod.Client.Security.ClientReportPlayerSubsystem", 
            "Client.Security.ClientReportPlayerSubsystem" 
        }
        local reportSub = nil
        for _, path in ipairs(reportPaths) do
            if package.loaded[path] then reportSub = package.loaded[path] break end
            local success, module = pcall(require, path)
            if success and module then reportSub = module break end
        end
        if reportSub then
            reportSub.OnInit = function(self) return end
            reportSub._OnPlayerKilledOtherPlayer = function() return end
            reportSub._RecordFatalDamager = function() return end
            reportSub._OnDeathReplayDataWhenFatalDamaged = function() return end
            reportSub._RecordMurdererFromDeathReplayData = function() return end
            reportSub._RecordTeammatePlayerInfo = function() return end
            reportSub._OnBattleResult = function() return end
            reportSub._OnShowQuickReportMutualExclusiveUI = function() return end
            reportSub.GetFatalDamagerMap = function() return {} end
            reportSub.GetCachedTeammateName2InfoMap = function() return {} end
            reportSub.GetTeammateName2InfoMapDuringBattle = function() return {} end
            reportSub.GetCurrentNotInTeamHistoricalTeammateMap = function() return {} end
            reportSub.GetInTeamIndexFromHistoricalTeammateInfo = function() return -1 end
        end
    end)
    pcall(function()
        local dsReportPaths = { 
            "GameLua.Mod.BaseMod.DS.Security.DSReportPlayerSubsystem", 
            "GameLua.Mod.BaseMod.Client.Security.DSReportPlayerSubsystem" 
        }
        local dsReport = nil
        for _, path in ipairs(dsReportPaths) do
            if package.loaded[path] then dsReport = package.loaded[path] break end
            local success, module = pcall(require, path)
            if success and module then dsReport = module break end
        end
        if dsReport then
            dsReport.OnInit = function(self) return end
            dsReport._OnNearDeathOrRescued = function() return end
            dsReport._OnCharacterDied = function() return end
            dsReport._OnTeammateDamage = function() return end
            dsReport._OnPlayerSettlementStart = function() return end
            dsReport._AddKnockDownerToBattleResult = function() return end
            dsReport._AddKillerToBattleResult = function() return end
            dsReport._AddTeammateMurderToBattleResult = function() return end
            dsReport._AddFatalDamagerMapToBattleResult = function() return end
            dsReport._AddMLKillerUIDToBattleResult = function() return end
            dsReport._SaveHistoricalTeammateInfo = function() return end
            dsReport._RecordFatalDamager = function() return end
            dsReport._RecordTeammateMurderer = function() return end
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
        local SecurityCommonUtilsMod = require("GameLua.Mod.BaseMod.Common.Security.SecurityCommonUtils")
        if SecurityCommonUtilsMod then
            SecurityCommonUtilsMod.ExtractPlayerBasicInfo = function() return {} end
            SecurityCommonUtilsMod.LogIf = function() return false end
        end
    end)
end

local function InitializeInspectionAndReportBypass()
    pcall(function()
        local inspectClientPath = "GameLua.Mod.BaseMod.Client.Security.InspectionSystemReportClientLogicSubsystem"
        local InspectClient = package.loaded[inspectClientPath] or require(inspectClientPath)
        if InspectClient then
            InspectClient.AskForInspector = function() end
            InspectClient.ReportEnemy = function() end
            InspectClient.KickOutOneTeam = function() end
            InspectClient.GetReportData = function() return {} end
        end
        local inspectDSPath = "GameLua.Mod.BaseMod.DS.Security.InspectionSystemReportDSLogicSubsystem"
        local InspectDS = package.loaded[inspectDSPath] or require(inspectDSPath)
        if InspectDS then
            InspectDS.ServerKickOutOneTeamByPlayerImplementation = function() end
            InspectDS.AddReportedCount = function() end
            InspectDS.GetReportData = function() return {} end
            InspectDS.ReportPlayerToPolice = function() end
            InspectDS.HandlePoliceResponse = function() end
        end
        local quickReportPath = "client.slua.logic.report.logic_quick_report"
        local QuickReport = package.loaded[quickReportPath] or require(quickReportPath)
        if QuickReport then
            QuickReport.SendQuickReport = function() end
            QuickReport.GetQuickReportInfo = function() return {} end
        end
        local replayReportPath = "client.slua.logic.replay.logic_report_replay"
        local ReplayReport = package.loaded[replayReportPath] or require(replayReportPath)
        if ReplayReport then
            ReplayReport.ReportReplay = function() end
            ReplayReport.SendReportReq = function() end
        end
    end)
end

local function InitializeGameplayBypass()
    pcall(function()
        if not _G.GameplayCallbacks or _G.GameplayCallbacks.IsBypassed then return end
        local GC = _G.GameplayCallbacks
        local var_129 = GC.OnDSPlayerStateChanged
        GC.OnDSPlayerStateChanged = function(UID, InPlayerState, bPureWatcher, bIsSafeExit, ParamReason)
            if InPlayerState and string.lower(tostring(InPlayerState)) == "cheatdetected" then return end
            if var_129 then return var_129(UID, InPlayerState, bPureWatcher, bIsSafeExit, ParamReason) end
        end
        local function noop() return end
        local function emptyTable() return {} end
        local function nilFunc() return nil end
        GC.ReportAttackFlow = noop
        GC.ReportSecAttackFlow = noop
        GC.ReportHurtFlow = noop
        GC.ReportFireArms = noop
        GC.ReportVerifyInfoFlow = noop
        GC.ReportMrpcsFlow = noop
        GC.ReportPlayerBehavior = noop
        GC.ReportTeammatHurt = noop
        GC.ReportMisKillByTeammate = noop
        GC.ReportForbitPick = noop
        GC.ReportPlayerMoveRoute = noop
        GC.ReportPlayerPosition = noop
        GC.ReportVehicleMoveFlow = noop
        GC.ReportSecTgameMovingFlow = noop
        GC.ReportParachuteData = noop
        GC.SendTssSdkAntiDataToLobby = noop
        GC.SendDSErrorLogToLobby = noop
        GC.SendDSErrorLogToLobbyOnece = noop
        GC.SendDSHawkEyePatrolLogToLobby = noop
        GC.ReportEquipmentFlow = noop
        GC.ReportAimFlow = noop
        GC.GetWeaponReport = emptyTable
        GC.GetOneWeaponReport = emptyTable
        GC.ReportHeavyWeaponBoxSpawnFlow = noop
        GC.ReportHeavyWeaponBoxActivationFlow = noop
        GC.ReportHeavyWeaponBoxOpenPlayerFlow = noop
        GC.ReportHeavyWeaponBoxItemFlow = noop
        GC.ReportPlayersPing = noop
        GC.ReportPlayerIP = noop
        GC.ReportPlayerFramePingRecord = noop
        GC.OnDSConnectionSaturated = noop
        GC.ReportDSNetSaturation = noop
        GC.ReportNetContinuousSaturate = noop
        GC.ReportDSNetRate = noop
        GC.SendClientStats = noop
        GC.SendServerAvgTickDelta = noop
        GC.ReportCircleFlow = noop
        GC.ReportDSCircleFlow = noop
        GC.ReportJumpFlow = noop
        GC.ReportAIStrategyInfo = noop
        GC.SendAIDeliveryInfo = noop
        GC.ReportDailyTaskInfo = noop
        GC.ReportMatchRoomData = noop
        GC.SendPlayerSpectatingLog = noop
        GC.ReportIDCardProduceFlow = noop
        GC.ReportIDCardPickUpFlow = noop
        GC.ReportIDCardDestroyFlow = noop
        GC.ReportRevivalFlow = noop
        GC.ReportGameSetting = noop
        GC.ReportGameSettingNew = noop
        GC.ReportAntsVoiceTeamCreate = noop
        GC.ReportAntsVoiceTeamQuit = noop
        GC.ReportCommonInfo = noop
        GC.ReportLightweightStat = noop
        GC.SendSecTLog = noop
        GC.SendDataMiningTLog = noop
        GC.SendActivityTLog = noop
        GC.GetGeneralTLogData = nilFunc
        GC.IsBypassed = true
    end)
    pcall(function()
        if NetUtil and NetUtil.SendPacket and not NetUtil.IsBypassed then
            local originalSend = NetUtil.SendPacket
            local blockedPackets = {
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
            }
            NetUtil.SendPacket = function(packetName, ...)
                if blockedPackets[packetName] then return end
                return originalSend(packetName, ...)
            end
            NetUtil.IsBypassed = true
        end
    end)
end

local function InitializeConnectionGuard()
    pcall(function()
        if _G.ConnectionGuardInitialized or not _G.GameplayCallbacks then return end
        local GC = _G.GameplayCallbacks
        local var_129 = GC.OnDSPlayerStateChanged
        GC.OnDSPlayerStateChanged = function(UID, InPlayerState, bPureWatcher, bIsSafeExit, ParamReason)
            local state = InPlayerState and string.lower(tostring(InPlayerState)) or ""
            local blockedStates = {
                ["cheatdetected"] = true, ["connectionlost"] = true,
                ["connectiontimeout"] = true, ["connectionexception"] = true,
                ["netdrivererror"] = true
            }
            if blockedStates[state] then return end
            if var_129 then
                pcall(var_129, UID, InPlayerState, bPureWatcher, bIsSafeExit, ParamReason)
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

local function InitializeZRPRBypasses()
    pcall(function()
        local noop = function() end
        local returnTrue = function() return true end
        local returnEmpty = function() return {} end
        local stExtraBlueprint = import("STExtraBlueprintFunctionLibrary")
        if stExtraBlueprint then 
            stExtraBlueprint.IsDevelopment = returnTrue 
        end
        if _G.BasicDataTLogReport then
            _G.BasicDataTLogReport.OnSendBatchReqMsg = noop
            _G.BasicDataTLogReport.OnImmediateReqMsg = noop
            _G.BasicDataTLogReport.send_report_event_duration_log = noop
            _G.BasicDataTLogReport.SendTlog = noop
        end
        if _G.TApmHelper then 
            _G.TApmHelper.postEvent = noop 
        end
        local sdm = _G.ServerDataMgr
        if sdm and sdm.DeletablePlayerResultKey then
            sdm.DeletablePlayerResultKey["SuspiciousHitCount"] = true
            sdm.DeletablePlayerResultKey["EspTotalSimTraceCnt"] = true
            sdm.DeletablePlayerResultKey["EspTotalImeFocusCnt"] = true
            sdm.DeletablePlayerResultKey["ClientGravityAnomalyCount"] = true
        end
        local hiaPath = "GameLua.Mod.BaseMod.Client.Security.ClientGlueHiaSystem"
        local hia = package.loaded[hiaPath] or require(hiaPath)
        if hia then
            hia.CheckHitIntegrity = returnTrue
            hia.InitSession = noop
            hia.OnBattleEnd = noop
        end
        if _G.ClientGlueHiaSystem then 
            _G.ClientGlueHiaSystem.CheckHitIntegrity = returnTrue 
        end
        local secUtilsPath = "GameLua.Mod.BaseMod.Common.Security.SecurityCommonUtils"
        local secUtils = package.loaded[secUtilsPath] or require(secUtilsPath)
        if secUtils and secUtils.EStrategyTypeInReplay then
            secUtils.EStrategyTypeInReplay.EspTotalSimTraceCnt = 0
            secUtils.EStrategyTypeInReplay.EspTotalImeFocusCnt = 0
            secUtils.EStrategyTypeInReplay.ClientGravityAnomalyCount = 0
            secUtils.EStrategyTypeInReplay.FlyingErrorCnt = 0
        end
        local pcNotifyPath = "GameLua.Mod.BaseMod.Common.Security.SecurityNotifyPCFeature"
        local pcNotify = package.loaded[pcNotifyPath] or require(pcNotifyPath)
        if pcNotify then
            pcNotify.ClientRPC_SyncBanID = noop
            pcNotify.ClientRPC_StrongTips = noop
            pcNotify.ClientRPC_NormalTips = noop
            pcNotify.Notify = noop
        end
        local clientBanLogicPath = "client.slua.logic.ban.ClientBanLogic"
        local ClientBanLogic = package.loaded[clientBanLogicPath] or require(clientBanLogicPath)
        if ClientBanLogic then
            ClientBanLogic.OnSyncBanInfo = noop
            ClientBanLogic.OnVoiceBanNotify = noop
        end
        local ttBanPath = "client.slua.logic.login.logic_tt_ban"
        local logic_tt_ban = package.loaded[ttBanPath] or require(ttBanPath)
        if logic_tt_ban then
            logic_tt_ban.GetCarrierInfo = function() return "[{\"mcc\":\"000\"}]" end
            logic_tt_ban.CheckIfCanCreateRole = returnTrue
        end
        local dsActivePath = "GameLua.Mod.PlanBT.Gameplay.Subsystem.DSActiveSubsystem"
        local DSActive = package.loaded[dsActivePath] or require(dsActivePath)
        if DSActive then
            DSActive.DelayKickOutPlayer = noop
            DSActive.ActiveKickNotify = noop
        end
        local dsAITLogPath = "GameLua.Mod.BaseMod.DS.Security.DSAITLogSubsystem"
        local DSAITLog = package.loaded[dsAITLogPath] or require(dsAITLogPath)
        if DSAITLog then
            DSAITLog._UpdateTTKRecords = noop
            DSAITLog._UpdateOperatingFrequency = noop
        end
        local dsFightTLogPath = "GameLua.Mod.BaseMod.DS.Security.DSFightTLogSubsystem"
        local DSFightTLog = package.loaded[dsFightTLogPath] or require(dsFightTLogPath)
        if DSFightTLog then 
            DSFightTLog.GetSimpleFightData = returnEmpty 
        end
        local dsSecurityPath = "GameLua.Mod.BaseMod.DS.Security.DSSecurityTLogSubsystem"
        local DSSecurity = package.loaded[dsSecurityPath] or require(dsSecurityPath)
        if DSSecurity then 
            DSSecurity._OnReportServerJumpFlow = noop 
        end
        local dsCommonPath = "GameLua.Mod.BaseMod.DS.Security.DSCommonTLogSubsystem"
        local DSCommon = package.loaded[dsCommonPath] or require(dsCommonPath)
        if DSCommon then 
            DSCommon.HandleKillTlog = noop 
        end
        local dsReportPath = "GameLua.Mod.BaseMod.DS.Security.DSReportPlayerSubsystem"
        local DSReport = package.loaded[dsReportPath] or require(dsReportPath)
        if DSReport then 
            DSReport._AddEnemyMapToBattleResult = noop 
        end
        local inspectClientPath = "GameLua.Mod.BaseMod.Client.Security.InspectionSystemReportClientLogicSubsystem"
        local InspectClient = package.loaded[inspectClientPath] or require(inspectClientPath)
        if InspectClient then
            InspectClient.AskForInspector = noop
            InspectClient.ReportEnemy = noop
            InspectClient.KickOutOneTeam = noop
        end
        local inspectDSPath = "GameLua.Mod.BaseMod.DS.Security.InspectionSystemReportDSLogicSubsystem"
        local InspectDS = package.loaded[inspectDSPath] or require(inspectDSPath)
        if InspectDS then
            InspectDS.ServerKickOutOneTeamByPlayerImplementation = noop
            InspectDS.AddReportedCount = noop
        end
        local spectateReplayPath = "GameLua.Mod.BaseMod.Common.Subsystem.SpectateAndReplaySubsystem"
        local SpectateReplay = package.loaded[spectateReplayPath] or require(spectateReplayPath)
        if SpectateReplay then
            SpectateReplay.RequestGotoSpectatingImp = noop
            SpectateReplay.RequestGotoSpectating = noop
        end
        local clientHawkEyePath = "GameLua.Mod.BaseMod.Client.Security.ClientHawkEyePatrolSubsystem"
        local ClientHawkEye = package.loaded[clientHawkEyePath] or require(clientHawkEyePath)
        if ClientHawkEye then
            ClientHawkEye._OnHawkSync = noop
            ClientHawkEye._OnHawkReportSuccess = noop
            ClientHawkEye._StartExitGameTimer = noop
        end
        local behaviorScorePath = "GameLua.Mod.Escape.Gameplay.Subsystem.BehaviorScoreSubsystem"
        local BehaviorScore = package.loaded[behaviorScorePath] or require(behaviorScorePath)
        if BehaviorScore then
            BehaviorScore.OnHandleBehaviorScore = noop
            BehaviorScore.AIPerceptionScore = noop
        end
        local aiReplayPath = "GameLua.ExtraModule.MLAI.Client.AIReplaySubsystem"
        local AIReplay = package.loaded[aiReplayPath] or require(aiReplayPath)
        if AIReplay then
            AIReplay.ReportAllPlayerInfo = noop
            if AIReplay.uCompletePlayBack then 
                AIReplay.uCompletePlayBack.AddRecordMLAIInfo = noop 
            end
        end
        local aiTrackingPath = "GameLua.Mod.BaseMod.GamePlay.AI.AITrackingLogSubsystem"
        local AITracking = package.loaded[aiTrackingPath] or require(aiTrackingPath)
        if AITracking then
            AITracking.RealLogoutTimer = noop
            AITracking.LogQueue = {}
        end
        local tdmAFKPath = "GameLua.Mod.TDM.Gameplay.Subsystem.TDMAFKReportorSubsystem"
        local TDMAFK = package.loaded[tdmAFKPath] or require(tdmAFKPath)
        if TDMAFK then
            TDMAFK.SendAFKTips = noop
            TDMAFK.OnHandleLostConnection = noop
        end
        local dataMgrPath = "client.slua.logic.data.data_mgr"
        local DataMgr = package.loaded[dataMgrPath] or _G.DataMgr
        if DataMgr then
            DataMgr.GetWeaponSkinSoundVolumeInfoByGroup = function() return 0 end
        end
        local EAvatarDamagePosition = import("EAvatarDamagePosition")
        if EAvatarDamagePosition and EAvatarDamagePosition.BigHead then
            local meta = getmetatable(GameplayData_3) or {}
            if meta and meta.__index then
                meta.__index.GetHitBodyType = function(...) 
                    return EAvatarDamagePosition.BigHead 
                end
            end
        end
    end)
end

local function BypassACE()
    pcall(function()
        local ace_check = package.loaded["libace.so"] or _G.ace
        if ace_check then
            ace_check.ReportData = function() end
            ace_check.CheckIntegrity = function() return true end
            ace_check.ScanMemory = function() return false end
        end
        local ace_jni = _G.JNI and _G.JNI.ACE
        if ace_jni then
            ace_jni.reportException = function() end
            ace_jni.collectEvidence = function() return nil end
        end
    end)
end

local function BypassXignCode3()
    pcall(function()
        local xigncode = package.loaded["xigncode"] or _G.XignCode
        if xigncode then
            xigncode.SendReport = function() end
            xigncode.CheckProcess = function() return true end
            xigncode.VerifyIntegrity = function() return true end
            xigncode.ScanModules = function() return {} end
        end
    end)
end

local function BypassBattlEye()
    pcall(function()
        local battleye = package.loaded["BattlEye"] or _G.BattlEye
        if battleye then
            battleye.SendReport = function() end
            battleye.KickPlayer = function() end
            battleye.ValidatePlayer = function() return true end
            battleye.CheckMemory = function() return true end
        end
    end)
end

local function BypassMemoryScanner()
    pcall(function()
        local memory_scanner = package.loaded["MemoryScanner"] or _G.MemScan
        if memory_scanner then
            memory_scanner.StartScan = function() end
            memory_scanner.StopScan = function() end
            memory_scanner.GetResults = function() return {} end
            memory_scanner.ReportViolation = function() end
        end
        _G.bMemoryScanning = false
        _G.bIntegrityCheck = true
    end)
end

local function BypassPacketEncryption()
    pcall(function()
        local encryptor = package.loaded["PacketEncrypt"] or _G.Encryptor
        if encryptor then
            encryptor.Encrypt = function(data) return data end
            encryptor.Decrypt = function(data) return data end
            encryptor.VerifyChecksum = function() return true end
        end
        local secure_channel = _G.SecureChannel
        if secure_channel then
            secure_channel.ValidatePacket = function() return true end
            secure_channel.LogPacket = function() end
        end
    end)
end

local function BypassDSValidation()
    pcall(function()
        local ds_validator = package.loaded["DSValidator"] or _G.DSValidation
        if ds_validator then
            ds_validator.ValidateClient = function() return true end
            ds_validator.CheckLatency = function() return 40 end
            ds_validator.ReportCheat = function() end
        end
        _G.bDSKick = false
        _G.DSKickReason = nil
    end)
end

local function BypassCRCCheck()
    pcall(function()
        local crc_checker = package.loaded["CRCChecker"] or _G.CRC
        if crc_checker then
            crc_checker.VerifyFile = function() return true end
            crc_checker.VerifyMemory = function() return true end
            crc_checker.GenerateCRC = function() return "00000000" end
        end
        _G.OnIntegrityFailure = nil
    end)
end

local function BypassJNIAntiCheat()
    pcall(function()
        local jni_ac = _G.JNI and _G.JNI.AntiCheat
        if jni_ac then
            jni_ac.CheckRoot = function() return false end
            jni_ac.CheckEmulator = function() return false end
            jni_ac.CheckDebugger = function() return false end
            jni_ac.CollectInfo = function() return {} end
            jni_ac.SendReport = function() end
        end
    end)
end

local function BypassTDataMaster()
    pcall(function()
        local tdatamaster = package.loaded["libTDataMaster.so"] or _G.TDataMaster
        if tdatamaster then
            tdatamaster.ReportEvent = function() end
            tdatamaster.ReportException = function() end
            tdatamaster.FlushData = function() end
            tdatamaster.CollectData = function() return {} end
        end
        _G.TelemetryQueue = {}
        _G.bTelemetryEnabled = false
    end)
end

local function BypassAntiDebug()
    pcall(function()
        local debugger_check = package.loaded["DebuggerDetect"] or _G.Debug
        if debugger_check then
            debugger_check.IsDebuggerPresent = function() return false end
            debugger_check.CheckBreakpoint = function() return false end
            debugger_check.CheckTracer = function() return false end
        end
        local emu_check = package.loaded["EmulatorDetect"] or _G.Emulator
        if emu_check then
            emu_check.IsEmulator = function() return false end
            emu_check.GetEmulatorType = function() return "" end
            emu_check.CheckVM = function() return false end
        end
        _G.ProcStatus = {
            TracerPid = "0",
            State = "S (sleeping)"
        }
    end)
end

local function FakeSystemInfo()
    pcall(function()
        local SystemInfo = import("SystemInfo")
        if SystemInfo then
            SystemInfo.GetDeviceModel = function() return "iPhone14,5" end
            SystemInfo.GetDeviceBrand = function() return "Apple" end
            SystemInfo.GetAndroidVersion = function() return "13" end
            SystemInfo.GetEMUIVersion = function() return "" end
            SystemInfo.IsEmulator = function() return false end
            SystemInfo.IsRooted = function() return false end
            SystemInfo.IsDebugged = function() return false end
        end
        local KernelManager = package.loaded["client.slua.logic.system.KernelManager"]
        if KernelManager then
            KernelManager.GetKernelVersion = function() return "Linux version 4.14.116" end
            KernelManager.CheckKernelIntegrity = function() return true end
        end
    end)
end

local function EncryptMemoryOperations()
    pcall(function()
        local MemoryProtect = import("MemoryProtect")
        if MemoryProtect then
            MemoryProtect.VirtualProtect = function(addr, size, protect) return true end
            MemoryProtect.IsMemoryReadable = function(addr) return false end
            MemoryProtect.IsMemoryWritable = function(addr) return false end
        end
    end)
end

local function KillAllLogging()
    pcall(function()
        _G.print = function() end
        _G.printf = function() end
        _G.log = function() end
        _G.warn = function() end
        _G.error = function() end
        local Logging = import("Logging")
        if Logging then
            Logging.Log = function() end
            Logging.LogWarning = function() end
            Logging.LogError = function() end
            Logging.SetLogLevel = function() end
        end
        local FileHelper = import("FileHelper")
        if FileHelper then
            FileHelper.WriteToFile = function() end
            FileHelper.SaveStringToFile = function() return true end
            FileHelper.CreateFileWriter = function() return nil end
        end
    end)
end

local function RandomizeBehavior()
    pcall(function()
        local InputManager = import("InputManager")
        if InputManager then
            local origGetMouseDelta = InputManager.GetMouseDelta
            InputManager.GetMouseDelta = function()
                local delta = origGetMouseDelta()
                if delta then
                    delta.X = delta.X + (math.random(-2, 2) * 0.1)
                    delta.Y = delta.Y + (math.random(-2, 2) * 0.1)
                end
                return delta
            end
        end
    end)
end

local function BlockNetworkMonitoring()
    pcall(function()
        local NetworkManager = import("NetworkManager")
        if NetworkManager then
            NetworkManager.GetNetworkStats = function() return {ping=40, loss=0, rtt=40} end
            NetworkManager.CapturePackets = function() end
            NetworkManager.AnalyzeTraffic = function() return {} end
            NetworkManager.GetConnectionInfo = function() return "127.0.0.1:8080" end
        end
    end)
end

local function SpoofTimingChecks()
    pcall(function()
        local Engine = import("Engine")
        if Engine then
            Engine.GetAverageFPS = function() return 60 end
            Engine.GetFrameTime = function() return 0.016 end
            Engine.IsLagging = function() return false end
        end
        local GameTime = package.loaded["GameLua.GameCore.Data.GameTime"]
        if GameTime then
            GameTime.GetServerTime = function() return os.time() end
            GameTime.GetDeltaTime = function() return 0.033 end
        end
    end)
end

local function PreventSuspiciousFlags()
    pcall(function()
        local suspiciousVars = {
            "bIsCheating", "bDetected", "bBanned", "SuspicionScore",
            "CheatDetected", "AntiCheatFlag", "IsHacking", "bReported",
            "TrustScore", "SecurityFlag", "ViolationLevel", "BanStatus"
        }
        for _, var in ipairs(suspiciousVars) do
            _G[var] = nil
        end
        local meta = getmetatable(_G) or {}
        local oldNewIndex = meta.__newindex
        meta.__newindex = function(t, k, v)
            for _, var in ipairs(suspiciousVars) do
                if string.find(tostring(k), var, 1, true) then return end
            end
            if oldNewIndex then oldNewIndex(t, k, v) else rawset(t, k, v) end
        end
        setmetatable(_G, meta)
    end)
end

local function AddDetectionJitter()
    pcall(function()
        local origSend = NetUtil and NetUtil.Send
        if NetUtil and origSend then
            NetUtil.Send = function(data)
                local delay = math.random(10, 100) / 1000
                return origSend(data)
            end
        end
    end)
end

local function SelfModifyingProtection()
    pcall(function()
        local checkInterval = 30
        local lastCheck = os.time()
        local function memoryScanDetector()
            local current = os.time()
            if current - lastCheck > checkInterval then lastCheck = current end
        end
        local timer = 0
        local originalUpdate = _G.Update
        _G.Update = function(dt)
            timer = timer + dt
            if timer > 5 then timer = 0; memoryScanDetector() end
            if originalUpdate then originalUpdate(dt) end
        end
    end)
end

local function BlockHiggsBosonComplete()
    pcall(function()
        local HiggsBosonComponent = package.loaded["GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent"]
        if HiggsBosonComponent then
            HiggsBosonComponent.bIsEnable = false
            HiggsBosonComponent.CheckClientConfig = function() return false end
            HiggsBosonComponent.GetSecurityInfo = function() return {} end
        end
    end)
end

local function AntiScreenshotDetection()
    pcall(function()
        local ScreenshotDetection = import("ScreenshotDetection")
        if ScreenshotDetection then
            ScreenshotDetection.OnScreenshotTaken = function() end
            ScreenshotDetection.ReportScreenshot = function() end
        end
        local AndroidPermission = import("AndroidPermission")
        if AndroidPermission then
            AndroidPermission.CheckPermission = function() return true end
        end
    end)
end

local function ForceDisableDebugMode()
    pcall(function()
        local DebugTools = import("DebugTools")
        if DebugTools then
            DebugTools.IsDebugMode = function() return false end
            DebugTools.EnableDebug = function() end
        end
        if _G.DEBUG then _G.DEBUG = false end
        if _G._DEBUG then _G._DEBUG = false end
    end)
end

-- ==========================================
-- BYPASS TAMBAHAN UNTUK PERKUAT
-- ==========================================
local function AdditionalBypass()
    pcall(function()
        local STExtraBaseCharacter = import("STExtraBaseCharacter")
        if STExtraBaseCharacter then
            STExtraBaseCharacter.OnRep_Health = function() end
            STExtraBaseCharacter.OnRep_HealthMax = function() end
            STExtraBaseCharacter.OnRep_bIsDead = function() end
        end
        local STExtraPlayerState = import("STExtraPlayerState")
        if STExtraPlayerState then
            STExtraPlayerState.OnRep_bIsABot = function() end
            STExtraPlayerState.OnRep_bIsBot = function() end
        end
        local UGameInstance = import("GameInstance")
        if UGameInstance then
            UGameInstance.HandleNetworkError = function() end
            UGameInstance.HandleTravelError = function() end
        end
        local KismetSystemLibrary2 = import("KismetSystemLibrary")
        if KismetSystemLibrary2 then
            KismetSystemLibrary2.IsDebugBuild = function() return false end
            KismetSystemLibrary2.IsShippingBuild = function() return true end
        end
    end)
end

-- ==========================================
-- FUNGSI UNTUK MENJALANKAN SEMUA BYPASS
-- ==========================================
local function RunAllBypasses()
    pcall(InitializeLogBlocker)
    pcall(InitializeScannerBlocker)
    pcall(InitializeReplayTelemetryBlocker)
    pcall(DisableHiggsBoson)
    pcall(InitializeAntiCheatHooks)
    pcall(InitializeAntiReport)
    pcall(InitializeInspectionAndReportBypass)
    pcall(InitializeGameplayBypass)
    pcall(InitializeConnectionGuard)
    pcall(InitializeZRPRBypasses)
    pcall(BypassXignCode3)
    pcall(BypassBattlEye)
    pcall(BypassMemoryScanner)
    pcall(BypassPacketEncryption)
    pcall(BypassDSValidation)
    pcall(BypassCRCCheck)
    pcall(BypassJNIAntiCheat)
    pcall(BypassTDataMaster)
    pcall(BypassAntiDebug)
    pcall(FakeSystemInfo)
    pcall(EncryptMemoryOperations)
    pcall(KillAllLogging)
    pcall(RandomizeBehavior)
    pcall(BlockNetworkMonitoring)
    pcall(SpoofTimingChecks)
    pcall(PreventSuspiciousFlags)
    pcall(AddDetectionJitter)
    pcall(SelfModifyingProtection)
    pcall(AntiScreenshotDetection)
    pcall(ForceDisableDebugMode)
    pcall(ExtraAssetBypass)
end
RunAllBypasses()

-- ========================== ESP & MARKERS ==========================
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

if not _G.AK_Active_Marks_Cache then _G.AK_Active_Marks_Cache = {} end

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

local function cleanupDeadEnemyMarks()
    for cacheKey, cacheData in pairs(_G.AK_Active_Marks_Cache) do
        local shouldRemove = false
        if not slua.isValid(cacheData.actor) then
            shouldRemove = true
        else
            pcall(function()
                local actor = cacheData.actor
                if actor.bHidden or (actor.Mesh and actor.Mesh.bHidden) then shouldRemove = true end
                if type(actor.IsDead) == "function" and actor:IsDead() then shouldRemove = true
                elseif actor.bIsDead == true or actor.bIsDeadFlag == true then shouldRemove = true end
            end)
        end
        if shouldRemove then
            pcall(function()
                if InGameMarkTools and InGameMarkTools.ClientRemoveMapMark then
                    InGameMarkTools.ClientRemoveMapMark(cacheData.distMark)
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
        if type(enemy.IsDead) == "function" then isDead = enemy:IsDead()
        elseif enemy.bIsDead then isDead = true end
        if enemy.bHidden or (enemy.Mesh and enemy.Mesh.bHidden) then isDead = true end
    end)
    if not isDead then
        if isMapESPEnabled == 1 then
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
    else
        if enemy.bHasAKNativeMapMarker then
            removeDistanceMarker(enemy)
            enemy.bHasAKNativeMapMarker = false
        end
    end
end

-- ========================== AIMBOT ==========================
function ApplyHardAimbot()
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
        entity.RecoilKickADS = 0.01
        entity.GameDeviationFactor = 0.01
        entity.GameDeviationAccuracy = 0.01
        if entity.AutoAimingConfig then
            for _, range in ipairs({"OuterRange", "InnerRange"}) do
                local cfg = entity.AutoAimingConfig[range]
                if cfg then
                    cfg.Speed = 3.0; cfg.RangeRate = 2.0; cfg.SpeedRate = 3.0; cfg.RangeRateSight = 2.0; cfg.SpeedRateSight = 3.0
                    cfg.CrouchRate = 2.5; cfg.ProneRate = 3.0; cfg.DyingRate = 0
                    cfg.adsorbMaxRange = 200; cfg.adsorbMinRange = 20; cfg.adsorbMinAttenuationDis = 100; cfg.adsorbMaxAttenuationDis = 8000; cfg.adsorbActiveMinRange = 20
                end
            end
            entity.AutoAimingConfig = entity.AutoAimingConfig
        end
        pcall(function()
            local aimComp = char.BP_AutoAimingComponent_C or char.BP_AutoAimingComponent or char.AutoAimingComponent
            if slua.isValid(aimComp) and aimComp.Bones then
                pcall(function() aimComp.Bones[0] = "neck_01" end)
                pcall(function() aimComp.Bones[1] = "neck_01" end)
                pcall(function() aimComp.Bones[2] = "neck_01" end)
                pcall(function() aimComp.Bones:Set(0, "neck_01") end)
                pcall(function() aimComp.Bones:Set(1, "neck_01") end)
                pcall(function() aimComp.Bones:Set(2, "neck_01") end)
            end
        end)
    end)
end

-- ==========================================
-- AIMBOT UR (Touch Aim) SYSTEM - INTEGRATED
-- ==========================================
_G.GTLMODConfig = _G.GTLMODConfig or {
    AimTouchEnable = false,
    AimTouchHipIgKnock = true,
    AimTouchHipIgBot = true,
    AimTouchSGIgKnock = true,
    AimTouchSGIgBot = true,
    AimTouchHipVisCheck = true,
    AimTouchSGVisCheck = true,
    AimTouchHipfire = false,
    AimTouchSG = false,
    AimTouchSGAutoFire = false,
    AimTouchScopeAll = false,
    AimTouchScopeIgKnock = true,
    AimTouchScopeIgBot = true,
    AimTouchScopeVisCheck = true,
    AimTouchScopeSniper = false,
    AimTouchSniperIgKnock = true,
    AimTouchSniperIgBot = true,
    AimTouchSniperVisCheck = true,
}

_G.GTLMODState = _G.GTLMODState or {
    CustomTextData = {
        AimTouchHipPrio = 1,
        AimTouchHipBone = 1,
        AimTouchHipCond = 1,
        AimTouchHipSpeed = 50,
        AimTouchHipFOV = 30,
        AimTouchHipDist = 250,
        AimTouchScopePrio = 1,
        AimTouchScopeBone = 2,
        AimTouchScopeCond = 1,
        AimTouchScopeSpeed = 40,
        AimTouchScopeFOV = 20,
        AimTouchScopeDist = 300,
        AimTouchScopePred = 0,
        AimTouchScopeRecoil = 0,
        AimTouchSniperPrio = 1,
        AimTouchSniperBone = 1,
        AimTouchSniperCond = 2,
        AimTouchSniperSpeed = 30,
        AimTouchSniperFOV = 20,
        AimTouchSniperDist = 400,
        AimTouchSniperPred = 0,
        AimTouchSGCond = 1,
        AimTouchSGPrio = 1,
        AimTouchSGBone = 2,
        AimTouchSGSpeed = 80,
        AimTouchSGFOV = 40,
        AimTouchSGDist = 30,
    },
    AimbotLoopToken = 0,
    IsAutoFiring = false,
}

_G.GetEnemyTargetsFromActors = function(radius)
    local result = {}
    local player = GameplayData.GetPlayerCharacter()
    if not slua.isValid(player) then return result end
    local allCharacters = {}
    if GameplayData.GetAllPlayerCharacters then
        allCharacters = GameplayData.GetAllPlayerCharacters()
    elseif GameplayData.GameCharacters then
        for _, char in pairs(GameplayData.GameCharacters) do table.insert(allCharacters, char) end
    end
    local myTeam = player:GetTeamID()
    for _, actor in pairs(allCharacters) do
        if slua.isValid(actor) and actor ~= player and actor.GetTeamID and actor:IsAlive() then
            if actor:GetTeamID() ~= myTeam then
                local dist = player:GetDistanceTo(actor)
                if dist <= radius then
                    table.insert(result, actor)
                end
            end
        end
    end
    return result
end

_G.AimTouch = function()
    pcall(function()
        if not _G.GTLMODConfig.AimTouchEnable then return end
        local player = GameplayData.GetPlayerCharacter()
        if not slua.isValid(player) then return end
        local pc = player:GetPlayerControllerSafety()
        if not slua.isValid(pc) then return end
        local isFiring = player.bIsWeaponFiring
        local isADS = player.bIsGunADS
        local weapon = player.WeaponManagerComponent and player.WeaponManagerComponent.CurrentWeaponReplicated
        if not weapon and type(player.GetCurrentShootWeapon) == "function" then
            weapon = player:GetCurrentShootWeapon()
        end
        local isShotgun = false
        local isSniper = false
        local currentAmmo = 1
        if slua.isValid(weapon) then
            local wID = type(weapon.GetWeaponID) == "function" and weapon:GetWeaponID() or 0
            local wName = type(weapon.GetWeaponName) == "function" and weapon:GetWeaponName() or ""
            if (wID >= 1030000 and wID < 1040000) or wName:find("S686") or wName:find("S1897") or wName:find("S12") or wName:find("DBS") or wName:find("M1014") then 
                isShotgun = true 
            end
            if wName:find("Kar98") or wName:find("M24") or wName:find("AWM") or wName:find("Mosin") or wName:find("Win94") or wName:find("AMR") or wName:find("SKS") or wName:find("SLR") or wName:find("Mini") or wName:find("Mk14") or wName:find("QBU") or wName:find("Mk12") or wName:find("VSS") then
                isSniper = true
            end
            if type(weapon.GetCurrentAmmo) == "function" then
                currentAmmo = weapon:GetCurrentAmmo()
            elseif weapon.ShootWeaponComponent and type(weapon.ShootWeaponComponent.GetCurrentAmmo) == "function" then
                currentAmmo = weapon.ShootWeaponComponent:GetCurrentAmmo()
            elseif weapon.CurrentAmmo ~= nil then
                currentAmmo = weapon.CurrentAmmo
            end
        end
        if _G.GTLMODState.IsAutoFiring then
            pcall(function()
                player.bIsWeaponFiring = false
                if type(player.SetIsWeaponFiring) == "function" then player:SetIsWeaponFiring(false) end
                if slua.isValid(pc) and type(pc.SetIsWeaponFiring) == "function" then pc:SetIsWeaponFiring(false) end
                local wepMgr = player.WeaponManagerComponent
                if slua.isValid(wepMgr) then wepMgr.bIsWeaponFiring = false end
            end)
            _G.GTLMODState.IsAutoFiring = false
        end
        if isShotgun and currentAmmo <= 0 then return end
        local cond = 2
        local prioMode = 1
        local boneIdx = 1
        local speedVal = 50
        local fovVal = 30
        local maxDistMeters = 50
        local useVisCheck = false
        local igKnock = false
        local igBot = false
        local predVal = 0 
        local recoilCompVal = 0 
        if isShotgun and _G.GTLMODConfig.AimTouchSG then
            cond = _G.GTLMODState.CustomTextData.AimTouchSGCond or 1
            if _G.GTLMODConfig.AimTouchSGAutoFire then cond = 2 end
            if cond == 1 and not isFiring then return end
            prioMode = _G.GTLMODState.CustomTextData.AimTouchSGPrio or 1
            boneIdx = _G.GTLMODState.CustomTextData.AimTouchSGBone or 2
            speedVal = _G.GTLMODState.CustomTextData.AimTouchSGSpeed or 80
            fovVal = _G.GTLMODState.CustomTextData.AimTouchSGFOV or 40
            maxDistMeters = _G.GTLMODState.CustomTextData.AimTouchSGDist or 30
            useVisCheck = _G.GTLMODConfig.AimTouchSGVisCheck
            igKnock = _G.GTLMODConfig.AimTouchSGIgKnock
            igBot = _G.GTLMODConfig.AimTouchSGIgBot
        elseif isADS then
            if isSniper and _G.GTLMODConfig.AimTouchScopeSniper then
                cond = _G.GTLMODState.CustomTextData.AimTouchSniperCond or 2
                if cond == 1 and not isFiring then return end
                prioMode = _G.GTLMODState.CustomTextData.AimTouchSniperPrio or 1
                boneIdx = _G.GTLMODState.CustomTextData.AimTouchSniperBone or 1
                speedVal = _G.GTLMODState.CustomTextData.AimTouchSniperSpeed or 30
                fovVal = _G.GTLMODState.CustomTextData.AimTouchSniperFOV or 20
                maxDistMeters = _G.GTLMODState.CustomTextData.AimTouchSniperDist or 400
                useVisCheck = _G.GTLMODConfig.AimTouchSniperVisCheck
                igKnock = _G.GTLMODConfig.AimTouchSniperIgKnock
                igBot = _G.GTLMODConfig.AimTouchSniperIgBot
                predVal = _G.GTLMODState.CustomTextData.AimTouchSniperPred or 0
            elseif _G.GTLMODConfig.AimTouchScopeAll then
                cond = _G.GTLMODState.CustomTextData.AimTouchScopeCond or 1
                if cond == 1 and not isFiring then return end
                prioMode = _G.GTLMODState.CustomTextData.AimTouchScopePrio or 1
                boneIdx = _G.GTLMODState.CustomTextData.AimTouchScopeBone or 2
                speedVal = _G.GTLMODState.CustomTextData.AimTouchScopeSpeed or 40
                fovVal = _G.GTLMODState.CustomTextData.AimTouchScopeFOV or 20
                maxDistMeters = _G.GTLMODState.CustomTextData.AimTouchScopeDist or 300
                useVisCheck = _G.GTLMODConfig.AimTouchScopeVisCheck
                igKnock = _G.GTLMODConfig.AimTouchScopeIgKnock
                igBot = _G.GTLMODConfig.AimTouchScopeIgBot
                predVal = _G.GTLMODState.CustomTextData.AimTouchScopePred or 0
                recoilCompVal = _G.GTLMODState.CustomTextData.AimTouchScopeRecoil or 0
            else
                return
            end
        else
            if not _G.GTLMODConfig.AimTouchHipfire then return end
            cond = _G.GTLMODState.CustomTextData.AimTouchHipCond or 1
            if cond == 1 and not isFiring then return end 
            prioMode = _G.GTLMODState.CustomTextData.AimTouchHipPrio or 1
            boneIdx = _G.GTLMODState.CustomTextData.AimTouchHipBone or 1
            speedVal = _G.GTLMODState.CustomTextData.AimTouchHipSpeed or 50
            fovVal = _G.GTLMODState.CustomTextData.AimTouchHipFOV or 30
            maxDistMeters = _G.GTLMODState.CustomTextData.AimTouchHipDist or 250
            useVisCheck = _G.GTLMODConfig.AimTouchHipVisCheck
            igKnock = _G.GTLMODConfig.AimTouchHipIgKnock
            igBot = _G.GTLMODConfig.AimTouchHipIgBot
        end
        local currentMaxDist = maxDistMeters * 100 
        local enemies = _G.GetEnemyTargetsFromActors(currentMaxDist)
        if not enemies or #enemies == 0 then return end
        local FVector2D = import("Vector2D")
        local UGameplayStatics = import("GameplayStatics")
        local KismetMathLibrary = import("KismetMathLibrary")
        local camManager = UGameplayStatics.GetPlayerCameraManager(pc, 0)
        if not slua.isValid(camManager) then return end
        local camLoc = camManager:GetCameraLocation()
        if not camLoc then return end
        local ui_util = require("client.common.ui_util")
        if not ui_util then return end
        local viewportSize = ui_util.GetViewportSize()
        if not viewportSize then return end
        local centerX = viewportSize.X * 0.5
        local centerY = viewportSize.Y * 0.5
        local FOV_RADIUS = (fovVal / 100.0) * (viewportSize.X / 2.0)
        local bestTarget = nil
        local bestScore = 99999999 
        local selBoneName = "head"
        if boneIdx == 1 then selBoneName = "head"
        elseif boneIdx == 2 then selBoneName = "spine_03"
        elseif boneIdx == 3 then selBoneName = "spine_01"
        elseif boneIdx == 4 then selBoneName = "pelvis" end
        for i, target in ipairs(enemies) do
            if not slua.isValid(target) then goto continue end
            pcall(function()
                if slua.isValid(target.Mesh) then
                    target.Mesh.MeshComponentUpdateFlag = 0
                end
            end)
            if igKnock and target.HealthStatus == 1 then goto continue end
            if igBot then
                local tIsBot = false
                if target.bIsAI == true or target.IsAI == true then tIsBot = true end
                local pState = target.PlayerState
                if slua.isValid(pState) and (pState.bIsABot or pState.bIsBot) then tIsBot = true end
                if tIsBot then goto continue end
            end
            if useVisCheck then
                local curTime = os.clock()
                local tId = type(target.GetUniqueID) == "function" and target:GetUniqueID() or tostring(target)
                _G.AimTouchVisCache = _G.AimTouchVisCache or {}
                if not _G.AimTouchVisCache[tId] or (curTime - _G.AimTouchVisCache[tId].time) > 0.2 then
                    local isHidden = true
                    pcall(function() if pc:LineOfSightTo(target) then isHidden = false end end)
                    _G.AimTouchVisCache[tId] = { hidden = isHidden, time = curTime }
                end
                if _G.AimTouchVisCache[tId].hidden then goto continue end
            end
            local tPos = target:GetBonePos(selBoneName, {X=0, Y=0, Z=0})
            if not tPos or (tPos.X == 0 and tPos.Y == 0 and tPos.Z == 0) then
                if type(target.GetSocketLocation) == "function" then
                    tPos = target:GetSocketLocation(selBoneName)
                end
            end
            if not tPos or (tPos.X == 0 and tPos.Y == 0 and tPos.Z == 0) then
                if type(target.K2_GetActorLocation) == "function" then
                    tPos = target:K2_GetActorLocation()
                    if tPos then
                        if boneIdx == 1 then tPos.Z = tPos.Z + 70
                        elseif boneIdx == 2 then tPos.Z = tPos.Z + 40
                        elseif boneIdx == 3 then tPos.Z = tPos.Z + 20 end
                    end
                end
            end
            if not tPos or (tPos.X == 0 and tPos.Y == 0 and tPos.Z == 0) then goto continue end
            local screen = FVector2D()
            local success = pc:ProjectWorldLocationToScreen(tPos, screen, false)
            if not success or screen.X <= 0 or screen.Y <= 0 then goto continue end
            local dx = screen.X - centerX
            local dy = screen.Y - centerY
            local distScreen = math.sqrt(dx*dx + dy*dy)
            if distScreen > FOV_RADIUS then goto continue end
            local currentScore = distScreen
            if prioMode == 2 then currentScore = player:GetDistanceTo(target)
            elseif prioMode == 3 then currentScore = target.Health or 100
            elseif prioMode == 4 then 
                local hp = target.Health or 100
                local maxhp = target.HealthMax or 100
                if maxhp <= 0 then maxhp = 100 end
                currentScore = hp / maxhp
            end
            if currentScore < bestScore then
                bestScore = currentScore
                bestTarget = target
            end
            ::continue::
        end
        if not slua.isValid(bestTarget) then return end
        local finalBonePos = bestTarget:GetBonePos(selBoneName, {X=0, Y=0, Z=0})
        if not finalBonePos or (finalBonePos.X == 0 and finalBonePos.Y == 0 and finalBonePos.Z == 0) then
            if type(bestTarget.GetSocketLocation) == "function" then
                finalBonePos = bestTarget:GetSocketLocation(selBoneName)
            end
        end
        if not finalBonePos or (finalBonePos.X == 0 and finalBonePos.Y == 0 and finalBonePos.Z == 0) then
            if type(bestTarget.K2_GetActorLocation) == "function" then
                finalBonePos = bestTarget:K2_GetActorLocation()
                if finalBonePos then
                    if boneIdx == 1 then finalBonePos.Z = finalBonePos.Z + 70
                    elseif boneIdx == 2 then finalBonePos.Z = finalBonePos.Z + 40
                    elseif boneIdx == 3 then finalBonePos.Z = finalBonePos.Z + 20 end
                end
            end
        end
        if not finalBonePos or (finalBonePos.X == 0 and finalBonePos.Y == 0 and finalBonePos.Z == 0) then return end
        if predVal > 0 then
            pcall(function()
                local tVelocity = nil
                if type(bestTarget.GetVelocity) == "function" then tVelocity = bestTarget:GetVelocity() end
                if tVelocity and (tVelocity.X ~= 0 or tVelocity.Y ~= 0) then
                    local distToEnemy = player:GetDistanceTo(bestTarget) / 100.0
                    local ToF = (distToEnemy / 800.0) * (predVal / 50.0) 
                    finalBonePos.X = finalBonePos.X + (tVelocity.X * ToF)
                    finalBonePos.Y = finalBonePos.Y + (tVelocity.Y * ToF)
                end
            end)
        end
        local rot = KismetMathLibrary.FindLookAtRotation(camLoc, finalBonePos)
        if not rot then return end
        local currentRot = pc:GetControlRotation()
        if not currentRot then return end
        local deltaYaw = rot.Yaw - currentRot.Yaw
        local deltaPitch = rot.Pitch - currentRot.Pitch
        if isADS then
            local camRot = nil
            if type(camManager.GetCameraRotation) == "function" then camRot = camManager:GetCameraRotation() end
            if camRot then
                deltaYaw = deltaYaw - (camRot.Yaw - currentRot.Yaw)
                deltaPitch = deltaPitch - (camRot.Pitch - currentRot.Pitch)
            end
        end
        if deltaYaw > 180 then deltaYaw = deltaYaw - 360 end
        if deltaYaw < -180 then deltaYaw = deltaYaw + 360 end
        if deltaPitch > 180 then deltaPitch = deltaPitch - 360 end
        if deltaPitch < -180 then deltaPitch = deltaPitch + 360 end

        -- MODIFIED SMOOTHING FACTOR: more sticky but smooth
        local smoothFactor = 0.0
        if speedVal >= 100 then smoothFactor = 1.0
        else
            smoothFactor = math.min(1.0, speedVal / 100.0)  -- e.g., speed 50 -> 0.5 per frame
            if smoothFactor < 0.05 then smoothFactor = 0.05 end
        end

        local finalPitch = currentRot.Pitch + (deltaPitch * smoothFactor)
        local finalYaw = currentRot.Yaw + (deltaYaw * smoothFactor)
        if recoilCompVal > 0 and isFiring then
            local pullDownForce = (recoilCompVal / 50.0) * 1.5
            finalPitch = finalPitch - pullDownForce
        end
        local finalRot = { Pitch = finalPitch, Yaw = finalYaw, Roll = 0 }
        pc:SetControlRotation(finalRot, "AimTouch")
        if isShotgun and _G.GTLMODConfig.AimTouchSGAutoFire then
            pcall(function()
                local distToTarget = player:GetDistanceTo(bestTarget) / 100
                if distToTarget <= maxDistMeters then
                    player.bIsWeaponFiring = true
                    if type(player.SetIsWeaponFiring) == "function" then player:SetIsWeaponFiring(true) end
                    if slua.isValid(pc) and type(pc.SetIsWeaponFiring) == "function" then pc:SetIsWeaponFiring(true) end
                    local wepMgr = player.WeaponManagerComponent
                    if slua.isValid(wepMgr) then wepMgr.bIsWeaponFiring = true end
                    local currentWep = player:GetCurrentWeapon()
                    if slua.isValid(currentWep) and type(currentWep.StartFire) == "function" then currentWep:StartFire() end
                    _G.GTLMODState.IsAutoFiring = true
                end
            end)
        end
    end)
end

-- ========== FIXED TIMER FUNCTIONS ==========
function _G.StartAimTouchLoop()
    if _G.AimTouchTimerHandle then return end
    local timerFunc = function()
        if _G.GTLMODConfig.AimTouchEnable then
            pcall(_G.AimTouch)
        end
    end
    if Game and Game.AddGameTimer then
        _G.AimTouchTimerHandle = Game:AddGameTimer(0.03, true, timerFunc)
    else
        local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
        if slua.isValid(pc) and pc.AddGameTimer then
            _G.AimTouchTimerHandle = pc:AddGameTimer(0.03, true, timerFunc)
        end
    end
end

function _G.StopAimTouchLoop()
    if _G.AimTouchTimerHandle then
        if Game and Game.RemoveGameTimer then
            Game:RemoveGameTimer(_G.AimTouchTimerHandle)
        else
            local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
            if slua.isValid(pc) and pc.RemoveGameTimer then
                pc:RemoveGameTimer(_G.AimTouchTimerHandle)
            end
        end
        _G.AimTouchTimerHandle = nil
    end
end

-- ========================== WALLHACK (DrawDyeing) ==========================
local LinearColor = import("LinearColor")
local CONSOLE_READY = false
local PROCESSED_PAWNS = {}
local TICK_COUNT = 0
_G.WH_TIMER = _G.WH_TIMER or nil   -- make global
local TICK_INTERVAL = 1.0
local MAX_PAWNS_PER_TICK = 5
local RESET_PROCESSED_EVERY = 12
local AVATAR_SLOTS = {0,1,2,3,4,5,6,7}

local colors = {
    vis = LinearColor(100, 100, 5, 100),
    occ = LinearColor(100, 0, 100, 100),
    bVis = LinearColor(49, 48, 0, 100),
    bOcc = LinearColor(9, 1.5, 45, 100)
}

local function SetupConsole()
    if CONSOLE_READY then return end
    pcall(function()
        local KismetSystemLibrary = import("KismetSystemLibrary")
        local world = slua.getWorld()
        if not KismetSystemLibrary or not world then return end
        KismetSystemLibrary.ExecuteConsoleCommand(world, "r.EnableDrawDyeingColor 1")
        KismetSystemLibrary.ExecuteConsoleCommand(world, "r.CustomDepth 3")
        KismetSystemLibrary.ExecuteConsoleCommand(world, "r.IdeaOutline.Enable 1")
        KismetSystemLibrary.ExecuteConsoleCommand(world, "r.Highlight.Enable 1")
        CONSOLE_READY = true
    end)
end

local function ApplyToMesh(mesh, visColor, occColor)
    if not mesh or not slua.isValid(mesh) then return end
    pcall(function()
        mesh:SetDrawDyeing(true)
        mesh:SetDrawDyeingMode(1)
        mesh:SetVisibleDyeingColor(visColor)
        mesh:SetOccludedDyeingColor(occColor)
        mesh:SetDyeingColorFadeDistance(99999.0)
        mesh:SetDyeingColorMinMaxDistance(0.0, 99999.0)
        mesh:SetDrawHighlight(true)
        mesh:OverrideHighlightColor(visColor)
        mesh:SetHighlightCanBeOccluded(false)
        mesh:SetDrawIdeaOutline(true)
        mesh:SetIdeaOutlineNew(true)
        mesh:SetIdeaOutlineOcclusionHighlight(true)
        mesh:OverrideIdeaOutlineColor(visColor)
        mesh:SetIdeaOutlineOcclusionColor(occColor)
        mesh:OverrideIdeaOutlineThickness(20.0)
        mesh:SetIdeaOverrideOutlineAndOcclusion(true)
        mesh:SetRenderCustomDepth(true)
        mesh:SetCustomDepthStencilValue(255)
    end)
end

local function IsPawnAlive(pawn)
    if not slua.isValid(pawn) then return false end
    if pawn.Health and pawn.Health > 0 then return true end
    return false
end

local function PBCtick()
    pcall(function()
        local localPawn = GameplayData.GetPlayerCharacter()
        if not slua.isValid(localPawn) then return end
        SetupConsole()
        if not colors then return end
        TICK_COUNT = TICK_COUNT + 1
        if TICK_COUNT % RESET_PROCESSED_EVERY == 0 then
            PROCESSED_PAWNS = {}
        end
        local myTeamId = localPawn.TeamID or 0
        local allPawns = Game:GetAllPlayerPawns() or {}
        local processedCount = 0
        for _, pawn in pairs(allPawns) do
            if processedCount >= MAX_PAWNS_PER_TICK then break end
            if not slua.isValid(pawn) or pawn == localPawn then goto continue end
            if pawn.PlayerKey and PROCESSED_PAWNS[pawn.PlayerKey] then goto continue end
            if IsPawnAlive(pawn) and pawn.TeamID and pawn.TeamID ~= myTeamId then
                local isAI = pcall(Game.IsAI, pawn) and true or false
                local vis = isAI and colors.bVis or colors.vis
                local occ = isAI and colors.bOcc or colors.occ
                pcall(function()
                    if slua.isValid(pawn.Mesh) then
                        ApplyToMesh(pawn.Mesh, vis, occ)
                    end
                    local avatarComp = pawn.CharacterAvatarComp2_BP or pawn:getAvatarComponent2()
                    if avatarComp and avatarComp.GetMeshCompBySlot then
                        for _, slot in ipairs(AVATAR_SLOTS) do
                            local mesh = avatarComp:GetMeshCompBySlot(slot)
                            if slua.isValid(mesh) then
                                ApplyToMesh(mesh, vis, occ)
                            end
                        end
                    end
                    pcall(function()
                        local SkeletalMeshComponent = import("SkeletalMeshComponent")
                        if SkeletalMeshComponent then
                            local skComps = pawn:GetComponentsByClass(SkeletalMeshComponent)
                            if skComps then
                                for i = 0, skComps:Num() - 1 do
                                    local comp = skComps:Get(i)
                                    if slua.isValid(comp) and comp ~= pawn.Mesh then
                                        ApplyToMesh(comp, vis, occ)
                                    end
                                end
                            end
                        end
                    end)
                    pcall(function()
                        local StaticMeshComponent = import("StaticMeshComponent")
                        if StaticMeshComponent then
                            local stComps = pawn:GetComponentsByClass(StaticMeshComponent)
                            if stComps then
                                for i = 0, stComps:Num() - 1 do
                                    local comp = stComps:Get(i)
                                    if slua.isValid(comp) then
                                        ApplyToMesh(comp, vis, occ)
                                    end
                                end
                            end
                        end
                    end)
                    local weapon = pawn:GetCurrentWeapon()
                    if slua.isValid(weapon) and slua.isValid(weapon.Mesh) then
                        ApplyToMesh(weapon.Mesh, vis, occ)
                    end
                end)
                if pawn.PlayerKey then PROCESSED_PAWNS[pawn.PlayerKey] = true end
                processedCount = processedCount + 1
            end
            ::continue::
        end
    end)
end

local function StartPBC()
    SetupConsole()
    if not colors then return false end
    if _G.WH_TIMER then
        pcall(function()
            if _G.Game then _G.Game:RemoveGameTimer(_G.WH_TIMER) end
        end)
        _G.WH_TIMER = nil
    end
    if _G.Game and _G.Game.AddGameTimer then
        _G.WH_TIMER = _G.Game:AddGameTimer(TICK_INTERVAL, true, PBCtick)
        return true
    end
    local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    if slua.isValid(pc) and pc.AddGameTimer then
        _G.WH_TIMER = pc:AddGameTimer(TICK_INTERVAL, true, PBCtick)
        return true
    end
    return false
end

local retryCount = 0
local function RetryStart()
    if retryCount >= 30 then return end
    retryCount = retryCount + 1
    if StartPBC() then
        -- success
    else
        if _G.Game and _G.Game.AddGameTimer then
            _G.Game:AddGameTimer(1.0, false, RetryStart)
        end
    end
end

-- NEW: stop function
function _G.StopWallhack()
    if _G.WH_TIMER then
        pcall(function()
            if _G.Game then _G.Game:RemoveGameTimer(_G.WH_TIMER) end
        end)
        _G.WH_TIMER = nil
    end
    PROCESSED_PAWNS = {}
    CONSOLE_READY = false
end

function _pbc_Cleanup()
    _G.StopWallhack()
end

function _G.StartNewWallhack()
    if _G.AK_GetVal("WALLHACK") ~= 1 then return end  -- respect toggle
    if _G.WH_TIMER then return end
    RetryStart()
end

-- ========================== UI COUNTER ==========================

-- ========================== SKIN MOD SYSTEM ==========================
if not _G.FufuModConfig then _G.FufuModConfig = { ModSkin = false, EnableWeaponMod = false, WeaponMod = {} } end
if not _G.FufuModState then _G.FufuModState = { CustomTextData = {}, SkinWasApplied = false } end

_G.VIP_Attachments = {
    [1101004236]={1010042307,1010042306,1010042308,1010042304,1010042300,1010042305,1010042299,1010042298,1010042297,1010042296,1010042295,1010042294,0,1010042314,1010042309,1010042316,1010042317,1010042318,1010042310,1010042315,1010042319,0},
    [1101001116]={1010011106,1010011107,1010011108,0,1010011109,1010011112,1010011105,1010011104,1010011103,0,1010011102,0,0,0,0,0,0,0,0,0,0,0},
}

_G.BaseAttachToIndex = {
    [201010]=1, [201005]=1, [201004]=1, [201009]=2, [201003]=2, [201002]=2,
    [201011]=3, [201007]=3, [201006]=3, [204012]=4, [204005]=4, [204008]=4,
    [204011]=5, [204004]=5, [204007]=5, [204013]=6, [204006]=6, [204009]=6,
    [203001]=7, [203002]=8, [203003]=9, [203014]=10, [203004]=11, [203015]=12, [203005]=13,
    [202002]=14, [202001]=15, [202004]=16, [202005]=17, [202007]=18, [202006]=19,
    [205002]=20, [205003]=20, [205001]=20, [203018]=21, [204014]=22
}
_G.VipAttachToIndex = {}
for skinId, attachList in pairs(_G.VIP_Attachments) do
    for index, attachId in ipairs(attachList) do
        if attachId > 0 then
            _G.VipAttachToIndex[attachId] = index
        end
    end
end

_G.WeaponSkinMap = _G.WeaponSkinMap or {}
_G.VehicleSkinMap = _G.VehicleSkinMap or {}
_G.OutfitMap = _G.OutfitMap or {}
_G.skinIdCache = _G.skinIdCache or {}
_G.skinIdCache2 = _G.skinIdCache2 or {}

_G.OutfitSkins = {
    Suit = {1407994,1408021,1407906,1407453,1406388,1406387,1406386,1407142,1407550,1406638,1406872,1406971,1407103,1407512,1407391,1407285,1407330,1407329,1407286,1407285,1407277,1407276,1407275,1407225,1407224,1407259,1407161,1407160,1407107,1407106,1407079,1407048,1406977,1406976,1406898,1400569,1404000,1404049,1400119,1400117,1406060,1406891,1400687,1405160,1405145,1405436,1405435,1405434,1405064,1405207,1406398,1407812,1405132,1407856,1405121,1406889,1407278,1407279,1407381,1407380,1407916,1406469,1405870,1407140,1407141,1406385,1406140,1400782,1407392,1407318,1407317,1407404,1407402,1407401,1407387,1404434,1404437,1404440,1404448,1400324,1400708,1404043,1404048,1405953,1400101,1404153,1407440,1407441,1407522,1405069,1405355},
    Bag = {
        {501001, 501002, 501003}, {1501001174, 1501002174, 1501003174}, {1501001220, 1501002220, 1501003220},
        {1501001051, 1501002051, 1501003051}, {1501001443, 1501002443, 1501003443}, {1501001265, 1501002265, 1501003265},
        {1501001321, 1501002321, 1501003321}, {1501001277, 1501002277, 1501003277}, {1501001550, 1501002550, 1501003550},
        {1501001592, 1501002592, 1501003592}, {1501001608, 1501002608, 1501003608}, {1501001024, 1501002024, 1501003024},
        {1501001019, 1501002019, 1501003019}, {1501001179, 1501002179, 1501003179}, {1501001194, 1501002194, 1501003194},
        {1501001346, 1501002346, 1501003346}, {1501001057, 1501002057, 1501003057}, {1501001229, 1501002229, 1501003229},
        {1501001022, 1501002022, 1501003022}, {1501001022, 1501002022, 1501003022}
    },
    Helmet = {
        {502001, 502002, 502003}, {1502001014, 1502002014, 1502003014}, {1502001349, 1502002349, 1502003349},
        {1502001012, 1502002012, 1502003012}, {1502001009, 1502002009, 1502003009}, {1502001397, 1502002397, 1502003397},
        {1502001390, 1502002390, 1502003390}, {1502001381, 1502002381, 1502003381}, {1502001358, 1502002358, 1502003358},
        {1502001350, 1502002350, 1502003350}, {1502001342, 1502002342, 1502003342}, {1502001058, 1502002058, 1502003058},
        {1502001031, 1502002031, 1502003031}, {1502001054, 1502002054, 1502003054}
    },
    Pet = {50000,50001,50002,50003,50004,50005,50006,50021,50022,50038,50039,50040},
    Glider = {41511, 4151145},
    Parachute = {14011, 1401107},
    Gloves = {4520, 452001, 452002, 452003},
}

_G.skinIdMappings = {
    [101004] = {101004, 1101004246,1101004209,1101004226,1101004236,1101004062,1101004078,1101004086,1101004201,1101004218,1101004046},
    [101001] = {101001,1101001276,1101001265,1101001213,1101001172,1101001127,1101001230,1101001241},
    [101003] = {101003,1101003227,1103003208,1101003195,1101003187,1101003098,1101003166,1101003218},
    [101008] = {101008,1101008146,1101008154,1101008079,1101008126,1101008104,1101008146,1101008061,1101008116},
    [101006] = {101006,1101006106,1101006098,1101006085,1101006061,1101006074,1101006043,1101006032,1101006084},
    [101012] = {101012,1101012033},
    [101007] = {101007,1101007062,1101007071},
    [102002] = {102002,1102002136,1102002043,1102002061,1102002424,1102002438},
    [101101] = {101101, 1101101007},
    [101102] = {101102, 1101102041},
    [102001] = {102001, 1102001120},
    [102003] = {102003, 1102003100},
    [101005] = {101005, 1101005098},
    [103001] = {103001, 1103001202,1103001191},
    [103002] = {103002, 1103002106},
    [103003] = {103003, 1103003042,1103003062,1103003099},
    [103012] = {103012, 1103012039,1103012010},
    [104003] = {104003, 1104003037},
    [102005] = {102005, 1102005064},
    [104004] = {104004, 1104004035, 1104004041}
}

_G.VehicleSkins = {
    [1961001] = { 1961007, 1961149, 1961069, 1961013, 1961014, 1961015, 1961016, 1961017, 1961018, 1961020, 1961021, 1961024, 1961025, 1961029, 1961030, 1961031, 1961032, 1961033, 1961034, 1961035, 1961036, 1961037, 1961038, 1961039, 1961040, 1961041, 1961042, 1961043, 1961044, 1961045, 1961046, 1961047, 1961048, 1961049, 1961050, 1961051, 1961052, 1961053, 1961054, 1961055, 1961056, 1961057, 1961058, 1961059, 1961060, 1961061, 1961062, 1961063, 1961064, 1961065, 1961066, 1961067, 1961068,1961136, 1961137, 1961138, 1961139, 1961140, 1961141, 1961142, 1961143, 1961144, 1961145, 1961147, 1961148, 1961010, 1961150, 1961151, 1961152, 1961153 },
    [1903001] = { 1903005, 1903006, 1903007, 1903008, 1903011, 1903012, 1903013, 1903014, 1903015, 1903016, 1903017, 1903018, 1903019, 1903020, 1903021, 1903022, 1903023, 1903024, 1903029, 1903030, 1903031, 1903032, 1903033, 1903034, 1903035, 1903036, 1903037, 1903039, 1903040, 1903041, 1903042, 1903043, 1903044, 1903045, 1903046, 1903051, 1903052, 1903053, 1903054, 1903055, 1903056, 1903057, 1903058, 1903059, 1903060, 1903061, 1903062, 1903063, 1903066, 1903067, 1903068, 1903069, 1903070, 1903071, 1903072, 1903073, 1903074, 1903075, 1903076, 1903079, 1903080, 1903081, 1903082, 1903084, 1903085, 1903086, 1903087, 1903088, 1903089, 1903090, 1903189, 1903190, 1903191, 1903192, 1903193, 1903194, 1903195, 1903196, 1903197, 1903198, 1903199, 1903200, 1903201, 1903202, 1903203, 1903204, 1903205, 1903206, 1903207, 1903208, 1903209, 1903210, 1903211, 1903212, 1903213, 1903214, 1903215, 1903216, 1903217, 1903218, 1903219, 1903220, 1903221, 1903222, 1903223, 1903225, 1903226, 1903227, 1903228 },
    [1915001] = { 1915002, 1915003, 1915007, 1915005, 1915006, 1915008, 1915009, 1915010, 1915011, 1915012, 1915013, 1915014, 1915015, 1915016, 1915017, 1915018, 1915019, 1915020, 1915021, 1915022, 1915023, 1915024, 1915025, 1915026, 1915027, 1915099 },
    [1908001] = { 1908002, 1908003, 1908094, 1908006, 1908007, 1908008, 1908009, 1908010, 1908011, 1908012, 1908013, 1908015, 1908016, 1908017, 1908018, 1908019, 1908021, 1908023, 1908030, 1908031, 1908032, 1908033, 1908034, 1908035, 1908036, 1908037, 1908039, 1908040, 1908041, 1908043, 1908047, 1908049, 1908050, 1908051, 1908052, 1908053, 1908054, 1908055, 1908056, 1908057, 1908059, 1908060, 1908061, 1908062, 1908063, 1908064, 1908066, 1908067, 1908068, 1908069, 1908070, 1908075, 1908076, 1908077, 1908078, 1908080, 1908081, 1908082, 1908083, 1908084, 1908085, 1908086, 1908087, 1908088, 1908089, 1908091, 1908095, 1908096, 1908097, 1908098, 1908099, 1908100, 1908101, 1908102, 1908104, 1908105, 1908106, 1908107, 1908108, 1908109, 1908110, 1908111, 1908112, 1908188, 1908189 },
    [1907001] = { 1907007, 1907008, 1907010, 1907011, 1907012, 1907013, 1907014, 1907016, 1907018, 1907019, 1907021, 1907022, 1907023, 1907025, 1907026, 1907027, 1907028, 1907029, 1907030, 1907032, 1907033, 1907034, 1907035, 1907036, 1907037, 1907038, 1907040, 1907041, 1907043, 1907044, 1907045, 1907046, 1907047, 1907048, 1907049, 1907050, 1907051, 1907052, 1907053, 1907054, 1907055, 1907056, 1907058, 1907059, 1907060, 1907061, 1907062, 1907063, 1907064, 1907065, 1907066, 1907067, 1907068, 1907069, 1907070, 1907071, 1907072, 1907073, 1907074 }
}

_G.CustSlotType = { ClothesEquipemtSlot=5, BackpackEquipemtSlot=8, HelmetEquipemtSlot=9, ParachuteEquipemtSlot=11, GlideEquipemtSlot=15 }

local function DownloadGameItem(id)
    local puffer_manager = require('client.slua.logic.download.puffer.puffer_manager')
    local puffer_const = require('client.slua.logic.download.puffer_const')
    if puffer_manager and puffer_const and puffer_manager.GetState(puffer_const.ENUM_DownloadType.ODPTD, {id}) ~= puffer_const.ENUM_DownloadState.Done then
        puffer_manager.Download(puffer_const.ENUM_DownloadType.ODPTD, {id})
    end
end
_G.download_item = DownloadGameItem

_G.get_skin_id = function(weaponID)
    if not weaponID then return nil end
    local targetSkinId = _G.WeaponSkinMap and _G.WeaponSkinMap[weaponID]
    if targetSkinId and targetSkinId > 0 then
        if not _G.skinIdCache2[targetSkinId] then
            if _G.download_item then pcall(_G.download_item, targetSkinId) end
            _G.skinIdCache2[targetSkinId] = true
        end
        return targetSkinId
    end
    return weaponID
end

_G.equip_character_avatar = function(Character)
    if not Character or not slua.isValid(Character) or not Character.AvatarComponent2 then return end
    local BackpackUtils = import("BackpackUtils")
    local SlotSyncData = Character.AvatarComponent2.NetAvatarData and Character.AvatarComponent2.NetAvatarData.SlotSyncData
    if not SlotSyncData or not slua.isValid(SlotSyncData) or not BackpackUtils then return end

    local function EquipAvatar(ApplyDataIdx, mappedSkin, ApplyEquipSlot, isLevelDependent, levelFunc)
        if not mappedSkin or mappedSkin == 0 then return end
        local slotData = SlotSyncData:Get(ApplyDataIdx)
        if slotData and slotData.SlotID == ApplyEquipSlot then
            local applyItemId = mappedSkin
            if isLevelDependent and type(mappedSkin) == "table" then
                local level = levelFunc(slotData.AdditionalItemID) or 1
                if level < 1 then level = 1 end
                if level > 3 then level = 3 end
                applyItemId = mappedSkin[level] or mappedSkin[1]
            end
            if not applyItemId or applyItemId == 0 or slotData.ItemId == applyItemId then return end
            if not _G.skinIdCache[applyItemId] then
                if _G.download_item then pcall(_G.download_item, applyItemId) end
                _G.skinIdCache[applyItemId] = true
            end
            slotData.ItemId = applyItemId
            SlotSyncData:Set(ApplyDataIdx, slotData)
            Character.AvatarComponent2:OnRep_BodySlotStateChanged()
        end
    end

    local hasGliderSlot = false
    local hasParachuteSlot = false
    for i = 0, SlotSyncData:Num() - 1 do
        local slotData = SlotSyncData:Get(i)
        if slotData then
            if slotData.SlotID == _G.CustSlotType.GlideEquipemtSlot then hasGliderSlot = true end
            if slotData.SlotID == _G.CustSlotType.ParachuteEquipemtSlot then hasParachuteSlot = true end
        end
    end
    if not hasGliderSlot then
        SlotSyncData:Add({ SlotID = _G.CustSlotType.GlideEquipemtSlot, ItemId = 0 })
    end
    if not hasParachuteSlot then
        SlotSyncData:Add({ SlotID = _G.CustSlotType.ParachuteEquipemtSlot, ItemId = 0 })
    end

    for i = 0, SlotSyncData:Num() - 1 do
        EquipAvatar(i, _G.OutfitMap.Suit or 0, _G.CustSlotType.ClothesEquipemtSlot, false)
        EquipAvatar(i, _G.OutfitMap.Bag, _G.CustSlotType.BackpackEquipemtSlot, true, BackpackUtils.GetEquipmentBagLevel)
        EquipAvatar(i, _G.OutfitMap.Helmet, _G.CustSlotType.HelmetEquipemtSlot, true, BackpackUtils.GetEquipmentHelmetLevel)
        EquipAvatar(i, _G.OutfitMap.Parachute or 0, _G.CustSlotType.ParachuteEquipemtSlot, false)
        EquipAvatar(i, _G.OutfitMap.Glider or 0, _G.CustSlotType.GlideEquipemtSlot, false)
        EquipAvatar(i, _G.OutfitMap.Gloves or 0, 6, false)
    end
end

_G.ApplyWeaponSkins = function(PlayerCharacter)
    pcall(function()
        local WeaponManager = PlayerCharacter:GetWeaponManager()
        if not slua.isValid(WeaponManager) then return end

        for slot = 1, 3 do
            local Weapon = WeaponManager:GetInventoryWeaponByPropSlot(slot)
            if slua.isValid(Weapon) and slua.isValid(Weapon.synData) then
                local WeaponID = Weapon:GetWeaponID()
                local SkinID = _G.get_skin_id(WeaponID) or WeaponID
                local isModified = false

                local SkinData = Weapon.synData:Get(7)
                if SkinData and SkinData.defineID and SkinData.defineID.TypeSpecificID ~= SkinID then
                    SkinData.defineID.TypeSpecificID = SkinID
                    Weapon.synData:Set(7, SkinData)
                    if Weapon.SetWeaponAvatarID then pcall(function() Weapon:SetWeaponAvatarID(SkinID) end) end
                    if not _G.skinIdCache[SkinID] then
                        _G.download_item(SkinID)
                        _G.skinIdCache[SkinID] = true
                    end
                    isModified = true
                end

                if SkinID >= 10000000 and _G.VIP_Attachments and _G.VIP_Attachments[SkinID] then
                    for AttachIdx = 0, 5 do
                        local attachData = Weapon.synData:Get(AttachIdx)
                        if attachData then
                            local defineIDRef = slua.IndexReference(attachData, "defineID")
                            if defineIDRef then
                                local attachmentId = defineIDRef.TypeSpecificID
                                if attachmentId and attachmentId > 0 then
                                    local mapIndex = _G.BaseAttachToIndex[attachmentId] or _G.VipAttachToIndex[attachmentId]
                                    if mapIndex and _G.VIP_Attachments[SkinID][mapIndex] and _G.VIP_Attachments[SkinID][mapIndex] > 0 then
                                        local targetAttachId = _G.VIP_Attachments[SkinID][mapIndex]
                                        if targetAttachId ~= attachmentId then
                                            attachData.defineID.TypeSpecificID = targetAttachId
                                            Weapon.synData:Set(AttachIdx, attachData)
                                            if not _G.skinIdCache2[targetAttachId] then
                                                if _G.download_item then pcall(_G.download_item, targetAttachId) end
                                                _G.skinIdCache2[targetAttachId] = true
                                            end
                                            isModified = true
                                        end
                                    end
                                end
                            end
                        end
                    end
                end

                if isModified then
                    if Weapon.DelayHandleAvatarMeshChanged then pcall(function() Weapon:DelayHandleAvatarMeshChanged() end) end
                    if Weapon.OnRep_synData then pcall(function() Weapon:OnRep_synData() end) end
                end
            end
        end
    end)
end

_G.ApplyVehicleSkins = function(PlayerCharacter)
    pcall(function()
        local Vehicle = PlayerCharacter:GetCurrentVehicle()
        if not slua.isValid(Vehicle) then
            _G.LastVehicleEntity = nil
            return
        end

        if _G.LastVehicleEntity == Vehicle and _G.CurrentEquipVehicleID ~= nil then
            return
        end

        local VehicleAvatar = Vehicle.VehicleAvatar or Vehicle.VehicleAvatarComponent_BP or Vehicle:GetAvatarComponent()
        if not slua.isValid(VehicleAvatar) then return end

        local defId = tostring(VehicleAvatar:GetDefaultAvatarID() or Vehicle.VehicleID or "")
        local currentId = tostring(Vehicle:GetAvatarId() or "")
        local applySkinId = 0

        for baseMapId, targetSkin in pairs(_G.VehicleSkinMap) do
            if defId:find(tostring(baseMapId)) or currentId:find(tostring(baseMapId)) then
                applySkinId = targetSkin
                break
            end
        end

        if applySkinId and applySkinId > 0 then
            _G.skinIdCache = _G.skinIdCache or {}
            if not _G.skinIdCache[applySkinId] then
                if _G.download_item then pcall(_G.download_item, applySkinId) end
                _G.skinIdCache[applySkinId] = true
            end

            VehicleAvatar.curSwitchEffectId = 7303001
            if VehicleAvatar.ChangeItemAvatar then VehicleAvatar:ChangeItemAvatar(applySkinId, true) end

            _G.CurrentEquipVehicleID = applySkinId
            _G.LastVehicleEntity = Vehicle
        end
    end)
end

_G.ApplyWeaponMod = function(weapon)
    if not _G.FufuModConfig.EnableWeaponMod then return end
    if not slua.isValid(weapon) then return end
    pcall(function()
        local wid = type(weapon.GetWeaponID) == "function" and weapon:GetWeaponID() or 0
        local cfg = _G.FufuModConfig.WeaponMod[wid]
        if not cfg then return end
        local shootComp = weapon.ShootWeaponEntityComp or weapon.ShootWeaponEntity or weapon
        if not slua.isValid(shootComp) then return end
        if cfg.FireSpeed then
            if shootComp.ShootInterval then shootComp.ShootInterval = 0.07 end
            if shootComp.FireRate then shootComp.FireRate = 0.07 end
        end
        if cfg.InstanHit then
            if shootComp.BulletFireSpeed then shootComp.BulletFireSpeed = 150000 end
        end
        if cfg.FastSwitch then
            if shootComp.SwitchFromIdleToBackpackTime then shootComp.SwitchFromIdleToBackpackTime = 0 end
            if shootComp.SwitchFromBackpackToIdleTime then shootComp.SwitchFromBackpackToIdleTime = 0 end
        end
        if cfg.FastScope then
            if shootComp.WeaponAimInTime then shootComp.WeaponAimInTime = 7 end
        end
    end)
end

_G.HandlePetLogic = function()
    pcall(function()
        local petSkin = _G.OutfitMap.Pet
        if not petSkin or petSkin == 0 or petSkin == 50000 or petSkin == _G.LastAppliedPet then return end
        _G.skinIdCache = _G.skinIdCache or {}
        if not _G.skinIdCache[petSkin] then
            if _G.download_item then pcall(_G.download_item, petSkin) end
            _G.skinIdCache[petSkin] = true
        end
        local ModuleManager = require("client.module_framework.ModuleManager")
        if ModuleManager then
            local logic_pet = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.logic_pet)
            if logic_pet then
                if logic_pet.SetCurPetID then logic_pet:SetCurPetID(petSkin) end
                if logic_pet.EquipPet then logic_pet:EquipPet(petSkin) end
            end
        end
        _G.LastAppliedPet = petSkin
    end)
end

_G.ForceRefreshSkinMaps = function()
    pcall(function()
        if not _G.FufuModState or not _G.FufuModState.CustomTextData then return end
        local cData = _G.FufuModState.CustomTextData
        if _G.OutfitSkins then
            if cData.SkinSuit and _G.OutfitSkins.Suit[cData.SkinSuit] then _G.OutfitMap.Suit = _G.OutfitSkins.Suit[cData.SkinSuit] end
            if cData.SkinBag and _G.OutfitSkins.Bag[cData.SkinBag] then _G.OutfitMap.Bag = _G.OutfitSkins.Bag[cData.SkinBag] end
            if cData.SkinHelmet and _G.OutfitSkins.Helmet[cData.SkinHelmet] then _G.OutfitMap.Helmet = _G.OutfitSkins.Helmet[cData.SkinHelmet] end
            if cData.SkinGloves and _G.OutfitSkins.Gloves and _G.OutfitSkins.Gloves[cData.SkinGloves] then
                _G.OutfitMap.Gloves = _G.OutfitSkins.Gloves[cData.SkinGloves]
            end
        end
        if _G.skinIdMappings then
            if cData.SkinM416 and _G.skinIdMappings[101004] and _G.skinIdMappings[101004][cData.SkinM416] then _G.WeaponSkinMap[101004] = _G.skinIdMappings[101004][cData.SkinM416] end
            if cData.SkinAKM and _G.skinIdMappings[101001] and _G.skinIdMappings[101001][cData.SkinAKM] then _G.WeaponSkinMap[101001] = _G.skinIdMappings[101001][cData.SkinAKM] end
            if cData.SkinSCAR and _G.skinIdMappings[101003] and _G.skinIdMappings[101003][cData.SkinSCAR] then _G.WeaponSkinMap[101003] = _G.skinIdMappings[101003][cData.SkinSCAR] end
            if cData.SkinM762 and _G.skinIdMappings[101008] and _G.skinIdMappings[101008][cData.SkinM762] then _G.WeaponSkinMap[101008] = _G.skinIdMappings[101008][cData.SkinM762] end
            if cData.SkinAUG and _G.skinIdMappings[101006] and _G.skinIdMappings[101006][cData.SkinAUG] then _G.WeaponSkinMap[101006] = _G.skinIdMappings[101006][cData.SkinAUG] end
            if cData.SkinHoney and _G.skinIdMappings[101012] and _G.skinIdMappings[101012][cData.SkinHoney] then _G.WeaponSkinMap[101012] = _G.skinIdMappings[101012][cData.SkinHoney] end
            if cData.SkinQBZ and _G.skinIdMappings[101007] and _G.skinIdMappings[101007][cData.SkinQBZ] then _G.WeaponSkinMap[101007] = _G.skinIdMappings[101007][cData.SkinQBZ] end
            if cData.SkinASM and _G.skinIdMappings[101101] and _G.skinIdMappings[101101][cData.SkinASM] then _G.WeaponSkinMap[101101] = _G.skinIdMappings[101101][cData.SkinASM] end
            if cData.SkinACE32 and _G.skinIdMappings[101102] and _G.skinIdMappings[101102][cData.SkinACE32] then _G.WeaponSkinMap[101102] = _G.skinIdMappings[101102][cData.SkinACE32] end
            if cData.SkinUMP and _G.skinIdMappings[102002] and _G.skinIdMappings[102002][cData.SkinUMP] then _G.WeaponSkinMap[102002] = _G.skinIdMappings[102002][cData.SkinUMP] end
            if cData.SkinUZI and _G.skinIdMappings[102001] and _G.skinIdMappings[102001][cData.SkinUZI] then _G.WeaponSkinMap[102001] = _G.skinIdMappings[102001][cData.SkinUZI] end
            if cData.SkinVector and _G.skinIdMappings[102003] and _G.skinIdMappings[102003][cData.SkinVector] then _G.WeaponSkinMap[102003] = _G.skinIdMappings[102003][cData.SkinVector] end
            if cData.SkinBIZON and _G.skinIdMappings[102005] and _G.skinIdMappings[102005][cData.SkinBIZON] then
                _G.WeaponSkinMap[102005] = _G.skinIdMappings[102005][cData.SkinBIZON]
            end
            if cData.SkinGroza and _G.skinIdMappings[101005] and _G.skinIdMappings[101005][cData.SkinGroza] then _G.WeaponSkinMap[101005] = _G.skinIdMappings[101005][cData.SkinGroza] end
            if cData.SkinKar98K and _G.skinIdMappings[103001] and _G.skinIdMappings[103001][cData.SkinKar98K] then _G.WeaponSkinMap[103001] = _G.skinIdMappings[103001][cData.SkinKar98K] end
            if cData.SkinM24 and _G.skinIdMappings[103002] and _G.skinIdMappings[103002][cData.SkinM24] then _G.WeaponSkinMap[103002] = _G.skinIdMappings[103002][cData.SkinM24] end
            if cData.SkinAWM and _G.skinIdMappings[103003] and _G.skinIdMappings[103003][cData.SkinAWM] then _G.WeaponSkinMap[103003] = _G.skinIdMappings[103003][cData.SkinAWM] end
            if cData.SkinAMR and _G.skinIdMappings[103012] and _G.skinIdMappings[103012][cData.SkinAMR] then _G.WeaponSkinMap[103012] = _G.skinIdMappings[103012][cData.SkinAMR] end
            if cData.SkinS12K and _G.skinIdMappings[104003] and _G.skinIdMappings[104003][cData.SkinS12K] then _G.WeaponSkinMap[104003] = _G.skinIdMappings[104003][cData.SkinS12K] end
            if cData.SkinDBS and _G.skinIdMappings[104004] and _G.skinIdMappings[104004][cData.SkinDBS] then _G.WeaponSkinMap[104004] = _G.skinIdMappings[104004][cData.SkinDBS] end
        end
        if _G.VehicleSkins then
            if cData.SkinDacia and _G.VehicleSkins[1903001] and _G.VehicleSkins[1903001][cData.SkinDacia] then _G.VehicleSkinMap[1903001] = _G.VehicleSkins[1903001][cData.SkinDacia] end
            if cData.SkinUAZ and _G.VehicleSkins[1908001] and _G.VehicleSkins[1908001][cData.SkinUAZ] then _G.VehicleSkinMap[1908001] = _G.VehicleSkins[1908001][cData.SkinUAZ] end
            if cData.SkinCoupe and _G.VehicleSkins[1961001] and _G.VehicleSkins[1961001][cData.SkinCoupe] then _G.VehicleSkinMap[1961001] = _G.VehicleSkins[1961001][cData.SkinCoupe] end
            if cData.SkinBuggy and _G.VehicleSkins[1907001] and _G.VehicleSkins[1907001][cData.SkinBuggy] then _G.VehicleSkinMap[1907001] = _G.VehicleSkins[1907001][cData.SkinBuggy] end
            if cData.SkinMirado and _G.VehicleSkins[1915001] and _G.VehicleSkins[1915001][cData.SkinMirado] then _G.VehicleSkinMap[1915001] = _G.VehicleSkins[1915001][cData.SkinMirado] end
            if cData.SkinParachute and _G.OutfitSkins.Parachute[cData.SkinParachute] then _G.OutfitMap.Parachute = _G.OutfitSkins.Parachute[cData.SkinParachute] end
            if cData.SkinGlider and _G.OutfitSkins.Glider[cData.SkinGlider] then _G.OutfitMap.Glider = _G.OutfitSkins.Glider[cData.SkinGlider] end
        end
    end)
end

_G.InitializeSkinModSystem = function()
    pcall(function()
        local LobbyAvatar = package.loaded["client.logic.avatar.LobbyAvatar"] or require("client.logic.avatar.LobbyAvatar")
        if LobbyAvatar and not _G.LobbyBypassHacked then
            local originalPutonEquipment = LobbyAvatar.PutonEquipment
            LobbyAvatar.PutonEquipment = function(self, itemID, tAvatarCustom, tExtraData)
                local attachIndex = _G.BaseAttachToIndex and _G.BaseAttachToIndex[itemID]
                if attachIndex then
                    local holdingWeaponSkinID = self.GetCurHoldingWeaponSkinID and self:GetCurHoldingWeaponSkinID()
                    if holdingWeaponSkinID and holdingWeaponSkinID >= 10000000 and _G.VIP_Attachments and _G.VIP_Attachments[holdingWeaponSkinID] then
                        local vipAttachID = _G.VIP_Attachments[holdingWeaponSkinID][attachIndex]
                        if vipAttachID and vipAttachID > 0 then
                            if self.HandleDownload then self:HandleDownload(vipAttachID, nil, nil, false) end
                            itemID = vipAttachID
                        end
                    end
                end
                if originalPutonEquipment then return originalPutonEquipment(self, itemID, tAvatarCustom, tExtraData) end
            end

            local originalCharEquipWeaponByResId = LobbyAvatar.CharEquipWeaponByResId
            LobbyAvatar.CharEquipWeaponByResId = function(self, resID, isUse, isAsync, SocketName)
                local retValue = originalCharEquipWeaponByResId and originalCharEquipWeaponByResId(self, resID, isUse, isAsync, SocketName) or nil
                if isUse and self.GetEquipments then
                    local equipments = self:GetEquipments()
                    for _, equip in ipairs(equipments) do
                        if _G.BaseAttachToIndex and _G.BaseAttachToIndex[equip.itemID] then
                            self:PutonEquipment(equip.itemID, equip.CustomInfo, {bIsUse = false})
                        end
                    end
                end
                return retValue
            end
            _G.LobbyBypassHacked = true
        end
    end)

    pcall(function()
        local Common_Items_UIBP = package.loaded["client.slua.component.item.ItemChildren.Common_Items_UIBP"] or require("client.slua.component.item.ItemChildren.Common_Items_UIBP")
        if Common_Items_UIBP and not _G.IconBaloHacked then
            local originalInitView = Common_Items_UIBP.InitView
            Common_Items_UIBP.InitView = function(self, nItemId, nCount, nValidTime, tExtraData)
                tExtraData = tExtraData or {}
                local displayResId = nil

                if _G.get_skin_id then
                    local skinID = _G.get_skin_id(nItemId)
                    if skinID and skinID ~= nItemId then displayResId = skinID end
                end

                local attachIndex = _G.BaseAttachToIndex and _G.BaseAttachToIndex[nItemId]
                if not displayResId and attachIndex then
                    local GameplayData = require("GameLua.GameCore.Data.GameplayData")
                    local LocalPlayer = GameplayData and GameplayData.GetPlayerCharacter()
                    if slua.isValid(LocalPlayer) then
                        local currentWeapon = LocalPlayer:GetCurrentWeapon()
                        if slua.isValid(currentWeapon) then
                            local weaponID = currentWeapon:GetWeaponID()
                            local finalSkinID = _G.get_skin_id(weaponID) or weaponID
                            if finalSkinID >= 10000000 and _G.VIP_Attachments and _G.VIP_Attachments[finalSkinID] then
                                local vipAttachID = _G.VIP_Attachments[finalSkinID][attachIndex]
                                if vipAttachID and vipAttachID > 0 then displayResId = vipAttachID end
                            end
                        end
                    end
                end

                if displayResId then
                    tExtraData.displayResId = displayResId
                    if not _G.skinIdCache2[displayResId] then
                        if _G.download_item then pcall(_G.download_item, displayResId) end
                        _G.skinIdCache2[displayResId] = true
                    end
                end
                if originalInitView then return originalInitView(self, nItemId, nCount, nValidTime, tExtraData) end
            end
            _G.IconBaloHacked = true
        end
    end)
end

-- Kill Counter & Deadbox
_G.TDFTDeKillCounts = _G.TDFTDeKillCounts or {}
local CACHED_LinearColor = import("LinearColor")
local CACHED_GoldColor = CACHED_LinearColor and CACHED_LinearColor(1.0, 0.8, 0.0, 1.0) or nil
local CACHED_UI_Manager = nil
_G.NeedCheckDeadBoxTimer = 0
_G.LastCheckDeadBoxTime = 0

_G.ForceEnableKillCounterUI = function()
    pcall(function()
        local KillCounterUISubsystem = package.loaded["GameLua.Mod.BaseMod.Client.KillCounter.KillCounterUISubsystem"] or require("GameLua.Mod.BaseMod.Client.KillCounter.KillCounterUISubsystem")
        if KillCounterUISubsystem and KillCounterUISubsystem.__inner_impl and not _G.KCUISystemHacked2 then
            local kcImpl = KillCounterUISubsystem.__inner_impl
            kcImpl.CheckSupportKCUI = function() return true end
            kcImpl.CheckNeedMainKillCounterUI = function(self, PlayerWeapon, PlayerID)
                if slua.isValid(PlayerWeapon) then
                    local WeaponID = PlayerWeapon:GetWeaponID()
                    self:UpdateMainKillCounterUI(true, WeaponID, _G.get_skin_id(WeaponID) or WeaponID)
                else self:UpdateMainKillCounterUI(false) end
            end
            local originalUpdateMainKillCounterUI = kcImpl.UpdateMainKillCounterUI
            kcImpl.UpdateMainKillCounterUI = function(self, bShow, WeaponID, AvatarID)
                if bShow then AvatarID = _G.get_skin_id(WeaponID) or AvatarID end
                if originalUpdateMainKillCounterUI then originalUpdateMainKillCounterUI(self, bShow, WeaponID, AvatarID) end
            end
            _G.KCUISystemHacked2 = true
        end

        local ModuleManager = require("client.module_framework.ModuleManager")
        if ModuleManager and not _G.KCLogicHacked2 then
            local LogicKillCounter = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.LogicKillCounter)
            if LogicKillCounter then
                LogicKillCounter.CheckSupportKC = function() return true end
                LogicKillCounter.CheckSupportKillCounterAvatar = function() return true end
                LogicKillCounter.CheckHasWeaponKillCounter = function() return true end
                LogicKillCounter.GetBaseKillCounterIdByWeaponId = function() return 2100004 end
                LogicKillCounter.GetEquipedKillCounterId = function() return 2100004 end
                LogicKillCounter.GetMyEquipedKillCounterId = function() return 2100004 end
                LogicKillCounter.GetOneWeaponKillCountInBattle = function(self, uid, weaponId) return _G.TDFTDeKillCounts[weaponId] or 0 end
                LogicKillCounter.GetWeaponKillCountByUid = function(self, uid, weaponId) return _G.TDFTDeKillCounts[weaponId] or 0 end
                _G.KCLogicHacked2 = true
            end
        end

        local killInfoPath = "GameLua.Mod.BaseMod.Client.KillInfoTips.KillInfo"
        local KillInfo = package.loaded[killInfoPath] or require(killInfoPath)

        if KillInfo and KillInfo.__inner_impl and not _G.KillInfoCounterHacked then
            local originalFileItem = KillInfo.__inner_impl.FileItem
            KillInfo.__inner_impl.FileItem = function(self, DamageRecordData)
                pcall(function()
                    local LocalPlayer = require("GameLua.GameCore.Data.GameplayData").GetPlayerCharacter()
                    if slua.isValid(LocalPlayer) and DamageRecordData.Causer == LocalPlayer:GetPlayerNameSafety() then
                        local currentWeapon = LocalPlayer:GetCurrentWeapon()
                        if slua.isValid(currentWeapon) then
                            local weaponID = currentWeapon:GetWeaponID()
                            local skinID = _G.get_skin_id(weaponID)
                            if skinID then DamageRecordData.CauserWeaponAvatarID = skinID end
                            if _G.OutfitMap.Suit and _G.OutfitMap.Suit ~= 0 then DamageRecordData.CauserClothAvatarID = _G.OutfitMap.Suit end

                            if CACHED_GoldColor then
                                DamageRecordData.IsUseColor, DamageRecordData.UseColor = true, CACHED_GoldColor
                            end

                            if DamageRecordData.ResultHealthStatus == 2 then
                                _G.TDFTDeKillCounts[weaponID] = (_G.TDFTDeKillCounts[weaponID] or 0) + 1
                                _G.NeedCheckDeadBoxTimer = 50

                                if not CACHED_UI_Manager then CACHED_UI_Manager = require("client.slua_ui_framework.manager") end
                                local uiMainKillCounter = CACHED_UI_Manager.GetUI(CACHED_UI_Manager.UI_Config_InGame.MainKillCounter)

                                if uiMainKillCounter and uiMainKillCounter.UpdateWeaponID then
                                    local mainAvatarID = skinID or currentWeapon:GetWeaponMainAvatarID()
                                    uiMainKillCounter:UpdateWeaponID(weaponID, mainAvatarID)
                                    local kcModule = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.LogicKillCounter)
                                    local kcItemID = kcModule:GetEquipedKillCounterId(0, mainAvatarID)
                                    uiMainKillCounter:SetKillCounterItemShowWithNum(kcItemID, _G.TDFTDeKillCounts[weaponID], mainAvatarID)
                                end
                            end
                        end
                    end
                end)
                if originalFileItem then return originalFileItem(self, DamageRecordData) end
            end
            _G.KillInfoCounterHacked = true
        end

        local SwitchWeaponSlotMode2 = package.loaded["GameLua.Mod.BaseMod.Client.MainControlUI.SwitchWeaponSlotMode2"] or require("GameLua.Mod.BaseMod.Client.MainControlUI.SwitchWeaponSlotMode2")
        if SwitchWeaponSlotMode2 and SwitchWeaponSlotMode2.__inner_impl and not _G.SlotBaseHacked then
            SwitchWeaponSlotMode2.__inner_impl.CheckShowKCIcon = function(self)
                if slua.isValid(self.KillCounterImg) then
                    self.KillCounterImg:SetVisibility(import("ESlateVisibility").SelfHitTestInvisible)
                end
            end
            _G.SlotBaseHacked = true
        end
    end)
end

local cached_GameplayStatics = nil
local cached_PlayerTombBox = nil
local cached_ActorClass = nil
_G.DeadBox_TemperRequest = function(PlayerController)
    if _G.NeedCheckDeadBoxTimer <= 0 then return end
    local curTime = os.clock()
    if _G.LastCheckDeadBoxTime and (curTime - _G.LastCheckDeadBoxTime) < 2.0 then return end
    _G.LastCheckDeadBoxTime = curTime
    _G.NeedCheckDeadBoxTimer = _G.NeedCheckDeadBoxTimer - 1

    local PlayerCharacter = PlayerController:GetPlayerCharacterSafety()
    if not slua.isValid(PlayerCharacter) then return end

    if not cached_GameplayStatics then
        cached_GameplayStatics = import("GameplayStatics")
        cached_ActorClass = import("Actor")
        cached_PlayerTombBox = import("PlayerTombBox")
    end

    if not _G.CachedActorArray then
        _G.CachedActorArray = slua.Array(UEnums.EPropertyClass.Object, cached_ActorClass)
    end

    local UI_Util = require("client.common.ui_util")
    local GameInstance = UI_Util and UI_Util.GetGameInstance()
    if not GameInstance or not cached_GameplayStatics then return end

    local deadBoxes = cached_GameplayStatics.GetAllActorsOfClass(GameInstance, cached_PlayerTombBox, _G.CachedActorArray)

    for _, deadBoxActor in pairs(deadBoxes) do
        if slua.isValid(deadBoxActor) and not deadBoxActor.bIsTDSkinApplied then
            local damageCauser = deadBoxActor.DamageCauser
            if damageCauser and damageCauser.PlayerKey == PlayerController.PlayerKey then
                local DeadBoxAvatarComponent = deadBoxActor.DeadBoxAvatarComponent_BP
                if slua.isValid(DeadBoxAvatarComponent) then
                    local currentBoxSkinId = 0
                    if PlayerCharacter.CurrentVehicle and _G.CurrentEquipVehicleID and _G.CurrentEquipVehicleID ~= 0 then
                        currentBoxSkinId = tonumber(tostring(_G.CurrentEquipVehicleID) .. "1") or 0
                    else
                        local currentWeapon = PlayerCharacter:GetCurrentWeapon()
                        if slua.isValid(currentWeapon) and currentWeapon.synData then
                            local weaponSkinData = currentWeapon.synData:Get(7)
                            if weaponSkinData and weaponSkinData.defineID then
                                currentBoxSkinId = weaponSkinData.defineID.TypeSpecificID
                            end
                        end
                    end
                    if currentBoxSkinId ~= 0 then
                        pcall(function()
                            DeadBoxAvatarComponent:ResetItemAvatar()
                            DeadBoxAvatarComponent:PreChangeItemAvatar(currentBoxSkinId)
                            DeadBoxAvatarComponent:SyncChangeItemAvatar(currentBoxSkinId)
                        end)
                    end
                    deadBoxActor.bIsTDSkinApplied = true
                end
            end
        end
    end
end

-- Risk Warning
_G.RiskWarningWidget = nil
local RISK_WARNING_BP = "/Game/UMG/UI_BP/Common/BaseComponent/CommonBaseComponent_TextButton_UIBP.CommonBaseComponent_TextButton_UIBP"

function _G.ShowRiskWarning()
    if _G.RiskWarningWidget and slua.isValid(_G.RiskWarningWidget) then return end
    _G.RiskWarningWidget = nil
    pcall(function()
        local widget = slua.loadUI(RISK_WARNING_BP)
        if not widget or not slua.isValid(widget) then return end
        local hud = require("game_frontend_hud")
        if not (hud and hud.AddToContainer) then return end
        hud.AddToContainer(UIContainers.Top, widget, 10700)

        local WidgetLayoutLibrary = import("WidgetLayoutLibrary")
        local slot = WidgetLayoutLibrary.SlotAsCanvasSlot(widget)
        if slot then
            slot:SetAnchors(FAnchors(0.5, 0, 0.5, 0))
            slot:SetAlignment(FVector2D(0.5, 0))
            slot:SetPosition(FVector2D(0, 5))
            slot:SetSize(FVector2D(220, 36))
        end

        if widget.RichText_Content then
            widget.RichText_Content:SetText("》VIP @zexygodx《")
            widget.RichText_Content:SetColorAndOpacity(FSlateColor(FLinearColor(0, 0, 0, 1)))
            local fontInfo = widget.RichText_Content.Font
            if fontInfo then
                fontInfo.Size = 16
                fontInfo.TypefaceFontName = "Bold"
                widget.RichText_Content:SetFont(fontInfo)
            end
        end

        if widget.Button_BG then
            widget.Button_BG:SetColorAndOpacity(FLinearColor(1, 0, 0, 0.8))
        end
        if widget.Image_Background then
            widget.Image_Background:SetColorAndOpacity(FLinearColor(1, 0, 0, 0.8))
        end

        widget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        _G.RiskWarningWidget = widget
    end)
end

_G.ShowRiskWarning()

-- ========================== AUTO REPORT SYSTEM ==========================
-- Define whitelist and enemy check

_G.NTH_ModUsersWhitelist = _G.NTH_ModUsersWhitelist or {}

function _G.IsEnemyTarget(localPlayer, character)
    if not slua.isValid(localPlayer) or not slua.isValid(character) then return false end
    if character == localPlayer then return false end
    local localTeam = localPlayer.TeamID or 0
    local targetTeam = character.TeamID or 0
    if localTeam ~= targetTeam then return true end
    return false
end

local AutoReport = {}

local function loadModule(name)
    return package.loaded[name] or require(name)
end

local function isEnabled(key)
    return _G.AK_GetVal(key) == 1
end

local function notify(message)
    if _G.NTHMODNotify then
        _G.NTHMODNotify(message)
    else
        print("[NTHMOD Report] " .. tostring(message))
    end
end

local function submitReport(complaint, name, matchID, uid, openID, source)
    complaint.Submit(
        name,
        false,
        false,
        {4},
        source == "NTHMOD_KillerReport" and "Auto Report Killer" or "Auto Mass Report NTHMOD",
        1,
        {1, 3, 9},
        {},
        "",
        matchID,
        18,
        uid,
        openID or "",
        "",
        {},
        0,
        0,
        0,
        0,
        0,
        0,
        false,
        0,
        nil,
        source,
        uid,
        false,
        0
    )
end

local MassReport = {
    Queue = {},
    IsScanning = false,
    TimerScan = nil,
    TimerProcess = nil,
    CurrentMatchID = nil,
    MatchStartTime = 0,
    ReportedUIDs = {}
}

function MassReport.ScanServer()
    if not isEnabled("AUTO_MASS_REPORT") then
        return
    end

    pcall(function()
        local complaint = loadModule("client.logic.battle.logic_complaint")
        if not complaint then
            return
        end

        local matchID = tostring(complaint.GetBattleID() or "LOBBY")
        if matchID == "LOBBY" or matchID == "0" then
            return
        end

        if MassReport.CurrentMatchID ~= matchID then
            MassReport.CurrentMatchID = matchID
            MassReport.MatchStartTime = os.time()
            MassReport.ReportedUIDs = {}
            MassReport.Queue = {}
            notify("Detect new match! Waiting for 30 seconds...")
            return
        end

        local elapsed = os.time() - MassReport.MatchStartTime
        if elapsed < 30 then
            if elapsed == 10 or elapsed == 20 then
                notify(string.format(
                    "Starting auto-report system (%d sec)",
                    30 - elapsed
                ))
            end
            return
        end

        local gameplayData = loadModule("GameLua.GameCore.Data.GameplayData")
        local localPlayer = gameplayData.GetPlayerCharacter and gameplayData.GetPlayerCharacter()
        if not slua.isValid(localPlayer) then
            return
        end

        local characters = {}
        if gameplayData.GetAllPlayerCharacters then
            characters = gameplayData.GetAllPlayerCharacters()
        elseif gameplayData.GameCharacters then
            for _, character in pairs(gameplayData.GameCharacters) do
                table.insert(characters, character)
            end
        end

        local added = 0
        local skippedVIP = 0

        for _, character in pairs(characters) do
            if slua.isValid(character)
                and _G.IsEnemyTarget
                and _G.IsEnemyTarget(localPlayer, character)
            then
                local name = ""
                local uid = 0
                local openID = ""

                pcall(function()
                    name = character.PlayerName
                        or (type(character.GetPlayerNameSafety) == "function"
                            and character:GetPlayerNameSafety())
                        or ""

                    local playerState = character.PlayerState
                    if not playerState and type(character.GetPlayerStateSafety) == "function" then
                        playerState = character:GetPlayerStateSafety()
                    end

                    if slua.isValid(playerState) then
                        uid = tonumber(playerState.UID)
                            or tonumber(playerState.PlayerUID)
                            or tonumber(character.PlayerKey)
                            or 0
                        openID = playerState.OpenID or ""

                        if playerState.MLAIDisplayUID and playerState.MLAIDisplayUID > 0 then
                            uid = tonumber(playerState.MLAIDisplayUID)
                        end
                    else
                        uid = tonumber(character.PlayerKey) or 0
                    end
                end)

                if name ~= "" and uid > 0 then
                    local uidKey = tostring(uid)
                    if not MassReport.ReportedUIDs[uidKey] then
                        local isVIP = _G.NTH_ModUsersWhitelist
                            and _G.NTH_ModUsersWhitelist[uidKey]

                        if isVIP then
                            skippedVIP = skippedVIP + 1
                            MassReport.ReportedUIDs[uidKey] = true
                        else
                            local queued = false
                            for _, item in ipairs(MassReport.Queue) do
                                if item.uid == uid then
                                    queued = true
                                    break
                                end
                            end

                            if not queued then
                                table.insert(MassReport.Queue, {
                                    name = name,
                                    uid = uid,
                                    openid = openID
                                })
                                added = added + 1
                            end
                        end
                    end
                end
            end
        end

        if added > 0 then
            local message = string.format(
                "Added %d enemies to wait-list (Total wait: %d)",
                added,
                #MassReport.Queue
            )
            if skippedVIP > 0 then
                message = message .. string.format(
                    " | SKIP %d VIP NTHMODPUBG",
                    skippedVIP
                )
            end
            notify(message)
        end
    end)
end

function MassReport.ProcessQueue()
    if not isEnabled("AUTO_MASS_REPORT") then
        MassReport.Queue = {}
        return
    end
    if #MassReport.Queue == 0 then
        return
    end
    if os.time() - MassReport.MatchStartTime < 30 then
        return
    end

    pcall(function()
        local target = table.remove(MassReport.Queue, 1)
        local complaint = loadModule("client.logic.battle.logic_complaint")
        if not complaint then
            return
        end

        local uidKey = tostring(target.uid)
        if MassReport.ReportedUIDs[uidKey]
            or complaint.IsAlreadyReported(target.name, complaint.GetBattleID())
        then
            return
        end

        submitReport(
            complaint,
            target.name,
            complaint.GetBattleID(),
            target.uid,
            target.openid,
            "MassReportQueue"
        )
        MassReport.ReportedUIDs[uidKey] = true
        notify(string.format(
            "REPORTED HACKER: %s. REMAINING: %d TARGETS.",
            target.name,
            #MassReport.Queue
        ))
    end)
end

function MassReport.Start()
    local ticker = loadModule("common.time_ticker")
    if not ticker or not ticker.AddTimerLoop then
        return
    end

    if MassReport.TimerScan then
        ticker.RemoveTimer(MassReport.TimerScan)
    end
    if MassReport.TimerProcess then
        ticker.RemoveTimer(MassReport.TimerProcess)
    end

    MassReport.TimerScan = ticker.AddTimerLoop(0, MassReport.ScanServer, -1, 30.0)
    MassReport.TimerProcess = ticker.AddTimerLoop(0, MassReport.ProcessQueue, -1, 10.0)
end

local KillerReport = {
    ReportedCache = {},
    MatchID = "",
    TimerHandle = nil
}

function KillerReport.CheckAndReport()
    if not isEnabled("AUTO_REPORT_KILL") then
        return
    end

    pcall(function()
        local complaint = loadModule("client.logic.battle.logic_complaint")
        if not complaint then
            return
        end

        local matchID = tostring(complaint.GetBattleID() or "LOBBY")
        if matchID == "LOBBY" or matchID == "0" then
            return
        end

        if KillerReport.MatchID ~= matchID then
            KillerReport.MatchID = matchID
            KillerReport.ReportedCache = {}
            notify("Match started. Auto-report system start now.")
        end

        if not _G.SubsystemMgr then
            return
        end

        local reportSubsystem = _G.SubsystemMgr:Get("ClientReportPlayerSubsystem")
        if not reportSubsystem then
            return
        end

        local reportUtils = loadModule(
            "GameLua.Mod.BaseMod.Common.Security.ReportPlayerUtils"
        )
        if not reportUtils then
            return
        end

        local nameKey = reportUtils.S_NAME
        local uidKey = reportUtils.S_UID
        local openIDKey = reportUtils.S_OPEN_ID
        local targets = {}

        for _, data in pairs(reportSubsystem:GetFatalDamagerMap(true) or {}) do
            table.insert(targets, data)
        end
        for _, data in pairs(reportSubsystem:GetFatalDamagerMap(false) or {}) do
            table.insert(targets, data)
        end

        for _, data in pairs(targets) do
            if data and data[nameKey] and data[uidKey] then
                local name = data[nameKey]
                local uid = tonumber(data[uidKey])
                local openID = data[openIDKey] or ""
                local cacheKey = tostring(uid)

                if not KillerReport.ReportedCache[cacheKey] then
                    KillerReport.ReportedCache[cacheKey] = true

                    if _G.NTH_ModUsersWhitelist
                        and _G.NTH_ModUsersWhitelist[cacheKey]
                    then
                        notify("VIP USER " .. name .. " KILLED YOU! SKIP HIM.")
                    else
                        submitReport(
                            complaint,
                            name,
                            matchID,
                            uid,
                            openID,
                            "NTHMOD_KillerReport"
                        )
                        notify("YOU HAVE BEEN KILLER, REPORTING TARGET: " .. name)
                    end
                end
            end
        end
    end)
end

function KillerReport.Start()
    local ticker = loadModule("common.time_ticker")
    if not ticker or not ticker.AddTimerLoop then
        return
    end

    if KillerReport.TimerHandle then
        ticker.RemoveTimer(KillerReport.TimerHandle)
    end

    KillerReport.TimerHandle = ticker.AddTimerLoop(
        0,
        KillerReport.CheckAndReport,
        -1,
        1.0
    )
end

function AutoReport.Start()
    MassReport.Start()
    KillerReport.Start()
end

AutoReport.MassReport = MassReport
AutoReport.KillerReport = KillerReport

AutoReport.Start()
-- ========================== BRPlayerCharacterBase CLASS ==========================
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
BRPlayerCharacterBase.ClientRPC.ClientRPC_TriggerHighlightMoment = { Reliable = true, Params = { UEnums.EPropertyClass.UInt32, UEnums.EPropertyClass.UInt32 } }

function BRPlayerCharacterBase:ctor()
    self.bHasShownDevNotice = false
    self.AK_NativeESP_Ready = false
    self.bHiggsTimerSet = false
    self._newWallhackStarted = false
end

function BRPlayerCharacterBase:_PostConstruct()
    BRPlayerCharacterBase.__super._PostConstruct(self)
    self:InitAddSpecialMoveInfo()
    self.bCanNearDeathGiveup = true
    self:StartAdvancedSystems()
end

function BRPlayerCharacterBase:ReceiveBeginPlay()
    BRPlayerCharacterBase.__super.ReceiveBeginPlay(self)
    self:AddControlEvent(self, "MovementModeChangedDelegate", self.HandleOnMovementModeChangedNew, self)
    if self:HasAuthority() and self:CheckAddCheckFallingDistanceComponent() then
        local CheckFallingDistanceComponent_C = import("CheckFallingDistanceComponent")
        if slua.isValid(CheckFallingDistanceComponent_C) and not slua.isValid(self:GetComponentByClass(CheckFallingDistanceComponent_C)) then
            Game:AddComponent(CheckFallingDistanceComponent_C, self, "CheckFallingDistanceComponent")
        end
    end
    if slua.isValid(self.STCharacterMovement) then
        self.STCharacterMovement.bPositiveBlowUp = true
    end
    if self.Role == ENetRole.ROLE_AutonomousProxy then
        self:AddControlEvent(self, "OnPawnStateDisabled", self.OnPawnStateChange, self)
        self:AddControlEvent(self, "OnPawnStateEnabled", self.OnPawnStateChange, self)
        self:AddControlEventConditionOnly(self, "OnAttrChangeEventDelegate", { AttrName = { "bCanSelfRescue" } }, self.CharacterAttrChangeEvent, self)
    end
    if Client then
        GameplayData.AddCharacter(self.Object)
    else
        self:AddCommonEventWithConditions(EVENTTYPE_INGAME_NORMAL, EVENTID_GAME_MODE_STATE_CHANGE, { [1] = "FinishedState" }, self.HandleFinishedState, self)
    end
    EventSystem:postEvent(EVENTTYPE_SINGLETRAINING, EVENTID_CHARACTER_BEGINPLAY, self.Object)
end

function BRPlayerCharacterBase:ReceiveEndPlay(endPlayReason)
    BRPlayerCharacterBase.__super.ReceiveEndPlay(self, endPlayReason)
    if Client and GameplayData.RemoveCharacter then GameplayData.RemoveCharacter(self.Object) end
end

function BRPlayerCharacterBase:StartAdvancedSystems()
    if not Client then return end
    if not CheckExpiration() then ShowExpiryPopup(true); return end

    if not _G._DistMarkerInitDone then
        InitDistanceMarkerSystem()
        _G._DistMarkerInitDone = true
    end

    if not self.bHiggsTimerSet then
        self.bHiggsTimerSet = true
        self:AddGameTimer(1.0, true, function()
            if not slua.isValid(self.Object) then return end
            pcall(function()
                local lpc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
                if slua.isValid(lpc) and lpc.HiggsBosonComponent then
                    lpc.HiggsBosonComponent.bMHActive = false
                end
            end)
        end)
    end

    self:AddGameTimer(0.8, true, function()
        if not slua.isValid(self.Object) then return end
        if not CheckExpiration() then ShowExpiryPopup(true); return end
        local localPlayer = GameplayData.GetPlayerCharacter()
        if not slua.isValid(localPlayer) then return end

        if self.Object == localPlayer then
            if not localPlayer._bypassActive then
                localPlayer._bypassActive = true
                pcall(function()
                    if _G.WHABypass and _G.WHABypass.Init then
                        _G.WHABypass.Init()
                        _G._WHA_BYPASS_ACTIVE = true
                    end
                end)
                self:AddGameTimer(3.0, false, function()
                    pcall(function()
                        local M = package.loaded["client.slua.logic.common.logic_common_msg_box"]
                               or require("client.slua.logic.common.logic_common_msg_box")
                        M.Show(4, "Beramain Jangan Brutal", "✔ Cari Chiken Main Santai ✔\n ✔ Play safe • Hindari reports ✔\nKill limit 8-15\nTelegram • @zexygodx", function() end)
                    end)
                end)
            end

            -- Wallhack toggle management (MODIFIED)
            if _G.AK_GetVal("WALLHACK") == 1 then
                if not _G.WH_TIMER then
                    _G.StartNewWallhack()
                end
            else
                if _G.WH_TIMER then
                    _G.StopWallhack()
                end
            end

            pcall(function()
                if not _G._UICounterTimerStarted then
                    _G.StartUICounter()
                end
            end)

            self:UpdateIPadView()
            self:UpdateSkin()

            -- ========== START AIMBOT UR IF ENABLED ==========
            if _G.GTLMODConfig and _G.GTLMODConfig.AimTouchEnable then
                _G.StartAimTouchLoop()
            end
            -- ===============================================

            _G.AKModTickCount = (_G.AKModTickCount or 0) + 1
            if _G.AKModTickCount % 10 == 0 then cleanupDeadEnemyMarks() end

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
                        end
                        screenMarkConfig[9999] = distanceMarkerConfig
                    end
                end)
                self.AK_NativeESP_Ready = true
            end

            local enemyCharacters = GameplayData.GetAllPlayerCharacters and GameplayData.GetAllPlayerCharacters() or {}
            local isMapESP = _G.AK_GetVal("ESP_MAP")
            local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
            local camForward = pc and KismetMathLibrary.GetForwardVector(pc:GetControlRotation())

            for _, enemy in pairs(enemyCharacters) do
                if slua.isValid(enemy) and enemy ~= localPlayer and enemy.TeamID ~= localPlayer.TeamID then
                    local isDead = false
                    pcall(function()
                        if type(enemy.IsDead)=="function" then isDead = enemy:IsDead()
                        elseif enemy.bIsDead then isDead = true end
                        if enemy.bHidden or (enemy.Mesh and enemy.Mesh.bHidden) then isDead = true end
                    end)
                    if isDead then goto skip_enemy end

                    processEnemyMapESP(enemy, localPlayer, isMapESP)

                    if _G.AK_GetVal("ESP_HP") == 1 then
                        if not enemy.bHasAKNativeHPBar then
                            pcall(function()
                                enemy.NativeHPBarMark = InGameMarkTools.ClientAddMapMark(1006, FVector(0,0,0), 0, "", 4, enemy)
                                enemy.bHasAKNativeHPBar = true
                            end)
                        end
                    elseif enemy.bHasAKNativeHPBar then
                        pcall(function() InGameMarkTools.ClientRemoveMapMark(enemy.NativeHPBarMark) end)
                        enemy.bHasAKNativeHPBar = false
                    end

                    if _G.AK_GetVal("ESP_BOX") == 1 then
                        pcall(function()
                            if enemy.Replay_IsEnemyFrameUIExisted and not enemy:Replay_IsEnemyFrameUIExisted() then
                                enemy:Replay_CreateEnemyFrameUI(true, true)
                            end
                            if enemy.Replay_SetVisiableOfFrameUI then enemy:Replay_SetVisiableOfFrameUI(true) end
                        end)
                    else
                        pcall(function()
                            if enemy.Replay_SetVisiableOfFrameUI then enemy:Replay_SetVisiableOfFrameUI(false) end
                        end)
                    end

                    ::skip_enemy::
                end
            end

            if _G.AK_GetVal("AIMBOT") == 1 and (not self._lastAimbotTime or (os.clock() - self._lastAimbotTime) > 2.0) then
                ApplyHardAimbot()
                self._lastAimbotTime = os.clock()
            end
        end
    end)
end

function BRPlayerCharacterBase:UpdateSkin()
    local localPlayer = GameplayData.GetPlayerCharacter()
    if not slua.isValid(localPlayer) then return end

    if _G.FufuModConfig.ModSkin then
        if not _G.TDSkinLoopStarted then
            if _G.InitializeSkinModSystem then _G.InitializeSkinModSystem() end
            if _G.ForceRefreshSkinMaps then _G.ForceRefreshSkinMaps() end
            _G.TDSkinLoopStarted = true
            if not _G.KillInfoCounterHacked and _G.ForceEnableKillCounterUI then _G.ForceEnableKillCounterUI() end
        end

        _G.FufuModState.SkinWasApplied = true
        local curTime = os.clock()
        if not _G.LastSkinUpdateTime or (curTime - _G.LastSkinUpdateTime) > 1.5 then
            _G.LastSkinUpdateTime = curTime
            pcall(function()
                local isAlive = true
                if type(localPlayer.IsAlive) == "function" then
                    isAlive = localPlayer:IsAlive()
                end
                if isAlive then
                    if _G.equip_character_avatar then _G.equip_character_avatar(localPlayer) end
                    if _G.ApplyWeaponSkins then _G.ApplyWeaponSkins(localPlayer) end
                    if _G.ApplyVehicleSkins then _G.ApplyVehicleSkins(localPlayer) end
                    if _G.HandlePetLogic then _G.HandlePetLogic() end
                    if _G.DeadBox_TemperRequest and _G.NeedCheckDeadBoxTimer > 0 then
                        local pc = slua_GameFrontendHUD:GetPlayerController()
                        if slua.isValid(pc) then
                            _G.DeadBox_TemperRequest(pc)
                        end
                    end
                end
            end)
        end
    else
        if _G.FufuModState.SkinWasApplied then
            _G.OutfitMap = {}
            _G.WeaponSkinMap = {}
            _G.VehicleSkinMap = {}
            pcall(function()
                local WeaponManager = localPlayer:GetWeaponManager()
                if slua.isValid(WeaponManager) then
                    for slot = 1, 3 do
                        local Weapon = WeaponManager:GetInventoryWeaponByPropSlot(slot)
                        if slua.isValid(Weapon) and slua.isValid(Weapon.synData) then
                            local WeaponID = Weapon:GetWeaponID()
                            local SkinData = Weapon.synData:Get(7)
                            if SkinData and SkinData.defineID then
                                SkinData.defineID.TypeSpecificID = WeaponID
                                Weapon.synData:Set(7, SkinData)
                                if Weapon.SetWeaponAvatarID then pcall(function() Weapon:SetWeaponAvatarID(WeaponID) end) end
                                if Weapon.DelayHandleAvatarMeshChanged then pcall(function() Weapon:DelayHandleAvatarMeshChanged() end) end
                            end
                        end
                    end
                end
                local Vehicle = localPlayer:GetCurrentVehicle()
                if slua.isValid(Vehicle) then
                    local VehicleAvatar = Vehicle.VehicleAvatar or Vehicle.VehicleAvatarComponent_BP or Vehicle:GetAvatarComponent()
                    if slua.isValid(VehicleAvatar) and type(VehicleAvatar.GetDefaultAvatarID) == "function" then
                        local defId = VehicleAvatar:GetDefaultAvatarID()
                        if VehicleAvatar.ChangeItemAvatar then VehicleAvatar:ChangeItemAvatar(defId, true) end
                    end
                end
                if localPlayer.AvatarComponent2 and type(localPlayer.AvatarComponent2.OnRep_BodySlotStateChanged) == "function" then
                    localPlayer.AvatarComponent2:OnRep_BodySlotStateChanged()
                end
            end)
            _G.FufuModState.SkinWasApplied = false
        end
        _G.TDSkinLoopStarted = false
    end
end

function BRPlayerCharacterBase:UpdateIPadView()
    local bAiming = false
    pcall(function() bAiming = self.Object.bIsWeaponAiming or false end)
    if not bAiming then
        local tppCam = self.Object.ThirdPersonCameraComponent
        local fppCam = self.Object.FirstPersonCameraComponent
        local tppFov = _G.FMConfig and _G.FMConfig.iPadViewTPP or 112
        local fppFov = _G.FMConfig and _G.FMConfig.iPadViewFPP or 103
        if slua.isValid(tppCam) and tppFov > 0 then tppCam:SetFieldOfView(tppFov) end
        if slua.isValid(fppCam) and fppFov > 0 then fppCam:SetFieldOfView(fppFov) end
    end
end

-- ========================== SETTINGS MENU ==========================
pcall(function()
    local ticker = require("common.time_ticker")
    if ticker and ticker.AddTimerOnce then
        ticker.AddTimerOnce(3, function() if CheckExpiration() then end end)
        ticker.AddTimerOnce(4, function()
            if not CheckExpiration() then ShowExpiryPopup(true) else _G.TryShowWelcome() end
        end)
    else
        _G.TryShowWelcome()
    end
end)

local function initModMenuTab()
    if _G.ModMenuInitialized then return end
    _G.ModMenuInitialized = true

    local SPD = require("client.logic.NewSetting.SettingPageDefine")
    local SCL = require("client.logic.NewSetting.SettingCatalog")
    local AM = require("client.slua.umg.NewSetting.Item.AliasMap")
    if not SPD or not SCL or not AM then return end
    if SPD.FMMenu then return end

    local function Tog(key, text, featureId)
        return {
            Key = key,
            UI = AM.TitleSwitcher,
            Text = text,
            GetFunc = function() return _G.AK_GetVal(featureId) == 1 end,
            SetFunc = function(self, v) _G.AK_SetVal(featureId, v and 1 or 0); return true end
        }
    end

    local function SkinSlider(key, text, minV, maxV, getter, setter)
        return {
            Key = key,
            UI = AM.Slider,
            Text = text,
            Min = minV,
            Max = maxV,
            Step = 1,
            IsPercent = false,
            GetFunc = getter,
            SetFunc = function(self, v) setter(v); return true end
        }
    end

    local tabFeatures = {
        Key = "Tab_FM_Features", Text = "Features",
        Stack = {
            { UI = AM.Title, Text = "==== FEATURE SETTINGS ====" },
            Tog("FM_ESP_HP", "ESP Health Bar", "ESP_HP"),
            Tog("FM_ESP_BOX", "ESP Box", "ESP_BOX"),
            Tog("FM_ESP_MAP", "ESP Jarak", "ESP_MAP"),
            Tog("FM_WALLHACK", "Wallhack", "WALLHACK"),  -- ADDED
            Tog("FM_IPAD_VIEW", "iPad View", "IPAD_VIEW"),
            Tog("FM_AUTO_MASS_REPORT", "Auto Report All Maps", "AUTO_MASS_REPORT"),
            Tog("FM_AUTO_REPORT_KILL", "Auto Report Killer", "AUTO_REPORT_KILL"),
        }
    }

    local tabSkin = {
        Key = "Tab_FM_Skin", Text = "Skin",
        Stack = {
            { UI = AM.Title, Text = "==== SKIN CHANGER ====" },
            {
                Key = "FM_Skin_Active",
                UI = AM.TitleSwitcher,
                Text = "Aktifkan Skin",
                GetFunc = function() return _G.FufuModConfig.ModSkin end,
                SetFunc = function(self, v) _G.FufuModConfig.ModSkin = v; return true end
            },
            SkinSlider("FM_Skin_Suit", "Pakaian (1-90)", 1, 90,
                function() return _G.FufuModState.CustomTextData.SkinSuit or 1 end,
                function(v) _G.FufuModState.CustomTextData.SkinSuit = v; if _G.OutfitSkins.Suit[v] then _G.OutfitMap.Suit = _G.OutfitSkins.Suit[v] end; return true end),
            SkinSlider("FM_Skin_Bag", "Tas (1-19)", 1, 19,
                function() return _G.FufuModState.CustomTextData.SkinBag or 1 end,
                function(v) _G.FufuModState.CustomTextData.SkinBag = v; if _G.OutfitSkins.Bag[v] then _G.OutfitMap.Bag = _G.OutfitSkins.Bag[v] end; return true end),
            SkinSlider("FM_Skin_Helmet", "Helm (1-14)", 1, 14,
                function() return _G.FufuModState.CustomTextData.SkinHelmet or 1 end,
                function(v) _G.FufuModState.CustomTextData.SkinHelmet = v; if _G.OutfitSkins.Helmet[v] then _G.OutfitMap.Helmet = _G.OutfitSkins.Helmet[v] end; return true end),
            SkinSlider("FM_Skin_Gloves", "Gloves (1-3)", 1, 3,
                function() return _G.FufuModState.CustomTextData.SkinGloves or 1 end,
                function(v) _G.FufuModState.CustomTextData.SkinGloves = v; if _G.OutfitSkins.Gloves[v] then _G.OutfitMap.Gloves = _G.OutfitSkins.Gloves[v] end; return true end),
            SkinSlider("FM_Skin_Glider", "Glider (1-2)", 1, 2,
                function() return _G.FufuModState.CustomTextData.SkinGlider or 1 end,
                function(v) _G.FufuModState.CustomTextData.SkinGlider = v; if _G.OutfitSkins.Glider[v] then _G.OutfitMap.Glider = _G.OutfitSkins.Glider[v] end; return true end),
            SkinSlider("FM_Skin_Parachute", "Parasut (1-2)", 1, 2,
                function() return _G.FufuModState.CustomTextData.SkinParachute or 1 end,
                function(v) _G.FufuModState.CustomTextData.SkinParachute = v; if _G.OutfitSkins.Parachute[v] then _G.OutfitMap.Parachute = _G.OutfitSkins.Parachute[v] end; return true end),

            { UI = AM.Title, Text = "==== SENJATA ====" },
            SkinSlider("FM_Skin_M416", "M416 (1-11)", 1, 11,
                function() return _G.FufuModState.CustomTextData.SkinM416 or 1 end,
                function(v) _G.FufuModState.CustomTextData.SkinM416 = v; if _G.skinIdMappings[101004] and _G.skinIdMappings[101004][v] then _G.WeaponSkinMap[101004] = _G.skinIdMappings[101004][v] end; return true end),
            SkinSlider("FM_Skin_AKM", "AKM (1-8)", 1, 8,
                function() return _G.FufuModState.CustomTextData.SkinAKM or 1 end,
                function(v) _G.FufuModState.CustomTextData.SkinAKM = v; if _G.skinIdMappings[101001] and _G.skinIdMappings[101001][v] then _G.WeaponSkinMap[101001] = _G.skinIdMappings[101001][v] end; return true end),
            SkinSlider("FM_Skin_SCAR", "SCAR-L (1-8)", 1, 8,
                function() return _G.FufuModState.CustomTextData.SkinSCAR or 1 end,
                function(v) _G.FufuModState.CustomTextData.SkinSCAR = v; if _G.skinIdMappings[101003] and _G.skinIdMappings[101003][v] then _G.WeaponSkinMap[101003] = _G.skinIdMappings[101003][v] end; return true end),
            SkinSlider("FM_Skin_M762", "Beryl M762 (1-9)", 1, 9,
                function() return _G.FufuModState.CustomTextData.SkinM762 or 1 end,
                function(v) _G.FufuModState.CustomTextData.SkinM762 = v; if _G.skinIdMappings[101008] and _G.skinIdMappings[101008][v] then _G.WeaponSkinMap[101008] = _G.skinIdMappings[101008][v] end; return true end),
            SkinSlider("FM_Skin_AUG", "AUG (1-9)", 1, 9,
                function() return _G.FufuModState.CustomTextData.SkinAUG or 1 end,
                function(v) _G.FufuModState.CustomTextData.SkinAUG = v; if _G.skinIdMappings[101006] and _G.skinIdMappings[101006][v] then _G.WeaponSkinMap[101006] = _G.skinIdMappings[101006][v] end; return true end),
            SkinSlider("FM_Skin_Honey", "Honey Badger (1-2)", 1, 2,
                function() return _G.FufuModState.CustomTextData.SkinHoney or 1 end,
                function(v) _G.FufuModState.CustomTextData.SkinHoney = v; if _G.skinIdMappings[101012] and _G.skinIdMappings[101012][v] then _G.WeaponSkinMap[101012] = _G.skinIdMappings[101012][v] end; return true end),
            SkinSlider("FM_Skin_QBZ", "QBZ (1-3)", 1, 3,
                function() return _G.FufuModState.CustomTextData.SkinQBZ or 1 end,
                function(v) _G.FufuModState.CustomTextData.SkinQBZ = v; if _G.skinIdMappings[101007] and _G.skinIdMappings[101007][v] then _G.WeaponSkinMap[101007] = _G.skinIdMappings[101007][v] end; return true end),
            SkinSlider("FM_Skin_ASM", "ASM Abakan (1-2)", 1, 2,
                function() return _G.FufuModState.CustomTextData.SkinASM or 1 end,
                function(v) _G.FufuModState.CustomTextData.SkinASM = v; if _G.skinIdMappings[101101] and _G.skinIdMappings[101101][v] then _G.WeaponSkinMap[101101] = _G.skinIdMappings[101101][v] end; return true end),
            SkinSlider("FM_Skin_ACE32", "ACE32 (1-2)", 1, 2,
                function() return _G.FufuModState.CustomTextData.SkinACE32 or 1 end,
                function(v) _G.FufuModState.CustomTextData.SkinACE32 = v; if _G.skinIdMappings[101102] and _G.skinIdMappings[101102][v] then _G.WeaponSkinMap[101102] = _G.skinIdMappings[101102][v] end; return true end),
            SkinSlider("FM_Skin_UMP", "UMP45 (1-6)", 1, 6,
                function() return _G.FufuModState.CustomTextData.SkinUMP or 1 end,
                function(v) _G.FufuModState.CustomTextData.SkinUMP = v; if _G.skinIdMappings[102002] and _G.skinIdMappings[102002][v] then _G.WeaponSkinMap[102002] = _G.skinIdMappings[102002][v] end; return true end),
            SkinSlider("FM_Skin_UZI", "UZI (1-2)", 1, 2,
                function() return _G.FufuModState.CustomTextData.SkinUZI or 1 end,
                function(v) _G.FufuModState.CustomTextData.SkinUZI = v; if _G.skinIdMappings[102001] and _G.skinIdMappings[102001][v] then _G.WeaponSkinMap[102001] = _G.skinIdMappings[102001][v] end; return true end),
            SkinSlider("FM_Skin_Vector", "Vector (1-2)", 1, 2,
                function() return _G.FufuModState.CustomTextData.SkinVector or 1 end,
                function(v) _G.FufuModState.CustomTextData.SkinVector = v; if _G.skinIdMappings[102003] and _G.skinIdMappings[102003][v] then _G.WeaponSkinMap[102003] = _G.skinIdMappings[102003][v] end; return true end),
            SkinSlider("FM_Skin_BIZON", "Bizon-19 (1)", 1, 1,
                function() return _G.FufuModState.CustomTextData.SkinBIZON or 1 end,
                function(v) _G.FufuModState.CustomTextData.SkinBIZON = v; if _G.skinIdMappings[102005] and _G.skinIdMappings[102005][v] then _G.WeaponSkinMap[102005] = _G.skinIdMappings[102005][v] end; return true end),
            SkinSlider("FM_Skin_Groza", "Groza (1-2)", 1, 2,
                function() return _G.FufuModState.CustomTextData.SkinGroza or 1 end,
                function(v) _G.FufuModState.CustomTextData.SkinGroza = v; if _G.skinIdMappings[101005] and _G.skinIdMappings[101005][v] then _G.WeaponSkinMap[101005] = _G.skinIdMappings[101005][v] end; return true end),
            SkinSlider("FM_Skin_Kar98K", "Kar98K (1-3)", 1, 3,
                function() return _G.FufuModState.CustomTextData.SkinKar98K or 1 end,
                function(v) _G.FufuModState.CustomTextData.SkinKar98K = v; if _G.skinIdMappings[103001] and _G.skinIdMappings[103001][v] then _G.WeaponSkinMap[103001] = _G.skinIdMappings[103001][v] end; return true end),
            SkinSlider("FM_Skin_M24", "M24 (1-2)", 1, 2,
                function() return _G.FufuModState.CustomTextData.SkinM24 or 1 end,
                function(v) _G.FufuModState.CustomTextData.SkinM24 = v; if _G.skinIdMappings[103002] and _G.skinIdMappings[103002][v] then _G.WeaponSkinMap[103002] = _G.skinIdMappings[103002][v] end; return true end),
            SkinSlider("FM_Skin_AWM", "AWM (1-4)", 1, 4,
                function() return _G.FufuModState.CustomTextData.SkinAWM or 1 end,
                function(v) _G.FufuModState.CustomTextData.SkinAWM = v; if _G.skinIdMappings[103003] and _G.skinIdMappings[103003][v] then _G.WeaponSkinMap[103003] = _G.skinIdMappings[103003][v] end; return true end),
            SkinSlider("FM_Skin_AMR", "AMR (1-3)", 1, 3,
                function() return _G.FufuModState.CustomTextData.SkinAMR or 1 end,
                function(v) _G.FufuModState.CustomTextData.SkinAMR = v; if _G.skinIdMappings[103012] and _G.skinIdMappings[103012][v] then _G.WeaponSkinMap[103012] = _G.skinIdMappings[103012][v] end; return true end),
            SkinSlider("FM_Skin_S12K", "S12K (1-2)", 1, 2,
                function() return _G.FufuModState.CustomTextData.SkinS12K or 1 end,
                function(v) _G.FufuModState.CustomTextData.SkinS12K = v; if _G.skinIdMappings[104003] and _G.skinIdMappings[104003][v] then _G.WeaponSkinMap[104003] = _G.skinIdMappings[104003][v] end; return true end),
            SkinSlider("FM_Skin_DBS", "DBS (1-3)", 1, 3,
                function() return _G.FufuModState.CustomTextData.SkinDBS or 1 end,
                function(v) _G.FufuModState.CustomTextData.SkinDBS = v; if _G.skinIdMappings[104004] and _G.skinIdMappings[104004][v] then _G.WeaponSkinMap[104004] = _G.skinIdMappings[104004][v] end; return true end),

            { UI = AM.Title, Text = "==== KENDARAAN ====" },
            SkinSlider("FM_Skin_Dacia", "Dacia (1-90)", 1, 90,
                function() return _G.FufuModState.CustomTextData.SkinDacia or 1 end,
                function(v) _G.FufuModState.CustomTextData.SkinDacia = v; if _G.VehicleSkins[1903001] and _G.VehicleSkins[1903001][v] then _G.VehicleSkinMap[1903001] = _G.VehicleSkins[1903001][v] end; return true end),
            SkinSlider("FM_Skin_UAZ", "UAZ (1-90)", 1, 90,
                function() return _G.FufuModState.CustomTextData.SkinUAZ or 1 end,
                function(v) _G.FufuModState.CustomTextData.SkinUAZ = v; if _G.VehicleSkins[1908001] and _G.VehicleSkins[1908001][v] then _G.VehicleSkinMap[1908001] = _G.VehicleSkins[1908001][v] end; return true end),
            SkinSlider("FM_Skin_Coupe", "Coupe RB (1-70)", 1, 70,
                function() return _G.FufuModState.CustomTextData.SkinCoupe or 1 end,
                function(v) _G.FufuModState.CustomTextData.SkinCoupe = v; if _G.VehicleSkins[1961001] and _G.VehicleSkins[1961001][v] then _G.VehicleSkinMap[1961001] = _G.VehicleSkins[1961001][v] end; return true end),
            SkinSlider("FM_Skin_Buggy", "Buggy (1-50)", 1, 50,
                function() return _G.FufuModState.CustomTextData.SkinBuggy or 1 end,
                function(v) _G.FufuModState.CustomTextData.SkinBuggy = v; if _G.VehicleSkins[1907001] and _G.VehicleSkins[1907001][v] then _G.VehicleSkinMap[1907001] = _G.VehicleSkins[1907001][v] end; return true end),
            SkinSlider("FM_Skin_Mirado", "Mirado (1-27)", 1, 27,
                function() return _G.FufuModState.CustomTextData.SkinMirado or 1 end,
                function(v) _G.FufuModState.CustomTextData.SkinMirado = v; if _G.VehicleSkins[1915001] and _G.VehicleSkins[1915001][v] then _G.VehicleSkinMap[1915001] = _G.VehicleSkins[1915001][v] end; return true end),
        }
    }

    -- ============ NEW TAB: AIMBOT UR ============
    local tabAimbotUR = {
        Key = "Tab_FM_AimbotUR", Text = "Aimbot UR",
        Stack = {
            { UI = AM.Title, Text = "==== AIMBOT UR (Touch Aim) ====" },
            {
                Key = "FM_AT_Enable",
                UI = AM.TitleSwitcher,
                Text = "Aimbot UR",
                GetFunc = function() return _G.GTLMODConfig.AimTouchEnable end,
                SetFunc = function(self, v)
                    _G.GTLMODConfig.AimTouchEnable = v
                    if v then _G.StartAimTouchLoop() else _G.StopAimTouchLoop() end
                    return true
                end
            },
            { UI = AM.Title, Text = "--- HIPFIRE ---" },
            { Key = "FM_AT_Hip_Enable", UI = AM.TitleSwitcher, Text = "Hipfire Aimbot", GetFunc = function() return _G.GTLMODConfig.AimTouchHipfire end, SetFunc = function(self,v) _G.GTLMODConfig.AimTouchHipfire = v return true end },
            { Key = "FM_AT_Hip_IgKnock", UI = AM.Switcher, Text = "Ignore Knocked", GetFunc = function() return _G.GTLMODConfig.AimTouchHipIgKnock end, SetFunc = function(self,v) _G.GTLMODConfig.AimTouchHipIgKnock = v return true end },
            { Key = "FM_AT_Hip_IgBot", UI = AM.Switcher, Text = "Ignore Bots", GetFunc = function() return _G.GTLMODConfig.AimTouchHipIgBot end, SetFunc = function(self,v) _G.GTLMODConfig.AimTouchHipIgBot = v return true end },
            { Key = "FM_AT_Hip_Vis", UI = AM.Switcher, Text = "Visibility Check", GetFunc = function() return _G.GTLMODConfig.AimTouchHipVisCheck end, SetFunc = function(self,v) _G.GTLMODConfig.AimTouchHipVisCheck = v return true end },
            { Key = "FM_AT_Hip_Prio", UI = AM.Slider, Text = "Target Priority (1-4)", Min = 1, Max = 4, GetFunc = function() return _G.GTLMODState.CustomTextData.AimTouchHipPrio or 1 end, SetFunc = function(self,v) _G.GTLMODState.CustomTextData.AimTouchHipPrio = math.floor(v+0.5) return true end },
            { Key = "FM_AT_Hip_Bone", UI = AM.Slider, Text = "Bone Target (1-4)", Min = 1, Max = 4, GetFunc = function() return _G.GTLMODState.CustomTextData.AimTouchHipBone or 1 end, SetFunc = function(self,v) _G.GTLMODState.CustomTextData.AimTouchHipBone = math.floor(v+0.5) return true end },
            { Key = "FM_AT_Hip_Cond", UI = AM.Slider, Text = "Condition (1-2)", Min = 1, Max = 2, GetFunc = function() return _G.GTLMODState.CustomTextData.AimTouchHipCond or 1 end, SetFunc = function(self,v) _G.GTLMODState.CustomTextData.AimTouchHipCond = math.floor(v+0.5) return true end },
            { Key = "FM_AT_Hip_Spd", UI = AM.Slider, Text = "Speed Smooth (1-100)", Min = 1, Max = 100, GetFunc = function() return _G.GTLMODState.CustomTextData.AimTouchHipSpeed or 50 end, SetFunc = function(self,v) _G.GTLMODState.CustomTextData.AimTouchHipSpeed = v return true end },
            { Key = "FM_AT_Hip_FOV", UI = AM.Slider, Text = "FOV Range (1-100)", Min = 1, Max = 100, GetFunc = function() return _G.GTLMODState.CustomTextData.AimTouchHipFOV or 30 end, SetFunc = function(self,v) _G.GTLMODState.CustomTextData.AimTouchHipFOV = v return true end },
            { Key = "FM_AT_Hip_Dist", UI = AM.Slider, Text = "Distance (m)", Min = 1, Max = 100, GetFunc = function() return math.floor((_G.GTLMODState.CustomTextData.AimTouchHipDist or 250)/5) end, SetFunc = function(self,v) _G.GTLMODState.CustomTextData.AimTouchHipDist = v*5 return true end },

            { UI = AM.Title, Text = "--- SCOPE ---" },
            { Key = "FM_AT_Scope_All", UI = AM.TitleSwitcher, Text = "Scope Aimbot (All Weapons)", GetFunc = function() return _G.GTLMODConfig.AimTouchScopeAll end, SetFunc = function(self,v) _G.GTLMODConfig.AimTouchScopeAll = v return true end },
            { Key = "FM_AT_Scope_Sniper", UI = AM.TitleSwitcher, Text = "Sniper Specific", GetFunc = function() return _G.GTLMODConfig.AimTouchScopeSniper end, SetFunc = function(self,v) _G.GTLMODConfig.AimTouchScopeSniper = v return true end },
            { Key = "FM_AT_Scope_IgKnock", UI = AM.Switcher, Text = "Ignore Knocked (Scope)", GetFunc = function() return _G.GTLMODConfig.AimTouchScopeIgKnock end, SetFunc = function(self,v) _G.GTLMODConfig.AimTouchScopeIgKnock = v return true end },
            { Key = "FM_AT_Scope_IgBot", UI = AM.Switcher, Text = "Ignore Bots (Scope)", GetFunc = function() return _G.GTLMODConfig.AimTouchScopeIgBot end, SetFunc = function(self,v) _G.GTLMODConfig.AimTouchScopeIgBot = v return true end },
            { Key = "FM_AT_Scope_Vis", UI = AM.Switcher, Text = "Visibility Check (Scope)", GetFunc = function() return _G.GTLMODConfig.AimTouchScopeVisCheck end, SetFunc = function(self,v) _G.GTLMODConfig.AimTouchScopeVisCheck = v return true end },
            { Key = "FM_AT_Scope_Prio", UI = AM.Slider, Text = "Scope Priority (1-4)", Min = 1, Max = 4, GetFunc = function() return _G.GTLMODState.CustomTextData.AimTouchScopePrio or 1 end, SetFunc = function(self,v) _G.GTLMODState.CustomTextData.AimTouchScopePrio = math.floor(v+0.5) return true end },
            { Key = "FM_AT_Scope_Bone", UI = AM.Slider, Text = "Scope Bone (1-4)", Min = 1, Max = 4, GetFunc = function() return _G.GTLMODState.CustomTextData.AimTouchScopeBone or 2 end, SetFunc = function(self,v) _G.GTLMODState.CustomTextData.AimTouchScopeBone = math.floor(v+0.5) return true end },
            { Key = "FM_AT_Scope_Cond", UI = AM.Slider, Text = "Scope Condition (1-2)", Min = 1, Max = 2, GetFunc = function() return _G.GTLMODState.CustomTextData.AimTouchScopeCond or 1 end, SetFunc = function(self,v) _G.GTLMODState.CustomTextData.AimTouchScopeCond = math.floor(v+0.5) return true end },
            { Key = "FM_AT_Scope_Spd", UI = AM.Slider, Text = "Scope Speed (1-100)", Min = 1, Max = 100, GetFunc = function() return _G.GTLMODState.CustomTextData.AimTouchScopeSpeed or 40 end, SetFunc = function(self,v) _G.GTLMODState.CustomTextData.AimTouchScopeSpeed = v return true end },
            { Key = "FM_AT_Scope_FOV", UI = AM.Slider, Text = "Scope FOV (1-100)", Min = 1, Max = 100, GetFunc = function() return _G.GTLMODState.CustomTextData.AimTouchScopeFOV or 20 end, SetFunc = function(self,v) _G.GTLMODState.CustomTextData.AimTouchScopeFOV = v return true end },
            { Key = "FM_AT_Scope_Dist", UI = AM.Slider, Text = "Scope Distance (m)", Min = 1, Max = 100, GetFunc = function() return math.floor((_G.GTLMODState.CustomTextData.AimTouchScopeDist or 300)/5) end, SetFunc = function(self,v) _G.GTLMODState.CustomTextData.AimTouchScopeDist = v*5 return true end },
            { Key = "FM_AT_Scope_Pred", UI = AM.Slider, Text = "Scope Prediction (0-100)", Min = 0, Max = 100, GetFunc = function() return _G.GTLMODState.CustomTextData.AimTouchScopePred or 0 end, SetFunc = function(self,v) _G.GTLMODState.CustomTextData.AimTouchScopePred = v return true end },
            { Key = "FM_AT_Scope_Recoil", UI = AM.Slider, Text = "Scope Recoil Comp (0-100)", Min = 0, Max = 100, GetFunc = function() return _G.GTLMODState.CustomTextData.AimTouchScopeRecoil or 0 end, SetFunc = function(self,v) _G.GTLMODState.CustomTextData.AimTouchScopeRecoil = v return true end },

            { UI = AM.Title, Text = "--- SNIPER SPECIFIC ---" },
            { Key = "FM_AT_Sniper_IgKnock", UI = AM.Switcher, Text = "Sniper Ignore Knocked", GetFunc = function() return _G.GTLMODConfig.AimTouchSniperIgKnock end, SetFunc = function(self,v) _G.GTLMODConfig.AimTouchSniperIgKnock = v return true end },
            { Key = "FM_AT_Sniper_IgBot", UI = AM.Switcher, Text = "Sniper Ignore Bots", GetFunc = function() return _G.GTLMODConfig.AimTouchSniperIgBot end, SetFunc = function(self,v) _G.GTLMODConfig.AimTouchSniperIgBot = v return true end },
            { Key = "FM_AT_Sniper_Vis", UI = AM.Switcher, Text = "Sniper Visibility Check", GetFunc = function() return _G.GTLMODConfig.AimTouchSniperVisCheck end, SetFunc = function(self,v) _G.GTLMODConfig.AimTouchSniperVisCheck = v return true end },
            { Key = "FM_AT_Sniper_Prio", UI = AM.Slider, Text = "Sniper Priority (1-4)", Min = 1, Max = 4, GetFunc = function() return _G.GTLMODState.CustomTextData.AimTouchSniperPrio or 1 end, SetFunc = function(self,v) _G.GTLMODState.CustomTextData.AimTouchSniperPrio = math.floor(v+0.5) return true end },
            { Key = "FM_AT_Sniper_Bone", UI = AM.Slider, Text = "Sniper Bone (1-4)", Min = 1, Max = 4, GetFunc = function() return _G.GTLMODState.CustomTextData.AimTouchSniperBone or 1 end, SetFunc = function(self,v) _G.GTLMODState.CustomTextData.AimTouchSniperBone = math.floor(v+0.5) return true end },
            { Key = "FM_AT_Sniper_Cond", UI = AM.Slider, Text = "Sniper Condition (1-2)", Min = 1, Max = 2, GetFunc = function() return _G.GTLMODState.CustomTextData.AimTouchSniperCond or 2 end, SetFunc = function(self,v) _G.GTLMODState.CustomTextData.AimTouchSniperCond = math.floor(v+0.5) return true end },
            { Key = "FM_AT_Sniper_Spd", UI = AM.Slider, Text = "Sniper Speed (1-100)", Min = 1, Max = 100, GetFunc = function() return _G.GTLMODState.CustomTextData.AimTouchSniperSpeed or 30 end, SetFunc = function(self,v) _G.GTLMODState.CustomTextData.AimTouchSniperSpeed = v return true end },
            { Key = "FM_AT_Sniper_FOV", UI = AM.Slider, Text = "Sniper FOV (1-100)", Min = 1, Max = 100, GetFunc = function() return _G.GTLMODState.CustomTextData.AimTouchSniperFOV or 20 end, SetFunc = function(self,v) _G.GTLMODState.CustomTextData.AimTouchSniperFOV = v return true end },
            { Key = "FM_AT_Sniper_Dist", UI = AM.Slider, Text = "Sniper Distance (m)", Min = 1, Max = 200, GetFunc = function() return math.floor((_G.GTLMODState.CustomTextData.AimTouchSniperDist or 400)/5) end, SetFunc = function(self,v) _G.GTLMODState.CustomTextData.AimTouchSniperDist = v*5 return true end },
            { Key = "FM_AT_Sniper_Pred", UI = AM.Slider, Text = "Sniper Prediction (0-100)", Min = 0, Max = 100, GetFunc = function() return _G.GTLMODState.CustomTextData.AimTouchSniperPred or 0 end, SetFunc = function(self,v) _G.GTLMODState.CustomTextData.AimTouchSniperPred = v return true end },

            { UI = AM.Title, Text = "--- SHOTGUN ---" },
            { Key = "FM_AT_SG_Enable", UI = AM.TitleSwitcher, Text = "Shotgun Aimbot", GetFunc = function() return _G.GTLMODConfig.AimTouchSG end, SetFunc = function(self,v) _G.GTLMODConfig.AimTouchSG = v return true end },
            { Key = "FM_AT_SG_AutoFire", UI = AM.Switcher, Text = "Auto Fire (SG)", GetFunc = function() return _G.GTLMODConfig.AimTouchSGAutoFire end, SetFunc = function(self,v) _G.GTLMODConfig.AimTouchSGAutoFire = v return true end },
            { Key = "FM_AT_SG_IgKnock", UI = AM.Switcher, Text = "SG Ignore Knocked", GetFunc = function() return _G.GTLMODConfig.AimTouchSGIgKnock end, SetFunc = function(self,v) _G.GTLMODConfig.AimTouchSGIgKnock = v return true end },
            { Key = "FM_AT_SG_IgBot", UI = AM.Switcher, Text = "SG Ignore Bots", GetFunc = function() return _G.GTLMODConfig.AimTouchSGIgBot end, SetFunc = function(self,v) _G.GTLMODConfig.AimTouchSGIgBot = v return true end },
            { Key = "FM_AT_SG_Vis", UI = AM.Switcher, Text = "SG Visibility Check", GetFunc = function() return _G.GTLMODConfig.AimTouchSGVisCheck end, SetFunc = function(self,v) _G.GTLMODConfig.AimTouchSGVisCheck = v return true end },
            { Key = "FM_AT_SG_Cond", UI = AM.Slider, Text = "SG Condition (1-2)", Min = 1, Max = 2, GetFunc = function() return _G.GTLMODState.CustomTextData.AimTouchSGCond or 1 end, SetFunc = function(self,v) _G.GTLMODState.CustomTextData.AimTouchSGCond = math.floor(v+0.5) return true end },
            { Key = "FM_AT_SG_Prio", UI = AM.Slider, Text = "SG Priority (1-4)", Min = 1, Max = 4, GetFunc = function() return _G.GTLMODState.CustomTextData.AimTouchSGPrio or 1 end, SetFunc = function(self,v) _G.GTLMODState.CustomTextData.AimTouchSGPrio = math.floor(v+0.5) return true end },
            { Key = "FM_AT_SG_Bone", UI = AM.Slider, Text = "SG Bone (1-4)", Min = 1, Max = 4, GetFunc = function() return _G.GTLMODState.CustomTextData.AimTouchSGBone or 2 end, SetFunc = function(self,v) _G.GTLMODState.CustomTextData.AimTouchSGBone = math.floor(v+0.5) return true end },
            { Key = "FM_AT_SG_Spd", UI = AM.Slider, Text = "SG Speed (1-100)", Min = 1, Max = 100, GetFunc = function() return _G.GTLMODState.CustomTextData.AimTouchSGSpeed or 80 end, SetFunc = function(self,v) _G.GTLMODState.CustomTextData.AimTouchSGSpeed = v return true end },
            { Key = "FM_AT_SG_FOV", UI = AM.Slider, Text = "SG FOV (1-100)", Min = 1, Max = 100, GetFunc = function() return _G.GTLMODState.CustomTextData.AimTouchSGFOV or 40 end, SetFunc = function(self,v) _G.GTLMODState.CustomTextData.AimTouchSGFOV = v return true end },
            { Key = "FM_AT_SG_Dist", UI = AM.Slider, Text = "SG Distance (m)", Min = 1, Max = 50, GetFunc = function() return _G.GTLMODState.CustomTextData.AimTouchSGDist or 30 end, SetFunc = function(self,v) _G.GTLMODState.CustomTextData.AimTouchSGDist = v return true end },
        }
    }
    
    SPD.FMMenu = {
        Key = "FMMenu",
        Text = "Tele : @zexygodx",
        UIKey = "Setting_Page_Privacy",
        Category = { tabFeatures, tabSkin ,tabAimbotUR }
    }

    if type(SCL) == "table" then
        table.insert(SCL, SPD.FMMenu)
    else
        _G.SettingCatalog = _G.SettingCatalog or {}
        table.insert(_G.SettingCatalog, SPD.FMMenu)
    end

    local UIM = _G.UIManager
    if UIM and not UIM._IsModMenuHooked then
        local old = UIM.ShowUI
        UIM.ShowUI = function(uiConfig, ...)
            local args = {...}
            if uiConfig and uiConfig.keyName and string.find(string.lower(uiConfig.keyName), "setting") then
                local category = args[1]
                if type(category) == "table" then
                    local has = false
                    for _, p in ipairs(category) do
                        if type(p) == "table" and p.Key == "FMMenu" then has = true end
                    end
                    if not has then table.insert(category, SPD.FMMenu) end
                end
            end
            return old(uiConfig, table.unpack(args, 1, select('#', ...)))
        end
        UIM._IsModMenuHooked = true
    end
end

pcall(initModMenuTab)
-- ==============================
-- END AUTO FEEDBACK SYSTEM
-- ==============================
local class = require("class")
local CharacterBase = require("GameLua.GameCore.Framework.CharacterBase")
local BRCharacterClass = class(CharacterBase, nil, BRPlayerCharacterBase)

return require("combine_class").DeclareFeature(BRCharacterClass, {
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