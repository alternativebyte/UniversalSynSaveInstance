--loadstring(game:HttpGet("https://raw.githubusercontent.com/alternativebyte/UniversalSynSaveInstance/main/loadstring.luau",true))()

local Params = {RepoURL = "https://raw.githubusercontent.com/alternativebyte/UniversalSynSaveInstance/main/",SSI = "saveinstance"}
local synsaveinstance = loadstring(game:HttpGet(Params.RepoURL .. Params.SSI .. ".luau", true), Params.SSI)()
synsaveinstance({})
