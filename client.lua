local spot
local jobGarage
local allJobgrades
local visible = false
local passedCheck = false

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end
	while ESX.GetPlayerData().job == nil do
		Citizen.Wait(10)
	end
	ESX.PlayerData = ESX.GetPlayerData()

	TriggerServerEvent('just_multijob:getJobs')
	allJobgrades = lib.callback.await('just_multijob:getAllGrades', false)
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded',function(xPlayer, isNew, skin)
	ESX.PlayerData = ESX.GetPlayerData()

	TriggerServerEvent('just_multijob:getJobs')
	allJobgrades = lib.callback.await('just_multijob:getAllGrades', false)
end)

RegisterNetEvent('esx:onPlayerLogout')
AddEventHandler('esx:onPlayerLogout', function()
	spot = nil
	jobGarage = nil
	allJobgrades = nil
	visible = false
	passedCheck = false
end)

RegisterNetEvent("esx:setJob")
AddEventHandler("esx:setJob", function(job)
	ESX.PlayerData.job = job
end)

local jobs = {}

function Split(s, delimiter)
    if s ~= nil then
        result = {};
        for match in (s..delimiter):gmatch("(.-)"..delimiter) do
            table.insert(result, match);
        end
        return result;
    end
end

function onEnter(self)
end

function onExit(self)
	if self.type == "garage" then
		lib.hideTextUI()
		jobGarage = nil
		Citizen.Wait(100)
		visible = false
		passedCheck = false
	end
end

function insideZone(self)
	local ped = PlayerPedId()
	local inVehicle = GetVehiclePedIsIn(ped, false)
	local location = Split(self.name, " ")
	if passedCheck then
		if not visible then
			if inVehicle ~= 0 then
				visible = true
				lib.showTextUI("[E] Store Vehicle", {icon = "fa-solid fa-car"})
			else
				visible = true
				lib.showTextUI("[E] Open Garage", {icon = "fa-solid fa-car"})
			end
		end
		if IsControlJustReleased(0, 54) then
			if inVehicle ~= 0 then
				lib.hideTextUI()
				TriggerEvent('just_multijob:StoreVehicle', inVehicle)
				visible = false
				passedCheck = false
			else
				lib.hideTextUI()
				TriggerEvent('just_multijob:GetOwnedVehicles', jobGarage)
				visible = false
				passedCheck = false
			end
		end
	else
		if Config.locations[location[1]].job == ESX.PlayerData.job.name then
			spot = location[3]
			jobGarage = location[1]
			passedCheck = true
		else
			if #jobs < 1 then
				TriggerServerEvent('just_multijob:getJobs')
			end
			for i=1, #jobs, 1 do
				if jobs[i].job == Config.locations[location[1]].job then
					spot = location[3]
					passedCheck = true
					jobGarage = location[1]
					break
				end
			end
		end
	end
end

