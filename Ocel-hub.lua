--[[
    Ocel-Hub / Dropzone Loader
    Auto-fetches the latest AdvancedESP module directly from Rostik22803/dropzone
]]

local repoOwner = "Rostik22803"
local repoName = "dropzone"
local branch = "main"

local url = string.format("https://raw.githubusercontent.com/%s/%s/%s/AdvancedESP.lua", repoOwner, repoName, branch)

local success, result = pcall(function()
    return game:HttpGet(url, true)
end)

if not success or not result or result == "" then
    warn("[Ocel-Hub] Failed to fetch script from GitHub:", tostring(result))
    return
end

local fn, compileErr = loadstring(result)
if not fn then
    warn("[Ocel-Hub] Compilation error:", tostring(compileErr))
    return
end

print("[Ocel-Hub] Loaded AdvancedESP successfully.")
return fn()
