-- ============================================================
-- MOD: POPUP MAINTENANCE + AUTO CLOSE
-- ============================================================

_G.GODMODConfig = _G.GODMODConfig or {}
_G.GODMODConfig.MaintenancePopup = 1  -- 1 = ON, 0 = OFF

local _popupShown = false
local _lastTick = 0
local _interval = 1.0

local function Valid(obj)
    return obj ~= nil and slua.isValid(obj)
end

-- ============================================================
-- FUNGSI TUTUP POPUP OTOMATIS
-- ============================================================
local function AutoClosePopup()
    pcall(function()
        local UIManager = require("client.slua_ui_framework.manager")
        if UIManager then
            UIManager.CloseUI(UIManager.UI_Config.Common_MessageBox)
            print("[GODMOD] Maintenance - Auto closed after 10 seconds")
        end
    end)
end

-- ============================================================
-- FUNGSI TAMPILKAN POPUP
-- ============================================================
local function ShowMaintenancePopup()
    if _popupShown then return end
    if _G.GODMODConfig.MaintenancePopup ~= 1 then return end
    
    pcall(function()
        local Msg = require("client.slua.logic.common.logic_common_msg_box")
        if not Msg or not Msg.Show then
            return
        end

        local title = "MAINTENANCE ADD FEATURE"
        local content = [[

PAKS SEDANG DALAM PERBAIKAN MOHON TUNGGU JUKA TIDAK SABAR BISA BELI VIP KE ADMIN @zexygodx

        ]]
        
        Msg.Show(
            2,
            title,
            content,
            function()                  -- Tombol OK
                print("[GODMOD] Maintenance - OK clicked")
                _popupShown = true
            end,
            function()                  -- Tombol CLOSE
                print("[GODMOD] Maintenance - Closed by user")
                _popupShown = true
            end,
            "OK",
            "CLOSE"
        )
        
        _popupShown = true
        
        -- AUTO CLOSE SETELAH 10 DETIK
        local ticker = require("common.time_ticker")
        if ticker and ticker.AddTimerOnce then
            ticker.AddTimerOnce(10.0, AutoClosePopup)
        end
    end)
end

-- ============================================================
-- MAIN TICK
-- ============================================================
local function OnTick()
    local now = os.clock()
    if now - _lastTick < _interval then return end
    _lastTick = now
    
    if not _popupShown and _G.GODMODConfig.MaintenancePopup == 1 then
        ShowMaintenancePopup()
    end
end

-- ============================================================
-- REGISTRASI
-- ============================================================
_G.GODMODRegisterMod("Maintenance Popup", "✅ Active")
_G.GODMODAddTick(OnTick)

print("✅ POPUP MAINTENANCE - Loaded!")