local holdingPackage          = false
local dropkey 	= 246 -- Key to drop/get the props
local closestEntity = 0
ESX = nil

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end
end)

-- Prolist, you can add as much as you want
attachPropList = {
	{["model"] = 'prop_roadcone02a',				["name"] = "cone", 		["bone"] = 28422, ["x"] = 0.6,	["y"] = -0.15,	["z"] = -0.1,	["xR"] = 315.0,	["yR"] = 288.0, ["zR"] = 0.0, 	["anim"] = 'pick' }, -- Done
    	{["model"] = 'prop_cs_trolley_01',				["name"] = "trolley", 		["bone"] = 28422, ["x"] = 0.0,	["y"] = -0.6,	["z"] = -0.8,	["xR"] = -180.0,["yR"] = -165.0,["zR"] = 90.0, 	["anim"] = 'hold' }
}

RegisterNetEvent('inrp_propsystem:attachProp')
AddEventHandler('inrp_propsystem:attachProp', function(attachModelSent,boneNumberSent,x,y,z,xR,yR,zR)
	ESX.ShowNotification("~r~Y~w~ to pickup/drop                    ~r~ /r~w~ to remove", true, false, 120)
    closestEntity = 0
    holdingPackage = true
    local attachModel = GetHashKey(attachModelSent)
    SetCurrentPedWeapon(GetPlayerPed(-1), 0xA2719263) 
    local bone = GetPedBoneIndex(GetPlayerPed(-1), boneNumberSent)
    RequestModel(attachModel)
    while not HasModelLoaded(attachModel) do
        Citizen.Wait(0)
    end
    closestEntity = CreateObject(attachModel, 1.0, 1.0, 1.0, 1, 1, 0)
	for i=1 ,#attachPropList , 1 do
		if (attachPropList[i].model == attachModelSent) and (attachPropList[i].anim == 'hold') then
			holdAnim()
		end
	end
	Citizen.Wait(200)
    AttachEntityToEntity(closestEntity, GetPlayerPed(-1), bone, x, y, z, xR, yR, zR, 1, 1, 0, true, 2, 1)
end)

function loadAnimDict(dict)
    while (not HasAnimDictLoaded(dict)) do
        RequestAnimDict(dict)
        Citizen.Wait(0)
    end
end

function randPickupAnim()
  local randAnim = math.random(7)
    loadAnimDict('random@domestic')
    TaskPlayAnim(GetPlayerPed(-1),'random@domestic', 'pickup_low',5.0, 1.0, 1.0, 48, 0.0, 0, 0, 0)
end

function holdAnim()
    loadAnimDict( "anim@heists@box_carry@" )
	TaskPlayAnim((GetPlayerPed(-1)),"anim@heists@box_carry@","idle",4.0, 1.0, -1,49,0, 0, 0, 0)
end

Citizen.CreateThread( function()
    while true do 
		Citizen.Wait(10)		
		if IsPedOnFoot(GetPlayerPed(-1)) and not IsPedDeadOrDying(GetPlayerPed(-1)) then
			if IsControlJustReleased(0, dropkey) then
				local playerPed = PlayerPedId()
				local coords    = GetEntityCoords(playerPed)
				local closestDistance = -1
				closestEntity   = 0
				for i=1, #attachPropList, 1 do
					local object = GetClosestObjectOfType(coords, 1.5, GetHashKey(attachPropList[i].model), false, false, false)
					if DoesEntityExist(object) then
						local objCoords = GetEntityCoords(object)
						local distance  = GetDistanceBetweenCoords(coords, objCoords, true)
						if closestDistance == -1 or closestDistance > distance then
							closestDistance = distance
							closestEntity   = object
							if not holdingPackage then
								local dst = GetDistanceBetweenCoords(GetEntityCoords(closestEntity) ,GetEntityCoords(GetPlayerPed(-1)),true)                 
								if dst < 2 then
									holdingPackage = true
									if attachPropList[i].anim == 'pick' then
										randPickupAnim()
									elseif attachPropList[i].anim == 'hold' then
										holdAnim()
									end
									Citizen.Wait(550)
									NetworkRequestControlOfEntity(closestEntity)
									while not NetworkHasControlOfEntity(closestEntity) do
										Wait(0)
									end
									SetEntityAsMissionEntity(closestEntity, true, true)
									while not IsEntityAMissionEntity(closestEntity) do
										Wait(0)
									end
									SetEntityHasGravity(closestEntity, true)
									AttachEntityToEntity(closestEntity, GetPlayerPed(-1),GetPedBoneIndex(GetPlayerPed(-1), attachPropList[i].bone), attachPropList[i].x, attachPropList[i].y, attachPropList[i].z, attachPropList[i].xR, attachPropList[i].yR, attachPropList[i].zR, 1, 1, 0, true, 2, 1)
								end
							else
								holdingPackage = false
								if attachPropList[i].anim == 'pick' then
									randPickupAnim()
								end
								Citizen.Wait(350)
								DetachEntity(closestEntity)
								ClearPedTasks(GetPlayerPed(-1))
								ClearPedSecondaryTask(GetPlayerPed(-1))
							end
						end
						break
					end
				end
			end
		else
			Citizen.Wait(500)
		end
	end
end)

function removeAttachedProp()
    if DoesEntityExist(closestEntity) then
        DeleteEntity(closestEntity)
    end
end

function attach(prop)
    TriggerEvent("inrp_propsystem:attachItem",prop)
end

function removeall()
    TriggerEvent("RemoveItems",false)
	ClearPedTasks(GetPlayerPed(-1))
	ClearPedSecondaryTask(GetPlayerPed(-1))
end

RegisterNetEvent('inrp_propsystem:attachItem')
AddEventHandler('inrp_propsystem:attachItem', function(item)
	for i=1 ,#attachPropList , 1 do
		if (attachPropList[i].model == item) then
			TriggerEvent("inrp_propsystem:attachProp",attachPropList[i].model, attachPropList[i].bone, attachPropList[i].x, attachPropList[i].y, attachPropList[i].z, attachPropList[i].xR, attachPropList[i].yR, attachPropList[i].zR)
		end
	end
end)

RegisterNetEvent("RemoveItems")
AddEventHandler("RemoveItems", function(sentinfo)
    SetCurrentPedWeapon(GetPlayerPed(-1), GetHashKey("weapon_unarmed"), 1)
	removeAttachedProp()
	holdingPackage = false
end)


Citizen.CreateThread( function()
	RegisterCommand("r", function()
		removeall()
	end, false)
			
	for i=1, #attachPropList, 1 do
		RegisterCommand(attachPropList[i].name, function(source, args, raw)
			local arg = args[1]

			if arg == nil then
				attach(attachPropList[i].model)
			end
			
		end, false)
	end
	
end)


Citizen.CreateThread(function() while true do Citizen.Wait(30000) collectgarbage() end end) -- Prevents RAM LEAKS :)
