local ME = component.me_controller
local event = require("Event")
local GUI = require("GUI")
local utils = require("/Precraft/utils.lua")


local TIME_INTERVAL = 10  


local CraftManager = {}

-- itemName: craftStatus. Содержит работающие крафты для предметов
local runningCrafts = {}


-- Проверяет правильность данных
function CraftManager.isPrecraftValid(precraft)
	local check1 = utils.itemExist(precraft.name, precraft.label)  -- Предмет существует
	local check2 = tonumber(precraft.maxAmount)  -- maxAmount - число
	-- Либо делается из материи, либо по заказу и кол-во за заказ указано числом
	local check3 = precraft.isMatter or (not precraft.isMatter and tonumber(precraft.step))
	-- Либо делается из материи, либо по заказу и для предмета существует заказ 
	local check4 = precraft.isMatter or (not precraft.isMatter and utils.itemCraftable(precraft.name, precraft.label))
	return check1 and check2 and check3 and check4
end


-- Включает либо выключает подачу материи по определённому адресу
function CraftManager.switchMatterStatus(precraft, isOn)
	local redstoneController = component.proxy(precraft.redstoneAddress)
	if isOn then
		redstoneController.setOutput(1, 1)
	else
		redstoneController.setOutput(1, 0)
	end
end


function CraftManager.turnOffUnusedRedstoneControllers(precrafts)
	local usedAddresses = {}
	for i, precraft in ipairs(precrafts) do
		if precraft.isMatter then
			usedAddresses[precraft.redstoneAddress] = true
		end
	end
	for i, address in ipairs(utils.getRedstoneAddresses()) do
		local redstoneController = component.proxy(address)
		-- Проверяем текущий выход сверху (лучше лишний раз не вызывать set метод, так как он дорогой)
		local currSignal = redstoneController.getOutput(1)   
		if currSignal > 0 and not usedAddresses[address] then
			component.proxy(address).setOutput(1, 0)
		end
	end
end


function CraftManager.turnOffAllRedstoneControllers()
	for i, address in ipairs(utils.getRedstoneAddresses()) do
		local redstoneController = component.proxy(address)
		-- Проверяем текущий выход сверху (лучше лишний раз не вызывать set метод, так как он дорогой)
		local currSignal = redstoneController.getOutput(1)   
		if currSignal > 0 then
			component.proxy(address).setOutput(1, 0)
		end
	end
end



-- Возвращает уникальный ключ прекрафта (слепленное название и метка)
function getKey(precraft)
	return precraft.name..precraft.label
end


-- Возвращает true, если крафт всё ещё находится в процессе
function CraftManager.craftIsRunning(craftStatus)
	return not craftStatus.isCanceled() and not craftStatus.isDone() 
end


-- Создаёт запрос на крафт
function CraftManager.createCraftQuery(precraft)
	local craft = ME.getCraftables({name=precraft.name, label=precraft.label})
	local craftStatus = craft[1].request(tonumber(precraft.step))
	runningCrafts[getKey(precraft)] = craftStatus
end


-- Проверяет предмет и делает его прекрафт, если это необходимо
function CraftManager.checkPrecraft(precraft)
	if not CraftManager.isPrecraftValid(precraft) then
		return
	end

	local itemCount = utils.getItemCount(precraft.name, precraft.label)

	-- Проверяем, нужно ли крафтить
	if itemCount < tonumber(precraft.maxAmount) then
		if precraft.isMatter then  -- Если предметы делаются из материи
			CraftManager.switchMatterStatus(precraft, true)  -- Включаем подачу материи
		else  -- Если предметы делаются заказами
			-- Если крафт уже был запрошен и ещё не завершился
			if runningCrafts[getKey(precraft)] and CraftManager.craftIsRunning(runningCrafts[getKey(precraft)]) then
				return
			else  -- Крафт завершился, либо ещё не был запрошен
				CraftManager.createCraftQuery(precraft)
			end
		end
	else  -- Предметов достаточно
		-- Выключаем подачу материи в репликаторы, если предмет делается из материи
		if precraft.isMatter then
			CraftManager.switchMatterStatus(precraft, false)
		end
	end
end


local monitorHandler = nil  -- Переменная, в которую будет помещён указатель на процесс


-- Запускает на фоне мониторинг за прекрафтами
function CraftManager.startMonitoring(precrafts)
	local checkAllOnceFunc = function()
		-- print("checkAllOnceFunc")
		CraftManager.turnOffUnusedRedstoneControllers(precrafts)  -- Выключаем все случайно включенные редстоуны
		for i, v in ipairs(precrafts) do
			CraftManager.checkPrecraft(v)
		end
	end
	monitorHandler = event.addHandler(checkAllOnceFunc, TIME_INTERVAL)
end


function CraftManager.stopMonitoring()
	event.removeHandler(monitorHandler)
	CraftManager.turnOffAllRedstoneControllers()
end


return CraftManager
