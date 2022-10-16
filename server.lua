ESX             = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

local jobs = {}

RegisterServerEvent("just_multijob:getJobs")
AddEventHandler("just_multijob:getJobs", function()
	local xPlayer = ESX.GetPlayerFromId(source)
    local _source = source
    local jobs = MySQL.scalar.await('SELECT jobs FROM users WHERE identifier = @identifier', {['@identifier'] = xPlayer.identifier})
    if jobs then
        TriggerClientEvent('just_multijob:sendJobs', _source, json.decode(jobs))
    end
end)

ESX.RegisterCommand('addjob', 'admin', function(xPlayer, args, showError)
	if ESX.DoesJobExist(args.job, args.grade) then
        TriggerEvent('just_multijob:addJob', args)
	else
		showError("Invvalid job")
	end
end, true, {help = "Add job to player", validate = true, arguments = {
	{name = 'playerId', help = "[playerId]", type = 'player'},
	{name = 'job', help = "[job]", type = 'string'},
	{name = 'grade', help = "[grade]", type = 'number'}
}})

RegisterServerEvent("just_multijob:addJob")
AddEventHandler("just_multijob:addJob", function(data)
	local xPlayer = ESX.GetPlayerFromId(data.playerId.source)
    local jobs = {}
    local updateSQL = true
    local result = MySQL.scalar.await('SELECT jobs FROM users WHERE identifier = ?',{xPlayer.identifier})
    if result then
        jobs = json.decode(result)
        for i=1, #jobs, 1 do
            if jobs[i].job == data.job then
                updateSQL = false
                break
            elseif i == #jobs then 
                table.insert(jobs,  {job = data.job, grade = data.grade})
            end
        end
    else
        table.insert(jobs,  {job = data.job, grade = data.grade})
    end

    if updateSQL then
        MySQL.update('UPDATE users SET jobs = ? WHERE identifier = ?', {json.encode(jobs), xPlayer.identifier}, function(affectedRows)
            if affectedRows then
                print(affectedRows)
            end
        end)
    end
    TriggerClientEvent('just_multijob:sendJobs', data.playerId.source, jobs)
end)

RegisterServerEvent("just_multijob:setJob")
AddEventHandler("just_multijob:setJob", function(data)
    local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)
    -- print(data.job)
    if data.job == "unemployed" and xPlayer.job.name ~= "unemployed" then
        xPlayer.setJob("unemployed", 0)
        TriggerClientEvent("just_multijob:notification", _source, "Time for a break", nil, "success")
    elseif data.job ~= "unemployed" then
        local jobs = MySQL.scalar.await('SELECT jobs FROM users WHERE identifier = @identifier', {['@identifier'] = xPlayer.identifier})
        local jobgrade
        jobs = json.decode(jobs)
        TriggerClientEvent("just_multijob:notification", _source, "Time to get to work", nil, "success")
        -- exports.xng_parsingtable:ParsingTable_sv(jobs)

        for k, v in pairs(jobs) do
            -- print(v.job, v.grade)
            if v.job == data.job then
                jobgrade = v.grade
            end
        end
        xPlayer.setJob(data.job, jobgrade)
    end
end)

-------------
-- Stashes --
-------------

AddEventHandler('onServerResourceStart', function(resourceName)
    if resourceName == 'ox_inventory' or resourceName == GetCurrentResourceName() and Config.UseOxInventory then
        for k, v in pairs(Config.locations) do
            if v.storage ~= nil then
                for k2, v2 in pairs(v.storage) do
                    exports.ox_inventory:RegisterStash((k.."Stash"..v2.id), (v.label.." Stash - "..v2.id), v2.slots, v2.weight, false)
                end
            end
        end
    end
end)

-------------
-- Garages --
-------------


