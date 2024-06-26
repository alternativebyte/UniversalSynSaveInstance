-- Prints all important yet hidden (NotScriptable) properties that could be missing from saveinstace file after it's done saving
-- due to broken gethiddenproperty on certain executors, therefore we must check all of these and verify it doesn't happen
-- if it does then please make an issue/pull request
-- Example of such case: Color3uint8 is prefered way to save Part's Color but this property is NotScriptable and might fail on certain executors therefore we must add a fallback redirect!

-- Only types to fail so far: BinaryString, SharedString, Color3uint8

local ClassList
local GlobalSettings, GlobalBasicSettings = settings(), UserSettings()
local service = setmetatable({}, {
	__index = function(Self, Name)
		local Service = game:GetService(Name) or GlobalSettings:GetService(Name) or GlobalBasicSettings:GetService(Name)
		Self[Name] = Service
		return Service
	end,
})
-- service.HttpService.HttpEnabled = true
local function ArrayToDictionary(Table, HybridMode)
	local tmp = table.create(#Table)

	if HybridMode == "adjust" then
		for Some1, Some2 in Table do
			if type(Some1) == "number" then
				tmp[Some2] = true
			elseif type(Some2) == "table" then
				tmp[Some1] = ArrayToDictionary(Some2, "adjust") -- Some1 is Class, Some2 is Name
			else
				tmp[Some1] = Some2
			end
		end
	else
		for _, Key in Table do
			tmp[Key] = true
		end
	end

	return tmp
end
local s = ""
local function Find(String, Pattern)
	return string.find(String, Pattern, nil, true)
end

do
	-- TODO: More @ https://github.com/Dekkonot/rbx-instance-serializer/blob/23f772f6f78af879a21faa9fea3e6c4f93d1cdee/src/API.lua#L19

	local function FetchAPI()
		local API_Dump_Url =
			"https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/roblox/Mini-API-Dump.json"
		local API_Dump = game:HttpGet(API_Dump_Url, true)
		local API_Classes = service.HttpService:JSONDecode(API_Dump).Classes

		local classList = {}

		for _index_0 = 1, #API_Classes do
			local API_Class = API_Classes[_index_0]
			local ClassMembers = API_Class.Members

			local Class = {}

			local ClassName = API_Class.Name

			local ClassTags = API_Class.Tags

			if ClassTags then
				ClassTags = ArrayToDictionary(ClassTags)
			end

			-- ClassInfo.Name = ClassName
			Class.Tags = ClassTags -- or {}
			Class.Superclass = API_Class.Superclass

			local ClassProperties = {}

			for _index_1 = 1, #ClassMembers do
				local Member = ClassMembers[_index_1]
				if Member.MemberType == "Property" then
					local PropertyName = Member.Name

					-- ? We avoid this as some Instances like services may have this property locked and thus make file unable to open and it's not even used by Roblox anyways as Parent-Child relationship is done by embedding/nesting

					local Ignored = false
					if not (Ignored and Ignored[PropertyName]) then
						local MemberTags = Member.Tags

						local Special

						if MemberTags then
							MemberTags = ArrayToDictionary(MemberTags)

							Special = MemberTags.NotScriptable
						end
						local Serialization = Member.Serialization
						if Serialization.CanLoad and Serialization.CanSave and Special then
							local instance
							if ClassTags and ClassTags.NotCreatable then
								instance = game:FindFirstChildWhichIsA(ClassName, true)
							else
								instance = Instance.new(ClassName)
							end

							local o, r = true, true
							if instance then
								o, r = pcall(gethiddenproperty, instance, PropertyName)
							else
								o, r = false, "Couldn't Create Class"
							end

							(not o and warn or print)(ClassName, PropertyName, not o and r or "")
						end
						local ValueType = Member.ValueType

						local Property = {
							Name = PropertyName,
							Category = ValueType.Category,
							Default = Member.Default,
							-- Tags = MemberTags,
							ValueType = ValueType.Name,
						}

						if Special then
							Property.Special = true
						end

						ClassProperties[PropertyName] = Property
					end
				end
			end

			Class.Properties = ClassProperties

			classList[ClassName] = Class
		end

		-- classList.Instance.Properties.Parent = nil -- ? Not sure if this is a better option than filtering throguh properties to remove this

		return classList
	end

	local ok, result = pcall(FetchAPI)

	if ok then
		ClassList = result
	else
		warn(result)
		return
	end
end
