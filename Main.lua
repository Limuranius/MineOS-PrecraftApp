local view = require("/Precraft/PrecraftView.lua")
local model = require("/Precraft/PrecraftModel.lua")


function addPrecraft(precraftData)
	local rowForm = view.addPrecraftRow()
	model.addLogicToRow(rowForm, precraftData)
end


function addEmptyPrecraft()
	addPrecraft({
		name="", 
		label="Предмет не найден", 
		maxAmount="",
		isMatter=false,
		step="",
		redstoneAddress=""})
end


function loadPrecrafts()
	local loaded_json = model.loadPrecraftsJSON()
	for i = 1, #loaded_json, 1 do
		local precraft = loaded_json[i]
		addPrecraft(precraft)
	end
end


view.addPrecraftButtonFunc = function()
	addEmptyPrecraft()
	model.savePrecraftsToJSON()
end

local exit = nil  -- Заранее определяем функцию exit()
view.exitButtonFunc = function()
	exit()
end

-------------------------------------------------------------------

function main()
	model.precrafts = {}
	view.forms = {}
	loadPrecrafts()
	model.startMonitoring()
	view.start()
end

function exit()
	model.stopMonitoring()
	view.exit()
end

main()