lib.callback.register('just_multijob:GetVehicles', function(source, garage)
    local vehicles = {}
    local results = MySQL.Sync.fetchAll("SELECT `plate`, `vehicle`, `stored`, `garage`, `job` FROM `owned_vehicles` WHERE `garage` = @garage", {
        ['@garage'] = garage
    })
    if results[1] ~= nil then
        for i = 1, #results do
            local result = results[i]
            local veh = json.decode(result.vehicle)
            vehicles[#vehicles+1] = {plate = result.plate, vehicle = veh, stored = result.stored, garage = result.garage}
        end
        return vehicles
    end
end)

RegisterServerEvent("just_multijob:SpawnVehicle")
AddEventHandler("just_multijob:SpawnVehicle", function(model, plate, coords, heading)
    if type(model) == 'string' then model = GetHashKey(model) end
    local xPlayer = ESX.GetPlayerFromId(source)
    local vehicles = GetAllVehicles()
    plate = ESX.Math.Trim(plate)
    for i = 1, #vehicles do
        if ESX.Math.Trim(GetVehicleNumberPlateText(vehicles[i])) == plate then
            if GetVehiclePetrolTankHealth(vehicle) > 0 and GetVehicleBodyHealth(vehicle) > 0 then
            return xPlayer.showNotification(Locale('vehicle_already_exists')) end
        end
    end
    MySQL.Async.fetchAll('SELECT vehicle, plate, garage FROM `owned_vehicles` WHERE plate = @plate', {['@plate'] = ESX.Math.Trim(plate)}, function(result)
        if result[1] then
            CreateThread(function()
                local entity = Citizen.InvokeNative(`CREATE_AUTOMOBILE`, model, coords.x, coords.y, coords.z, heading)
                local ped = GetPedInVehicleSeat(entity, -1)
                if ped > 0 then
                    for i = -1, 6 do
                        ped = GetPedInVehicleSeat(entity, i)
                        local popType = GetEntityPopulationType(ped)
                        if popType <= 5 or popType >= 1 then
                            DeleteEntity(ped)
                        end
                    end
                end
                local playerPed = GetPlayerPed(xPlayer.source)
                local timer = GetGameTimer()
                while GetVehiclePedIsIn(playerPed) ~= entity do
                    Wait(10)
                    SetPedIntoVehicle(playerPed, entity, -1)
                    if timer - GetGameTimer() > 15000 then
                        break
                    end
                end
                local ent = Entity(entity)
                ent.state.vehicleData = result[1]
            end)
        end
    end)
end)

RegisterServerEvent("just_multijob:SaveVehicle")
AddEventHandler("just_multijob:SaveVehicle", function(vehicle, plate, ent, garage)
    MySQL.Async.execute('UPDATE `owned_vehicles` SET `vehicle` = @vehicle, `garage` = @garage, `last_garage` = @garage, `stored` = @stored WHERE `plate` = @plate', {
        ['@vehicle'] = json.encode(vehicle),
        ['@plate'] = ESX.Math.Trim(plate),
        ['@stored'] = 1,
        ['@garage'] = garage
    })
    local ent = NetworkGetEntityFromNetworkId(ent)
    DeleteEntity(ent)
end)

lib.callback.register('just_multijob:CheckOwnership', function(source, plate)
    local result = MySQL.scalar.await('SELECT vehicle FROM owned_vehicles WHERE plate = ?', {plate})
    if result ~= nil then
        return true
    else
        -- Player tried to cheat
        TriggerClientEvent("just_multijob:notification", source, "Wait this is a local's vehicle", nil, "error")
        return false
    end
end)

----------------
-- Management --
----------------

lib.callback.register('just_multijob:getEmployees', function(source, job)
    local employees = {}
    local result = MySQL.Sync.fetchAll("SELECT `identifier`, `firstname`, `lastname`, `jobs` FROM users")
    if result then
        for i = 1, #result do
            local row = result[i]
            if row.jobs ~= nil then
                for k, v in pairs(json.decode(row.jobs)) do
                    if v.job == job then
                        table.insert(employees, {
                            name = result[i].firstname .. ' ' .. result[i].lastname,
                            identifier  = result[i].identifier,
                            job = v.job,
                            grade = v.grade,
                        })
                        break
                    end
                end
            end
        end
    end
    if employees ~= nil then
        return employees
    end
end)

lib.callback.register('just_multijob:getJobLabel', function(source, job)
    local jobLabel = MySQL.scalar.await('SELECT label FROM jobs WHERE name = ?',{job})
    if jobLabel ~= nil then
        return jobLabel
    end
end)

lib.callback.register('just_multijob:getJobGrades', function(source, job)
    local jobGrades = MySQL.Sync.fetchAll("SELECT `label`, `grade` FROM `job_grades` WHERE `job_name` = @job_name", {
        ['@job_name'] = job
    })
    if jobGrades[1] ~= nil then
        return jobGrades
    end
end)

lib.callback.register('just_multijob:getAllGrades', function(source, job)
    local jobGrades = MySQL.Sync.fetchAll("SELECT `id`, `job_name`, `grade`, `label` FROM `job_grades`")
    if jobGrades ~= nil then
        return jobGrades
    end
end)

RegisterServerEvent("just_multijob:changeRank")
AddEventHandler("just_multijob:changeRank", function(data, action, grade, input)
    local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)
    local playerID
    local tPlayer
    local jobs = {}
    if input ~= nil then
        playerID = tonumber(input[1])
	    tPlayer = ESX.GetPlayerFromId(playerID)
        jobs = {}
        jobs = MySQL.scalar.await('SELECT jobs FROM users WHERE identifier = ?',{tPlayer.identifier})
        if jobs then
            jobs = json.decode(jobs)
        end
    else
        jobs = {}

        jobs = MySQL.scalar.await('SELECT jobs FROM users WHERE identifier = ?',{data.identifier})
        if jobs then
            jobs = json.decode(jobs)
        end
    end
    if action == "changeRank" and xPlayer.identifier ~= data.identifier and xPlayer.job.grade >= grade then
        for k, v in pairs(jobs) do
            if v.job == data.job then
                table.remove(jobs, k)
                table.insert(jobs,  {job = data.job, grade = grade})
                MySQL.Async.execute('UPDATE `users` SET `jobs` = @jobs WHERE `identifier` = @identifier', {
                    ['@jobs'] = json.encode(jobs),
                    ['@identifier'] = data.identifier
                })
            end
        end
    elseif action == "fire" and xPlayer.identifier ~= data.identifier then
        for k, v in pairs(jobs) do
            if v.job == data.job then
                local yPlayer = ESX.GetPlayerFromIdentifier(data.identifier)
                if yPlayer ~= nil then
                    if yPlayer.job.name == data.job then
                        yPlayer.setJob("unemployed", 0)
                    end
                else
                    local job = MySQL.scalar.await('SELECT job FROM users WHERE identifier = ?',{data.identifier})
                    if job == data.job then
                        MySQL.Async.execute('UPDATE `users` SET `job` = @job, `job_grade` = @job_grade WHERE `identifier` = @identifier', {
                            ['@job'] = "unemployed",
                            ['@job_grade'] = 0,
                            ['@identifier'] = data.identifier
                        })
                    end
                end
                table.remove(jobs, k)
                MySQL.Async.execute('UPDATE `users` SET `jobs` = @jobs WHERE `identifier` = @identifier', {
                    ['@jobs'] = json.encode(jobs),
                    ['@identifier'] = data.identifier
                })
                break
            end
        end
    elseif action == "hire" and _source ~= playerID then
        if jobs ~= nil then
            local alreadyHired = false
	        for i=1, #jobs, 1 do
                if jobs[i].job == data.job then
                    alreadyHired = true
                    TriggerClientEvent("just_multijob:notification", _source, "This person already works here", nil, "error")
                    break
                elseif i == #jobs and not alreadyHired then
                    table.insert(jobs,  {job = data.job, grade = tonumber(input[2])})
                    MySQL.Async.execute('UPDATE `users` SET `jobs` = @jobs WHERE `identifier` = @identifier', {
                        ['@jobs'] = json.encode(jobs),
                        ['@identifier'] = tPlayer.identifier
                    })
                    TriggerClientEvent("just_multijob:notification", _source, "Successfully hired new employee", tPlayer.firstname, "success")
                    TriggerClientEvent("just_multijob:notification", playerID, "You've just been hired at "..Config.locations[data.business].label, nil, "success")
                end
            end
        else
            jobs = {}
            table.insert(jobs,  {job = data.job, grade = tonumber(input[2])})
            MySQL.Async.execute('UPDATE `users` SET `jobs` = @jobs WHERE `identifier` = @identifier', {
                ['@jobs'] = json.encode(jobs),
                ['@identifier'] = tPlayer.identifier
            })
            TriggerClientEvent("just_multijob:notification", _source, "Successfully hired new employee", tPlayer.firstname, "success")
            TriggerClientEvent("just_multijob:notification", playerID, "You've just been hired at "..Config.locations[data.business].label, nil, "success")
        end
    end
end)

RegisterServerEvent("just_multijob:renameRank")
AddEventHandler("just_multijob:renameRank", function(name, id)
    MySQL.Async.execute('UPDATE `job_grades` SET `label` = @label WHERE `id` = @id', {
        ['@label'] = name,
        ['@id'] = id
    })
end)

lib.callback.register('just_multijob:checkForJob', function(source, job)
    local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)
    if #jobs < 1 then
        jobs = MySQL.scalar.await('SELECT jobs FROM users WHERE identifier = @identifier', {['@identifier'] = xPlayer.identifier})
        jobs = json.decode(jobs)
    end
    for i=1, #jobs, 1 do
        if jobs[i].job == job then
            return true
        elseif i == #jobs then
            jobs = MySQL.scalar.await('SELECT jobs FROM users WHERE identifier = @identifier', {['@identifier'] = xPlayer.identifier})
            jobs = json.decode(jobs)
        end
    end
end)