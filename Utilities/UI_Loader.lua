local launcherData = game:GetService("HttpService"):JSONDecode((game:HttpGet("https://raw.githubusercontent.com/Trollmaster847/InfinityHub/main/Utilities/Modules/Hub_MetaData.json")));

local statusData = launcherData["StatusData"];
local latestVersion = launcherData["LatestVersion"];

print(statusData["InfinityHub"], statusData["InfinityHub_API"], statusData["InfinityHub_Launcher"])

for i, v in pairs(statusData) do
    print(i..":", v)
end

if statusData["InfinityHub_API"] == "Offline" or statusData["InfinityHub"] == "Offline" or statusData["InfinityHub_Launcher"] == "Offline" then
	spawn(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {Title = "Error", Text = "An error ocurred trying to load the hub!, Please try again later",Button1 = "OK", Duration = 25;})
	end)
	return
end

warn("Hub Initialized")
loadstring(game:HttpGet(latestVersion))();