for k, v in pairs(Config.locations) do
	exports.ox_target:addBoxZone({
		coords = vec3(v.onoffduty.x, v.onoffduty.y, v.onoffduty.z),
		size = vec3(v.onoffduty.w, v.onoffduty.l, v.onoffduty.height),
		rotation = v.onoffduty.h,
		debug = false,
		options = {
			{
				name = k.." signOff",
				serverEvent = 'just_multijob:setJob',
				icon = v.icon,
				label = 'Clock off from '..v.label,
				job = "unemployed",
				canInteract = function(entity, distance, coords, name)
					if Config.locations[k].job == ESX.PlayerData.job.name then
						return true
					end
				end,
				distance = 2.5
			},
			{
				name = k.." signOn",
				serverEvent = 'just_multijob:setJob',
				icon = v.icon,
				label = 'Clock on at '..v.label,
				job = v.job,
				canInteract = function(entity, distance, coords, name)
					if Config.locations[k].job ~= ESX.PlayerData.job.name then
						if #jobs < 1 then
							TriggerServerEvent('just_multijob:getJobs')
						end
						for i=1, #jobs, 1 do
							if jobs[i].job == v.job then
								return true
							elseif i == #jobs then
								TriggerServerEvent('just_multijob:getJobs')
							end
						end
					end
				end,
				distance = 2.5
			}
		}
	})
	if v.managerPC ~= nil then
		for k4, v4 in pairs(v.managerPC) do
			exports.ox_target:addBoxZone({
				coords = vec3(v4.x, v4.y, v4.z),
				size = vec3(v4.l, v4.w, v4.height),
				rotation = v4.h,
				debug = false,
				options = {
					{
						name = k.." ManageEmployees",
						event = 'just_multijob:managementMenu',
						icon = "fa-solid fa-users",
						label = 'Manage '..v.label.. " employees",
						job = v.job,
						canInteract = function(entity, distance, coords, name)
    						local jobGrades = {}
							for i=1, #allJobgrades, 1 do
								if allJobgrades[i].job_name == v.job then
									table.insert(jobGrades, allJobgrades[i].grade)
								end
							end
							table.sort(jobGrades, function(a,b) return a<b end)
							if Config.locations[k].job == ESX.PlayerData.job.name and ESX.PlayerData.job.grade >= (jobGrades[#jobGrades] - 1) then
								return true
							end
						end,
						distance = 2.5
					},
					{
						name = k.." ManageEmployees",
						event = 'just_multijob:hire',
						icon = "fa-solid fa-user-plus",
						label = 'Hire employee at '..v.label,
						job = v.job,
						business = k,
						canInteract = function(entity, distance, coords, name)
    						local jobGrades = {}
							for i=1, #allJobgrades, 1 do
								if allJobgrades[i].job_name == v.job then
									table.insert(jobGrades, allJobgrades[i].grade)
								end
							end
							table.sort(jobGrades, function(a,b) return a<b end)
							if Config.locations[k].job == ESX.PlayerData.job.name and ESX.PlayerData.job.grade >= (jobGrades[#jobGrades] - 1) then
								return true
							end
						end,
						distance = 2.5
					},
					{
						name = k.." RenameGrades",
						event = 'just_multijob:renameRank',
						icon = "fa-solid fa-i-cursor",
						label = 'Rename '..v.label.." employee titles",
						job = v.job,
						business = k,
						canInteract = function(entity, distance, coords, name)
							if Config.allowJobGradeRename then
								local jobGrades = {}
								for i=1, #allJobgrades, 1 do
									if allJobgrades[i].job_name == v.job then
										table.insert(jobGrades, allJobgrades[i].grade)
									end
								end
								table.sort(jobGrades, function(a,b) return a<b end)
								if Config.locations[k].job == ESX.PlayerData.job.name and ESX.PlayerData.job.grade >= (jobGrades[#jobGrades] - 1) then
									return true
								end
							end
						end,
						distance = 2.5
					}
				}
			})
		end
	end
	if v.storage ~= nil and Config.UseOxInventory then
		for k2, v2 in pairs(v.storage) do
			exports.ox_target:addBoxZone({
				coords = vec3(v2.x, v2.y, v2.z),
				size = vec3(v2.w, v2.l, v2.height),
				rotation = v2.h,
				debug = false,
				options = {
					{
						name = k.."stash"..v2.id,
						event = 'just_multijob:useStash',
						icon = "fa-solid fa-box-open",
						label = 'Open '..v2.label,
						stash = (k.."Stash"..v2.id),
						canInteract = function(entity, distance, coords, name)
							if Config.locations[k].job == ESX.PlayerData.job.name then
								return true
							else
								if #jobs < 1 then
									TriggerServerEvent('just_multijob:getJobs')
								end
								for i=1, #jobs, 1 do
									if jobs[i].job == v.job then
										return true
									elseif i == #jobs then
										TriggerServerEvent('just_multijob:getJobs')
									end
								end
							end
						end,
						distance = 2.5
					}
				}
			})
		end
	end
	if v.parking ~= nil and Config.useGarages then
		for k3, v3 in pairs(v.parking) do
			lib.zones.box({
				coords = vec3(v3.x, v3.y, v3.z),
				size = vec3(3, 5.4, 4),
				rotation = v3.h,
				debug = false,
				inside = insideZone,
				onEnter = onEnter,
				onExit = onExit,
				name = k.." parking "..k3,
				type = "garage",
			})
		end
	end
end

RegisterNetEvent('just_multijob:sendJobs')
AddEventHandler('just_multijob:sendJobs', function(joblist)
	jobs = joblist
end)

RegisterNetEvent('just_multijob:useStash')
AddEventHandler('just_multijob:useStash', function (data)
    exports.ox_inventory:openInventory('stash', data.stash)
end)

TriggerEvent('chat:addSuggestion', '/offduty', 'Clock off current job')
RegisterCommand('offduty', function()
	local data = {job = "unemployed"}
	TriggerServerEvent('just_multijob:setJob', data)
end, false)

RegisterNetEvent('just_multijob:notification')
AddEventHandler('just_multijob:notification', function (header, footer, alertType)
	lib.notify({
		title = header,
		description = footer,
		type = alertType
	})
end)

-------------
-- Garages --
-------------

RegisterNetEvent('just_multijob:GetOwnedVehicles')
AddEventHandler('just_multijob:GetOwnedVehicles', function (jobGarage)
    local vehicles = lib.callback.await('just_multijob:GetVehicles', false, jobGarage)
    local options = {}
    if not vehicles then
        lib.registerContext({
            id = 'just_multijob:GarageMenu',
            title = Config.locations[jobGarage].label.." Garage",
            options = {{title = "No vehicles parked"}}
        })
        return lib.showContext('just_multijob:GarageMenu')
    end
    for i = 1, #vehicles do
        local data = vehicles[i]
        local vehicleMake = GetLabelText(GetMakeNameFromVehicleModel(data.vehicle.model))
        local vehicleModel = GetLabelText(GetDisplayNameFromVehicleModel(data.vehicle.model))
        local vehicleTitle = vehicleMake .. ' ' .. vehicleModel
        local stored = data.stored
		-- print(vehicleTitle, data.plate, stored)
		if stored then
			table.insert(options, {
				title = vehicleTitle,
				event = 'just_multijob:VehicleMenu',
				arrow = true,
				args = {name = vehicleTitle, plate = data.plate, model = vehicleModel, vehicle = data.vehicle},
				metadata = {
					{label = 'Plate', value = data.plate},
				}
			})
		end
    end
    lib.registerContext({
        id = 'just_multijob:GarageMenu',
		title = Config.locations[jobGarage].label.." Garage",
        options = options
    })
    lib.showContext('just_multijob:GarageMenu')
end)

RegisterNetEvent('just_multijob:VehicleMenu')
AddEventHandler('just_multijob:VehicleMenu', function (data)
    lib.registerContext({
        id = 'just_multijob:VehicleMenu',
        title = data.name,
        menu = 'just_multijob:GarageMenu',
        options = {
            {
				title = 'Take out vehicle',
                event = 'just_multijob:RequestVehicle',
                args = {
                    vehicle = data.vehicle,
                    type = 'garage'
                }
            }
        }
    })

    lib.showContext('just_multijob:VehicleMenu')
end)

local function spawnVehicle(data, spawn)
    lib.requestModel(data.vehicle.model)
	exports['just_vehControl']:givePlayerKeys(data.vehicle.plate)
    TriggerServerEvent('just_multijob:SpawnVehicle', data.vehicle.model, data.vehicle.plate, spawn, spawn.h)
	lib.hideTextUI()
	Citizen.Wait(250)
	visible = false
end

RegisterNetEvent('just_multijob:RequestVehicle')
AddEventHandler('just_multijob:RequestVehicle', function (data)
	local spawn = Config.locations[jobGarage].parking[spot]
	if ESX.Game.IsSpawnPointClear(vector3(spawn.x, spawn.y, spawn.z), 1.0) then
		return spawnVehicle(data, spawn)
	end
end)

RegisterNetEvent('just_multijob:StoreVehicle')
AddEventHandler('just_multijob:StoreVehicle', function (veh)
    local vehicle = veh
    local vehPlate = GetVehicleNumberPlateText(vehicle)
    local vehProps = lib.getVehicleProperties(vehicle)
    local isOwned = lib.callback.await('just_multijob:CheckOwnership', false, vehPlate)
	if isOwned and jobGarage ~= nil then
		TriggerServerEvent('just_multijob:SaveVehicle', vehProps, vehPlate, VehToNet(vehicle), jobGarage)
		lib.hideTextUI()
		Citizen.Wait(250)
		visible = false
	end
end)

----------------
-- Management --
----------------

RegisterNetEvent('just_multijob:managementMenu')
AddEventHandler('just_multijob:managementMenu', function(target)
	local job = target.job
    local jobGrades = lib.callback.await('just_multijob:getJobGrades', false, job)
	local elements = {
		head = {'Name', 'Position', 'Actions'},
		rows = {}
	}
	lib.callback('just_multijob:getEmployees', false, function(employees)
		for i=1, #employees, 1 do
			for k, v in pairs(jobGrades) do
				if v.grade == employees[i].grade then
					table.insert(elements.rows, {
						data = employees[i],
						cols = {
							employees[i].name,
							v.label,
							'{{' .. 'Change Rank' .. '|changeRank}} {{' .. 'Fire' .. '|fire}}'
						}
					})
					break
				end
			end
			local rankOptions = {}
			for i=1, #allJobgrades, 1 do
				if allJobgrades[i].job_name == job then
					-- print(allJobgrades[i].grade, allJobgrades[i].label)
					table.insert(rankOptions, {value = allJobgrades[i].grade, label = allJobgrades[i].label})
				end
			end
			if i == #employees then
				ESX.UI.Menu.Open('list', GetCurrentResourceName(), 'employee_list_' .. job, elements, function(data, menu)
					local employee = data.data
					if data.value == 'changeRank' then
						menu.close()
						local input = lib.inputDialog('Change Rank', {
							{ type = 'select', label = 'Select Rank', options = rankOptions}
						})
						if not input then return end
						-- exports.xng_parsingtable:ParsingTable_cl(input)
						local rank = tonumber(input[1])
						TriggerServerEvent('just_multijob:changeRank', employee, "changeRank", rank)
					elseif data.value == 'fire' then
						TriggerServerEvent('just_multijob:changeRank', employee, "fire")
						menu.close()
					end
				end, function(data, menu)
					menu.close()
				end)
			end
		end
	end, job)
end)

RegisterNetEvent('just_multijob:hire')
AddEventHandler('just_multijob:hire', function(data)
	local rankOptions = {}
	for i=1, #allJobgrades, 1 do
		if allJobgrades[i].job_name == data.job then
			-- print(allJobgrades[i].grade, allJobgrades[i].label)
			table.insert(rankOptions, {value = allJobgrades[i].grade, label = allJobgrades[i].label})
		end
	end	local input = lib.inputDialog(('Hire at '..Config.locations[data.business].label),{
		{ type = "input", label = "Player ID", placeholder = "123" },
		{ type = 'select', label = 'Select Rank', options = rankOptions}
	})
	if not input then return end
	TriggerServerEvent('just_multijob:changeRank', data, "hire", nil, input)
end)

RegisterNetEvent('just_multijob:renameRank')
AddEventHandler('just_multijob:renameRank', function(data)
	local rankOptions = {}
	for i=1, #allJobgrades, 1 do
		if allJobgrades[i].job_name == data.job then
			-- print(allJobgrades[i].id, allJobgrades[i].label)
			table.insert(rankOptions, {value = allJobgrades[i].id, label = allJobgrades[i].label})
		end
	end	local input = lib.inputDialog(('Rename '..Config.locations[data.business].label.." rank"),{
		{ type = "input", label = "New name", placeholder = "A fitting Name" },
		{ type = 'select', label = 'Select Rank', options = rankOptions}
	})
	if not input then return end
	TriggerServerEvent('just_multijob:renameRank', input[1], input[2])
	allJobgrades = lib.callback.await('just_multijob:getAllGrades', false)
end)