--[[
XGOD UNIVERSAL LOADER V1

Cara pakai:
1) Salin SELURUH blok ini ke file Lua CLIENT yang ingin dipasangi loader.
2) Tempel di bagian paling bawah file, TEPAT SEBELUM `return ...` jika file memakai return.
3) Jangan tempel setelah `return`, karena kode setelah return tidak akan dieksekusi.
4) Jangan salin berulang kali ke file yang sama.

Catatan kompatibilitas:
- Memakai API game/SLua yang sama dengan loader sumber: HUD, UMG, ModuleManager HTTP, dan common.time_ticker.
- State memakai key global khusus agar tidak menimpa variabel XGOD atau local milik file lain.
- Native FVector2D/FLinearColor tidak pernah diganti table Lua.
- Jika HUD belum siap, loader mencoba lagi; request HTTP memiliki watchdog 65 detik.
- Satu payload dijalankan per sesi game untuk mencegah logic/hook menumpuk. Untuk mengganti payload setelah sukses, restart sesi/game.
- Tetap uji di tiap jenis Lua: tidak ada template yang bisa menjamin API/lifecycle semua modul identik.
]]
do
    local _xgodGlobal = rawget(_G, "__XGOD_UNIVERSAL_STATE_V1")
    if type(_xgodGlobal) ~= "table" then
        _xgodGlobal = {}
        rawset(_G, "__XGOD_UNIVERSAL_STATE_V1", _xgodGlobal)
    end
    if _xgodGlobal.loaderBooted ~= true then
        _xgodGlobal.loaderBooted = true
        -- XGOD: IN-GAME LOADER UI (DENGAN PROTEKSI ERROR)
        -- ============================================================
        -- ============================================================
        -- XGOD: IN-GAME LOADER UI (ANTI-HANG & DEBUG)
        -- ============================================================
        local XGOD = rawget(_G, "__XGOD_UNIVERSAL_STATE_V1")
        if type(XGOD) ~= "table" then
            XGOD = {}
            rawset(_G, "__XGOD_UNIVERSAL_STATE_V1", XGOD)
        end

        local _pcall   = pcall
        local _type    = type
        local _rawget  = rawget

        local function EValid(w)
            if not w then return false end
            if slua and slua.isValid then
                local ok, r = _pcall(slua.isValid, w)
                if ok then return r == true end
            end
            return true
        end

        local function ECol(r, g, b, a)
            local cls = nil
            _pcall(function() cls = import("LinearColor") end)
            if cls then local ok, c = _pcall(cls, r, g, b, a or 1); if ok and c then return c end end
            local cls2 = _rawget(_G, "FLinearColor")
            if cls2 then local ok, c = _pcall(cls2, r, g, b, a or 1); if ok and c then return c end end
            return nil
        end

        local function EVec(x, y)
            local fv = _rawget(_G, "FVector2D")
            if fv then local ok, v = _pcall(fv, x, y); if ok and v then return v end end
            local cls = nil; _pcall(function() cls = import("Vector2D") end)
            if cls then local ok, v = _pcall(cls, x, y); if ok and v then return v end end
            return nil
        end

        local function ESlate(c)
            local cls = _rawget(_G, "FSlateColor")
            if cls then local ok, v = _pcall(cls, c); if ok and v then return v end end
            return c
        end

        local function ENew(path, parent)
            local cg = _rawget(_G, "CGame")
            if not (cg and cg.NewObjectFromPath) then return nil end
            local ok, obj = _pcall(cg.NewObjectFromPath, cg, path, parent)
            if ok then return obj end
            return nil
        end

        local function EShowInteractive(w)
            if not EValid(w) then return end
            local UEnums = _rawget(_G, "UEnums")
            if not UEnums then return end
            _pcall(function() w:SetWidgetVisibility(UEnums.ESlateVisibility.Visible) end)
        end

        local function ESlot(parent, w, x, y, sx, sy, z)
            if not (EValid(parent) and EValid(w)) then return nil end
            local slot = nil
            local position = EVec(x, y)
            local size = EVec(sx, sy)
            if not position or not size then return nil end
            _pcall(function()
                slot = parent:AddChildToCanvas(w)
                if slot then
                    slot:SetAutoSize(false)
                    slot:SetPosition(position)
                    slot:SetSize(size)
                    slot:SetZOrder(z or 0)
                end
            end)
            return slot
        end

        local function ELayer(parent, x, y, sx, sy, col, z)
            local b = ENew("/Script/UMG.Border", parent)
            if not EValid(b) then return nil, nil end
            _pcall(function() b:SetBrushColor(col) end)
            local UEnums = _rawget(_G, "UEnums")
            if UEnums then _pcall(function() b:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end) end
            local slot = ESlot(parent, b, x, y, sx, sy, z)
            return b, slot
        end

        local function EText(parent, txt, x, y, size, col, z, ax, ay)
            local t = ENew("/Script/UMG.TextBlock", parent)
            if not EValid(t) then return nil end
            _pcall(function() t:SetText(txt) end)
            _pcall(function() t:SetColorAndOpacity(ESlate(col)) end)
            _pcall(function()
                local f = t.Font
                if f then
                    f.Size = size
                    local done = _pcall(function() t.Font = f end)
                    if not done then t:SetFont(f) end
                end
            end)
            local UEnums = _rawget(_G, "UEnums")
            if UEnums then _pcall(function() t:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end) end
            _pcall(function()
                local slot = parent:AddChildToCanvas(t)
                if slot then
                    local alignment = EVec(ax or 0.5, ay or 0.5)
                    local position = EVec(x, y)
                    slot:SetAutoSize(true)
                    if alignment then slot:SetAlignment(alignment) end
                    if position then slot:SetPosition(position) end
                    slot:SetZOrder(z or 100)
                end
            end)
            return t
        end

        local function EScreen()
            local w, h = 2340, 1080
            _pcall(function()
                local uiUtil = require("client.common.ui_util")
                if uiUtil and uiUtil.GetViewportSize then
                    local s = uiUtil.GetViewportSize()
                    if s and s.X and s.Y and s.X > 0 and s.Y > 0 then w, h = s.X, s.Y end
                end
            end)
            return w, h
        end

        local GODMOD_PAYLOAD_URL = "https://godmod.kenjawir780.workers.dev/"
        -- API verifikasi sesuai Worker yang dikirim user.
        local XGOD_VERIFY_URL = "https://godmod-zexy.kenjawir780.workers.dev/api/verify"
        local XGOD_BUY_URL = "https://t.me/zexygodx"
        local GODMOD_PAYLOAD_FILES = {
            { name = "X1", file = "X1.lua" }, { name = "X2", file = "X2.lua" },
            { name = "X3", file = "X3.lua" }, { name = "X4", file = "X4.lua" },
            { name = "X5", file = "X5.lua" }, { name = "X6", file = "X6.lua" },
            { name = "X7", file = "X7.lua" }, { name = "X8", file = "X8.lua" },
            { name = "X9", file = "X9.lua" }, { name = "X10", file = "X10.lua" },
            { name = "X11", file = "X11.lua" }
        }

        -- ============================================================
        -- FUNGSI DOWNLOAD DENGAN SISTEM ANTI-HANG
        -- ============================================================
        local function GODMOD_LoadPayloadFromWorker(file_name, statusCallback)
            local is_done = false
            local function finish(msg, is_error)
                if is_done then return end
                is_done = true
                if statusCallback then
                    pcall(statusCallback, msg, is_error)
                end
            end

            local ok, M = pcall(require, "client.module_framework.ModuleManager")
            if not ok or not M or type(M.GetModule) ~= "function" or not M.CommonModuleConfig then
                finish("GAGAL: ModuleManager tidak tersedia", true)
                return false
            end

            local ok2, http = pcall(function()
                return M.GetModule(M.CommonModuleConfig.http_manager)
            end)
            if not ok2 or not http or type(http.Post) ~= "function" then
                finish("GAGAL: HTTP Manager tidak tersedia", true)
                return false
            end

            local safeName = tostring(file_name or "")
            if safeName == "" or not safeName:match("^[%w_%.%-%/]+%.lua$") or
               safeName:find("..", 1, true) or safeName:find("//", 1, true) then
                finish("GAGAL: nama file Lua tidak valid", true)
                return false
            end

            -- Ikuti protokol petunjuk: POST form-urlencoded dengan key_path.
            local encodedName = safeName:gsub("([^%w%-_%.~/])", function(ch)
                return string.format("%%%02X", string.byte(ch))
            end)
            local body = "key_path=" .. encodedName
            local headers = {
                ["Content-Type"] = "application/x-www-form-urlencoded",
                ["Accept"] = "text/plain"
            }

            local function normalizeResponse(value, depth)
                depth = depth or 0
                if depth > 2 or value == nil then return nil end

                if type(value) == "string" then
                    if value:sub(1, 3) == "\239\187\191" then
                        value = value:sub(4)
                    end
                    return value
                end

                if type(value) ~= "table" then return nil end

                if #value > 0 then
                    local bytes = {}
                    for i = 1, #value do
                        local n = tonumber(value[i])
                        if not n then
                            bytes = nil
                            break
                        end
                        bytes[i] = string.char(n % 256)
                    end
                    if bytes then return table.concat(bytes) end
                end

                local keys = { "body", "content", "text", "response", "data", "payload", "result" }
                for i = 1, #keys do
                    local okValue, nested = pcall(function() return value[keys[i]] end)
                    if okValue and nested ~= nil then
                        local result = normalizeResponse(nested, depth + 1)
                        if result and result ~= "" then return result end
                    end
                end
                return nil
            end

            local function looksLikeLua(source)
                if type(source) ~= "string" then return false end
                local s = source:gsub("^%s+", "")
                if s == "" then return false end
                local lower = s:sub(1, 180):lower()
                local rejected = {
                    "invalid request", "bad request", "not found", "file not found",
                    "github fetch failed", "method not allowed", "payload required",
                    "worker error", "proxy error", "unauthorized", "forbidden"
                }
                for i = 1, #rejected do
                    if lower:find(rejected[i], 1, true) then return false end
                end
                return s:match("^%-%-") ~= nil or
                       s:match("^local%s") ~= nil or
                       s:match("^function%s") ~= nil or
                       s:match("^return[%s%(]") ~= nil or
                       s:match("^if%s") ~= nil or
                       s:match("^for%s") ~= nil or
                       s:match("^while%s") ~= nil or
                       s:match("^repeat[%s]") ~= nil or
                       s:match("^do[%s]") ~= nil
            end

            local function compileWithPetunjuk(source, chunkName)
                local proxyEnv = setmetatable({}, {
                    __index = _G,
                    __newindex = _G
                })
                rawset(proxyEnv, "_G", _G)

                local loadFn = rawget(_G, "load")
                if type(loadFn) == "function" then
                    local callOk, chunk, compileErr = pcall(loadFn, source, "@" .. chunkName, "t", proxyEnv)
                    if callOk and type(chunk) == "function" then
                        return chunk
                    end
                    if callOk then
                        compileErr = compileErr or chunk
                    end
                end

                local function bindEnvironment(chunk)
                    local setfenvFn = rawget(_G, "setfenv")
                    if type(setfenvFn) == "function" then
                        local envOk = pcall(setfenvFn, chunk, proxyEnv)
                        if envOk then return true end
                    end

                    local dbg = rawget(_G, "debug")
                    if type(dbg) == "table" and type(dbg.getupvalue) == "function"
                       and type(dbg.setupvalue) == "function" then
                        for i = 1, 64 do
                            local okUp, upName = pcall(dbg.getupvalue, chunk, i)
                            if not okUp or upName == nil then break end
                            if upName == "_ENV" then
                                local okSet, setName = pcall(dbg.setupvalue, chunk, i, proxyEnv)
                                return okSet and setName == "_ENV"
                            end
                        end
                    end
                    return false
                end

                local loadstringFn = rawget(_G, "loadstring")
                if type(loadstringFn) == "function" then
                    local callOk, chunk, compileErr = pcall(loadstringFn, source, "@" .. chunkName)
                    if callOk and type(chunk) == "function" then
                        if bindEnvironment(chunk) then return chunk end
                        return nil, "environment_binding_failed"
                    end
                    if callOk then compileErr = compileErr or chunk end
                end

                -- Fallback terakhir sesuai petunjuk: load(source, chunkname), lalu bind _ENV.
                if type(loadFn) == "function" then
                    local callOk, chunk, compileErr = pcall(loadFn, source, "@" .. chunkName)
                    if callOk and type(chunk) == "function" then
                        if bindEnvironment(chunk) then return chunk end
                        return nil, "environment_binding_failed"
                    end
                    if callOk then compileErr = compileErr or chunk end
                    return nil, tostring(compileErr or "compile_failed")
                end

                return nil, "lua_compiler_unavailable"
            end

            local reqOk, reqIndex = pcall(function()
                return http:Post(GODMOD_PAYLOAD_URL, headers, body, nil,
                    function(success, data, content, result)
                        if is_done then return end

                        -- Callback game dapat menaruh body pada argumen berbeda.
                        -- Pilih kandidat yang benar-benar terlihat seperti source Lua,
                        -- bukan string metadata/request dari HTTP manager.
                        local candidates = {}
                        local c1 = normalizeResponse(content)
                        local c2 = normalizeResponse(data)
                        local c3 = normalizeResponse(result)
                        if c1 then candidates[#candidates + 1] = c1 end
                        if c2 then candidates[#candidates + 1] = c2 end
                        if c3 then candidates[#candidates + 1] = c3 end

                        local responseBody = nil
                        for i = 1, #candidates do
                            if looksLikeLua(candidates[i]) then
                                responseBody = candidates[i]
                                break
                            end
                        end

                        if not success then
                            local detail = responseBody or normalizeResponse(content) or
                                           normalizeResponse(data) or normalizeResponse(result)
                            finish("GAGAL REQUEST: " .. tostring(detail or "koneksi gagal"):sub(1, 140), true)
                            return
                        end

                        if not responseBody then
                            local detail = normalizeResponse(content) or normalizeResponse(data) or
                                           normalizeResponse(result) or "(response kosong)"
                            finish("GAGAL RESPONSE: bukan source Lua; diterima: " ..
                                   tostring(detail):gsub("[%c]", " "):sub(1, 120), true)
                            return
                        end

                        local chunk, compileErr = compileWithPetunjuk(responseBody, safeName)
                        if not chunk then
                            finish("GAGAL COMPILE: " .. tostring(compileErr):sub(1, 120), true)
                            return
                        end

                        local runOk, runErr = pcall(chunk)
                        if not runOk then
                            finish("GAGAL LOAD: " .. tostring(runErr):sub(1, 120), true)
                            return
                        end

                        finish("DOWNLOAD & LOAD BERHASIL: " .. safeName, false)
                    end,
                    60
                )
            end)

            if not reqOk then
                finish("GAGAL API: " .. tostring(reqIndex):sub(1, 120), true)
                return false
            end
            if reqIndex == nil or reqIndex == 0 then
                finish("GAGAL: HTTP request tidak dapat dibuat", true)
                return false
            end

            -- Watchdog: HTTP callback yang tidak pernah datang tidak boleh menggantung UI.
            local timerOK, timer = pcall(require, "common.time_ticker")
            if timerOK and timer and timer.AddTimerOnce then
                pcall(timer.AddTimerOnce, 65.0, function()
                    finish("GAGAL: DOWNLOAD TIMEOUT, COBA SELECT LAGI", true)
                end)
            end
            return true
        end

        -- ============================================================
        -- UI BUILDER
        -- ============================================================
        local selectorPanel = nil
        local selectorLogo = nil
        local selectorLogoText = nil
        local keyPanel = nil
        local keyInput = nil
        local keyStatusText = nil
        local keyVerifyButton = nil
        local keyRequestBusy = false
        local selectorVisible = false
        local keyVisible = false

        local function XGOD_GetDeviceId()
            -- Gunakan device ID native engine agar binding device Worker konsisten.
            local libA = rawget(_G, "UKismetSystemLibrary")
            local libB = rawget(_G, "KismetSystemLibrary")
            if libA and type(libA.GetDeviceId) == "function" then
                local ok, id = pcall(function() return libA.GetDeviceId() end)
                if ok and id ~= nil and tostring(id) ~= "" then return tostring(id) end
            end
            if libB and type(libB.GetDeviceId) == "function" then
                local ok, id = pcall(function() return libB.GetDeviceId() end)
                if ok and id ~= nil and tostring(id) ~= "" then return tostring(id) end
            end
            local okImport, lib = pcall(import, "KismetSystemLibrary")
            if okImport and lib and type(lib.GetDeviceId) == "function" then
                local ok, id = pcall(function() return lib.GetDeviceId() end)
                if ok and id ~= nil and tostring(id) ~= "" then
                    return tostring(id)
                end
            end
            return nil
        end

        local function XGOD_SetKeyStatus(message, isError)
            if not EValid(keyStatusText) then return end
            pcall(function() keyStatusText:SetText(tostring(message or "")) end)
            local color = isError and ECol(1.00, 0.28, 0.28, 1)
                or ECol(0.20, 0.86, 0.60, 1)
            if color then
                pcall(function() keyStatusText:SetColorAndOpacity(ESlate(color)) end)
            end
        end

        local function BuildSelectorUI()
            -- Status sesi global: sukses tidak boleh memunculkan UI lagi sampai game restart.
            if XGOD.payloadLoaded == true then return true end
            if XGOD.payloadLoading == true then return true end
            if XGOD.selectorShown == true then return true end
            if EValid(selectorPanel) then return true end
            
            local canvas = nil
            _pcall(function()
                local hud = package.loaded["game_frontend_hud"] or _rawget(_G, "game_frontend_hud")
                local containers = _rawget(_G, "UIContainers")
                if not (hud and containers and slua and slua.loadUI) then return end
                local dummy = slua.loadUI("/Game/UMG/UI_BP/Common/BaseComponent/CommonBaseComponent_TextButton_UIBP.CommonBaseComponent_TextButton_UIBP")
                if not EValid(dummy) then return end
                if hud.AddToContainer then hud.AddToContainer(containers.Top, dummy, 9000) end
                local parent = dummy:GetParent()
                if parent and parent.AddChildToCanvas then
                    canvas = parent
                    _pcall(function() dummy:SetWidgetVisibility(_rawget(_G, "UEnums").ESlateVisibility.Collapsed) end)
                    _pcall(function() dummy:RemoveFromParent() end)
                else
                    _pcall(function() dummy:RemoveFromParent() end)
                end
            end)

            if not canvas then return false end

            -- Posisi panel disamakan dengan UI autentikasi key:
            -- anchor di tengah canvas, alignment di tengah widget, offset nol.
            local W, H = 560, 360

            local panel = ENew("/Script/UMG.CanvasPanel", canvas)
            if not EValid(panel) then return false end
            local slot = ESlot(canvas, panel, 0, 0, W, H, 12000)
            if not slot then _pcall(function() panel:RemoveFromParent() end); return false end
            _pcall(function()
                local anchorsCtor = _rawget(_G, "FAnchors")
                if _type(anchorsCtor) == "function" then
                    local okAnchors, anchors = _pcall(anchorsCtor, 0.5, 0.5, 0.5, 0.5)
                    if okAnchors and anchors ~= nil and _type(anchors) ~= "table" then
                        slot:SetAnchors(anchors)
                    end
                end
                local alignment = EVec(0.5, 0.5)
                local position = EVec(0, 0)
                local size = EVec(W, H)
                if alignment then slot:SetAlignment(alignment) end
                if position then slot:SetPosition(position) end
                if size then slot:SetSize(size) end
            end)
            
            selectorPanel = panel
            -- Panel Select dibuat tetapi disembunyikan sampai logo Toggle ditekan.
            local initialEnums = _rawget(_G, "UEnums")
            if initialEnums then
                _pcall(function() panel:SetWidgetVisibility(initialEnums.ESlateVisibility.Collapsed) end)
            else
                EShowInteractive(panel)
                selectorVisible = false
            end

            ELayer(panel, 0, 0, W, H, ECol(0.02, 0.05, 0.08, 0.95), 1)
            ELayer(panel, 0, 0, W, 2, ECol(0.10, 0.90, 1.00, 1), 2)
            ELayer(panel, 0, H - 2, W, 2, ECol(0.10, 0.50, 0.80, 1), 2)
            ELayer(panel, 0, 0, 2, H, ECol(0.10, 0.50, 0.80, 1), 2)
            ELayer(panel, W - 2, 0, 2, H, ECol(0.10, 0.50, 0.80, 1), 2)

            EText(panel, "GOD MOD • ZEXYXGOD", W * 0.5, 30, 20, ECol(0.10, 0.90, 1.00, 1), 5, 0.5, 0.5)
            EText(panel, "SELECT VERSI MOD", W * 0.5, 65, 12, ECol(0.50, 0.80, 0.90, 0.9), 5, 0.5, 0.5)

            ELayer(panel, 30, 95, W - 60, 90, ECol(0.04, 0.08, 0.12, 0.9), 3)
            local fileText = EText(panel, GODMOD_PAYLOAD_FILES[1].name, W * 0.5, 125, 16, ECol(1, 1, 1, 1), 5, 0.5, 0.5)
            local statusText = EText(panel, "● READY TO SELECT", W * 0.5, 160, 11, ECol(0.20, 0.86, 0.60, 1), 5, 0.5, 0.5)

            local Button = import("Button")

            -- Floating logo kiri atas: klik untuk buka/tutup panel selector.
            if not EValid(selectorLogo) then
                selectorLogo = Button()
                if EValid(selectorLogo) then
                    ESlot(canvas, selectorLogo, 24, 24, 58, 58, 13000)
                    EShowInteractive(selectorLogo)
                    _pcall(function()
                        selectorLogo:SetBackgroundColor(ECol(0.02, 0.12, 0.18, 0.96))
                    end)
                    selectorLogoText = EText(canvas, "XG", 53, 53, 19, ECol(0.10, 0.90, 1.00, 1), 13001, 0.5, 0.5)
                    if selectorLogo.OnClicked and selectorLogo.OnClicked.Add then
                        selectorLogo.OnClicked:Add(function()
                            if XGOD.payloadLoaded == true then return end
                            local enums = _rawget(_G, "UEnums")
                            if not XGOD.keyVerified then
                                keyVisible = not keyVisible
                                selectorVisible = false
                                if not EValid(keyPanel) then
                                    print("[XGOD KEY] Key UI gagal dibuat: EditableTextBox/UMG tidak tersedia")
                                    return
                                end
                                if enums then
                                    _pcall(function()
                                        if EValid(keyPanel) then
                                            keyPanel:SetWidgetVisibility(
                                                keyVisible and enums.ESlateVisibility.Visible
                                                or enums.ESlateVisibility.Collapsed
                                            )
                                        end
                                        if EValid(selectorPanel) then
                                            selectorPanel:SetWidgetVisibility(enums.ESlateVisibility.Collapsed)
                                        end
                                    end)
                                end
                            else
                                selectorVisible = not selectorVisible
                                keyVisible = false
                                if enums then
                                    _pcall(function()
                                        if EValid(keyPanel) then
                                            keyPanel:SetWidgetVisibility(enums.ESlateVisibility.Collapsed)
                                        end
                                        if EValid(selectorPanel) then
                                            selectorPanel:SetWidgetVisibility(
                                                selectorVisible and enums.ESlateVisibility.Visible
                                                or enums.ESlateVisibility.Collapsed
                                            )
                                        end
                                    end)
                                end
                            end
                        end)
                    end
                end
            end
            local function createBtn(label, bx, by, bw, bh, isStrong, onClick)
                local btn = Button()
                EText(panel, label, bx + bw * 0.5, by + bh * 0.5, 13, ECol(1, 1, 1, 1), 6, 0.5, 0.5)
                ESlot(panel, btn, bx, by, bw, bh, 5)
                EShowInteractive(btn)
                _pcall(function() btn:SetBackgroundColor(isStrong and ECol(0.75, 0.015, 0.02, 1) or ECol(0.08, 0.15, 0.22, 1)) end)
                if btn.OnClicked and btn.OnClicked.Add then btn.OnClicked:Add(function() onClick() end) end
                return btn
            end

            -- KEY GATE: panel baru ditampilkan setelah logo XG ditekan.
            -- Selector tetap tertutup sampai Worker mengembalikan valid=true.
            local function setKeyButtonEnabled(enabled)
                if EValid(keyVerifyButton) then
                    _pcall(function() keyVerifyButton:SetIsEnabled(enabled) end)
                end
            end

            local function verifyEnteredKey()
                if keyRequestBusy or XGOD.keyVerified == true then return end

                local keyValue = ""
                _pcall(function()
                    if EValid(keyInput) then
                        local value = keyInput:GetText()
                        keyValue = tostring(value or "")
                    end
                end)
                keyValue = keyValue:match("^%s*(.-)%s*$") or ""
                keyValue = keyValue:upper()

                if keyValue == "" then
                    XGOD_SetKeyStatus("MASUKKAN KEY TERLEBIH DAHULU", true)
                    return
                end
                if keyValue:find('"', 1, true) or keyValue:find("\\", 1, true) then
                    XGOD_SetKeyStatus("FORMAT KEY TIDAK VALID", true)
                    return
                end

                local deviceId = XGOD_GetDeviceId()
                if not deviceId then
                    XGOD_SetKeyStatus("DEVICE ID ENGINE TIDAK TERSEDIA", true)
                    return
                end

                local okM, M = pcall(require, "client.module_framework.ModuleManager")
                if not okM or not M or type(M.GetModule) ~= "function" or not M.CommonModuleConfig then
                    XGOD_SetKeyStatus("NETWORK MODULE TIDAK TERSEDIA", true)
                    return
                end

                local okHttp, http = pcall(function()
                    return M.GetModule(M.CommonModuleConfig.http_manager)
                end)
                if not okHttp or not http or type(http.Post) ~= "function" then
                    XGOD_SetKeyStatus("HTTP MANAGER TIDAK TERSEDIA", true)
                    return
                end

                local function jsonEscape(value)
                    return tostring(value):gsub("\\", "\\\\"):gsub('"', '\\"')
                        :gsub("\r", "\\r"):gsub("\n", "\\n")
                end

                local requestBody = '{"key":"' .. jsonEscape(keyValue)
                    .. '","device_id":"' .. jsonEscape(deviceId) .. '"}'

                keyRequestBusy = true
                setKeyButtonEnabled(false)
                XGOD_SetKeyStatus("VERIFYING KEY • PLEASE WAIT...", false)

                local finished = false
                local function finishFailure(message)
                    if finished then return end
                    finished = true
                    keyRequestBusy = false
                    setKeyButtonEnabled(true)
                    XGOD_SetKeyStatus(message, true)
                end

                local function finishSuccess()
                    if finished then return end
                    finished = true
                    keyRequestBusy = false
                    XGOD.keyVerified = true
                    XGOD.verifiedKey = keyValue
                    setKeyButtonEnabled(false)
                    XGOD_SetKeyStatus("KEY VALID • ACCESS GRANTED", false)

                    -- Setelah verifikasi sukses: tutup login, baru buka selector.
                    keyVisible = false
                    selectorVisible = true
                    local enums = _rawget(_G, "UEnums")
                    if enums then
                        _pcall(function()
                            if EValid(keyPanel) then keyPanel:SetWidgetVisibility(enums.ESlateVisibility.Collapsed) end
                            if EValid(selectorPanel) then selectorPanel:SetWidgetVisibility(enums.ESlateVisibility.Visible) end
                        end)
                    end
                end

                local function responseString(value)
                    if type(value) == "string" then return value end
                    if type(value) == "table" then
                        for _, field in ipairs({"body", "content", "text", "response", "data", "result"}) do
                            local ok, nested = pcall(function() return value[field] end)
                            if ok and type(nested) == "string" and nested ~= "" then return nested end
                        end
                    end
                    return ""
                end

                local reqOK, reqResult = pcall(function()
                    return http:Post(
                        XGOD_VERIFY_URL,
                        { ["Content-Type"] = "application/json", ["Accept"] = "application/json" },
                        requestBody,
                        nil,
                        function(success, data, content, result)
                            if finished then return end
                            local candidates = {
                                responseString(content),
                                responseString(data),
                                responseString(result)
                            }
                            local responseBody = table.concat(candidates, "\\n")
                            if success and responseBody:match('"valid"%s*:%s*true') then
                                finishSuccess()
                            else
                                local reason = "KEY INVALID • ACCESS DENIED"
                                if responseBody:find("KEY_EXPIRED", 1, true) then
                                    reason = "KEY EXPIRED"
                                elseif responseBody:find("KEY_DISABLED", 1, true) then
                                    reason = "KEY DISABLED"
                                elseif responseBody:find("KEY_NOT_FOUND", 1, true) then
                                    reason = "KEY NOT FOUND"
                                elseif responseBody:find("DEVICE_LIMIT_REACHED", 1, true) then
                                    reason = "DEVICE LIMIT REACHED"
                                elseif responseBody:find("SERVER_ERROR", 1, true) then
                                    reason = "SERVER ERROR • TRY AGAIN"
                                elseif not success then
                                    reason = "NETWORK ERROR • TRY AGAIN"
                                end
                                finishFailure(reason)
                            end
                        end,
                        25
                    )
                end)

                if not reqOK or reqResult == nil or reqResult == 0 then
                    finishFailure("GAGAL MEMULAI REQUEST VERIFIKASI")
                    return
                end

                -- Watchdog supaya tombol tidak terkunci jika callback HTTP tidak dipanggil.
                local timerOK, ticker = pcall(require, "common.time_ticker")
                if timerOK and ticker and ticker.AddTimerOnce then
                    pcall(ticker.AddTimerOnce, 27, function()
                        finishFailure("VERIFY TIMEOUT • COBA LAGI")
                    end)
                end
            end

            local function openBuyKey()
                local launched = false
                local libA = _rawget(_G, "UKismetSystemLibrary")
                local libB = _rawget(_G, "KismetSystemLibrary")
                if libA and type(libA.LaunchURL) == "function" then
                    launched = _pcall(function() libA.LaunchURL(XGOD_BUY_URL) end)
                end
                if not launched and libB and type(libB.LaunchURL) == "function" then
                    launched = _pcall(function() libB.LaunchURL(XGOD_BUY_URL) end)
                end
                if not launched then
                    local okImport, lib = _pcall(function() return import("KismetSystemLibrary") end)
                    if okImport and lib and type(lib.LaunchURL) == "function" then
                        launched = _pcall(function() lib.LaunchURL(XGOD_BUY_URL) end)
                    end
                end
                XGOD_SetKeyStatus(launched and "OPENING TELEGRAM..." or "OPEN TELEGRAM: t.me/zexygodx", not launched)
            end

            local editableCtor = nil
            _pcall(function() editableCtor = import("EditableTextBox") end)
            if editableCtor then
                local inputCtorOK, inputInstance = _pcall(editableCtor)
                if inputCtorOK then keyInput = inputInstance end
                keyPanel = ENew("/Script/UMG.CanvasPanel", canvas)
                if EValid(keyPanel) then
                    local keySlot = ESlot(canvas, keyPanel, 0, 0, W, H, 12500)
                    if keySlot then
                        _pcall(function()
                            local anchorsCtor = _rawget(_G, "FAnchors")
                            if _type(anchorsCtor) == "function" then
                                local okAnchors, anchors = _pcall(anchorsCtor, 0.5, 0.5, 0.5, 0.5)
                                if okAnchors and anchors ~= nil and _type(anchors) ~= "table" then keySlot:SetAnchors(anchors) end
                            end
                            local alignment, position, size = EVec(0.5, 0.5), EVec(0, 0), EVec(W, H)
                            if alignment then keySlot:SetAlignment(alignment) end
                            if position then keySlot:SetPosition(position) end
                            if size then keySlot:SetSize(size) end
                        end)
                    end
                    ELayer(keyPanel, 0, 0, W, H, ECol(0.02, 0.05, 0.08, 0.97), 1)
                    ELayer(keyPanel, 0, 0, W, 3, ECol(0.10, 0.90, 1.00, 1), 2)
                    ELayer(keyPanel, 0, H - 3, W, 3, ECol(0.10, 0.50, 0.80, 1), 2)
                    EText(keyPanel, "XGOD • LICENSE VERIFICATION", W * 0.5, 48, 20, ECol(0.10, 0.90, 1.00, 1), 5, 0.5, 0.5)
                    EText(keyPanel, "ENTER YOUR ACCESS KEY", W * 0.5, 92, 13, ECol(0.72, 0.86, 0.94, 1), 5, 0.5, 0.5)

                    if EValid(keyInput) then
                        _pcall(function() keyInput:SetHintText("Paste GODMOD key here...") end)
                        _pcall(function() keyInput:SetIsReadOnly(false) end)
                        ESlot(keyPanel, keyInput, 40, 125, W - 80, 48, 6)
                        EShowInteractive(keyInput)
                    end

                    keyStatusText = EText(keyPanel, "● PLEASE ENTER YOUR KEY", W * 0.5, 195, 12, ECol(0.20, 0.86, 0.60, 1), 7, 0.5, 0.5)

                    local function keyButton(label, x, width, strong, callback)
                        local btn = Button()
                        ESlot(keyPanel, btn, x, 235, width, 54, 8)
                        EShowInteractive(btn)
                        _pcall(function()
                            btn:SetBackgroundColor(strong and ECol(0.02, 0.48, 0.62, 1) or ECol(0.10, 0.16, 0.22, 1))
                        end)
                        EText(keyPanel, label, x + width * 0.5, 262, 13, ECol(1, 1, 1, 1), 9, 0.5, 0.5)
                        if btn.OnClicked and btn.OnClicked.Add then btn.OnClicked:Add(callback) end
                        return btn
                    end

                    keyVerifyButton = keyButton("VERIFY KEY", 40, 230, true, verifyEnteredKey)
                    keyButton("BUY KEY", 290, 230, false, openBuyKey)
                    EText(keyPanel, "KEY MANUAL & AUTO SUPPORTED", W * 0.5, 320, 11, ECol(0.45, 0.70, 0.82, 1), 10, 0.5, 0.5)

                    local keyEnums = _rawget(_G, "UEnums")
                    if keyEnums then
                        _pcall(function() keyPanel:SetWidgetVisibility(keyEnums.ESlateVisibility.Collapsed) end)
                    end
                end
            end

            local currentIndex = 1
            local isLoading = false
            local function updateDisplay()
                local entry = GODMOD_PAYLOAD_FILES[currentIndex]
                if entry and fileText then
                    fileText:SetText(entry.name)
                    statusText:SetText("● READY TO SELECT")
                    _pcall(function() statusText:SetColorAndOpacity(ESlate(ECol(0.20, 0.86, 0.60, 1))) end)
                end
            end

            createBtn("‹", 30, 210, 60, 50, false, function()
                currentIndex = currentIndex - 1
                if currentIndex < 1 then currentIndex = #GODMOD_PAYLOAD_FILES end
                updateDisplay()
            end)

            createBtn("SELECT VERSI MOD", 100, 210, W - 200, 50, true, function()
                local entry = GODMOD_PAYLOAD_FILES[currentIndex]
                if not entry or XGOD.keyVerified ~= true or isLoading or XGOD.payloadLoaded == true or XGOD.payloadLoading == true then return end
                isLoading = true
                XGOD.payloadLoading = true
                
                -- Tampilin status loading
                statusText:SetText("DOWNLOAD • PLEASE WAIT...")
                _pcall(function() statusText:SetColorAndOpacity(ESlate(ECol(1.00, 0.78, 0.20, 1))) end)

                local started = GODMOD_LoadPayloadFromWorker(entry.file, function(msg, isError)
                    isLoading = false
                    XGOD.payloadLoading = false
                    if not isError then
                        -- Flag global bertahan ketika karakter/match dibuat ulang.
                        XGOD.payloadLoaded = true
                        XGOD.payloadLoading = false
                        XGOD.selectorShown = false
                        XGOD.loadedFile = entry.file
                        rawset(_G, "__XGOD_SESSION_STATE", XGOD)
                        rawset(_G, "XGOD", XGOD)
                    end
                    _pcall(function() if EValid(statusText) then statusText:SetText(msg) end end)
                    if isError then
                        -- KALO ERROR/GAGAL/TIMEOUT, PASTI MUNCUL TEKS MERAH!
                        _pcall(function() if EValid(statusText) then statusText:SetColorAndOpacity(ESlate(ECol(1.00, 0.28, 0.28, 1))) end end)
                    else
                        -- Sukses: tutup UI langsung. Session latch mencegah UI dipanggil lagi
                        -- ketika kembali ke lobby atau masuk match berikutnya.
                        _pcall(function() if EValid(statusText) then statusText:SetColorAndOpacity(ESlate(ECol(0.20, 0.86, 0.60, 1))) end end)
                        _pcall(function()
                            if EValid(selectorPanel) then selectorPanel:RemoveFromParent() end
                            if EValid(selectorLogo) then selectorLogo:RemoveFromParent() end
                            if EValid(selectorLogoText) then selectorLogoText:RemoveFromParent() end
                        end)
                        selectorPanel = nil
                        selectorLogo = nil
                        selectorLogoText = nil
                    end
                end)
                if not started then
                    isLoading = false
                    XGOD.payloadLoading = false
                end
            end)

            createBtn("›", W - 90, 210, 60, 50, false, function()
                currentIndex = currentIndex + 1
                if currentIndex > #GODMOD_PAYLOAD_FILES then currentIndex = 1 end
                updateDisplay()
            end)
            return true
        end

        -- ============================================================
        -- START LOADER SAAT MODUL DIMUAT (LOADING AWAL), BUKAN SAAT MATCH.
        -- Logo tampil lebih dulu; panel Select tetap tersembunyi sampai Toggle ditekan.
        -- Retry sampai HUD siap. Status sukses dikunci sampai game restart.
        -- ============================================================
        -- ============================================================
        -- START XGOD LOADER
        -- Mengikuti urutan inisialisasi ClientEntry.
        -- ============================================================

        local function startInitialLoader()
            if XGOD.payloadLoaded == true then return end
            if XGOD.payloadLoading == true then return end
            if EValid(selectorPanel) then return end

            -- Dependency load is protected: missing/late HUD modules are retried, not fatal.
            pcall(require, "game_frontend_hud")
            pcall(require, "client.slua_ui_framework.manager")
            local ok, result = pcall(BuildSelectorUI)

            if not ok or result == false then
                local tickerOK, ticker = pcall(require, "common.time_ticker")

                if tickerOK and ticker and ticker.AddTimerOnce then
                    pcall(ticker.AddTimerOnce, 1.0, startInitialLoader)
                end
            end
        end

        local tickerOK, ticker = pcall(require, "common.time_ticker")

        if tickerOK and ticker and ticker.AddTimerOnce then
            local timerOK = pcall(
                ticker.AddTimerOnce,
                3.0,
                startInitialLoader
            )

            if not timerOK then
                startInitialLoader()
            end
        else
            startInitialLoader()
        end
    end
end
