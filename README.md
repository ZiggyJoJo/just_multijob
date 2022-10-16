# Just_Multijob
<br><div><h4 align='center'><a href='https://youtu.be/5Ebm4gBbUr0'>Video Demo</a></h4></div><br>
# Description

* All options are adjustable in the config

* Allows players to have multiple jobs at once 
* The top two ranks can manage employees and rename job job grades (Can be dissabled in config)
* Includes shared garages for each businnes (Can be dissabled in config)
* Includes shared storage for each businnes (Can be dissabled in config)
* Includes Cardealer, Police, EMS, and Taxi jobs by default but you can easilly add more in the config
# Dependencies

- ESX 
- https://github.com/overextended/ox_lib  
- https://github.com/overextended/ox_target

# Config
https://i.imgur.com/zPuQ3JH.png

# Usage

Server Side event

``` if #jobs < 1 then
        jobs = MySQL.scalar.await('SELECT jobs FROM users WHERE identifier = @identifier', {['@identifier'] = player.identifier})
        jobs = json.decode(jobs)
    end
    for i=1, #jobs, 1 do
        for k, v in pairs(door.groups) do
            if jobs[i].job == k then
                return true
            elseif i == #jobs then
                jobs = MySQL.scalar.await('SELECT jobs FROM users WHERE identifier = @identifier', {['@identifier'] = player.identifier})
                jobs = json.decode(jobs)
            end
        end
    end
```
Server Side Example

ox_doorlock serveer/framework.lua line 44 add
```
	if door.groups then
		if #jobs < 1 then
			jobs = MySQL.scalar.await('SELECT jobs FROM users WHERE identifier = @identifier', {['@identifier'] = player.identifier})
			jobs = json.decode(jobs)
		end
		for i=1, #jobs, 1 do
			for k, v in pairs(door.groups) do
				if jobs[i].job == k then
					return true
				elseif i == #jobs then
					jobs = MySQL.scalar.await('SELECT jobs FROM users WHERE identifier = @identifier', {['@identifier'] = player.identifier})
					jobs = json.decode(jobs)
				end
			end
		end
	end
```

Client Side Callback

```passed = lib.callback.await('just_multijob:checkForJob', false, jobname)```


# Support Me
<br><div><h4 align='left'><a href='https://www.buymeacoffee.com/ZiggyJoJo'>Buy Me A Coffee</a></h4></div><br>
<br><div><h4 align='left'><a href='https://ziggys-scripts.tebex.io'>Tebex</a></h4></div><br>
<br><div><h4 align='center'><a href='https://discord.gg/AWxBT49HR5'>Discord Server</a></h4></div><br>
