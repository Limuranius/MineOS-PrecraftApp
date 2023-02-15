local json = require("JSON")
local filesystem = require("Filesystem")
local CM = require("/Precraft/CraftManager.lua")
local utils = require("/Precraft/utils.lua")

JSON_PATH = "/Precraft/precrafts.json"


local model = {}


-- Данные о прекрафтах
model.precrafts = {}


-- Загружает JSON файл с прекрафтами
function model.loadPrecraftsJSON()
	return json.decode(filesystem.read(JSON_PATH))
end

-- Сохраняет все данные о страницах в JSON файл
function model.savePrecraftsToJSON()
	filesystem.write(JSON_PATH, json.encode(model.precrafts))
end


function model.addLogicToRow(rowForm, precraft)
	table.insert(model.precrafts, {
		name=precraft.name,
		label=precraft.label,
		maxAmount=precraft.maxAmount,
		isMatter=precraft.isMatter,
		step=precraft.step,
		redstoneAddress=precraft.redstoneAddress
	})
	local rowData = model.precrafts[#model.precrafts]  -- Указатель на данные этой строки

	rowForm.itemInput.text = precraft.name
	rowForm.amountInput.text = precraft.maxAmount
	rowForm.isMatterSwitch.switch.state = precraft.isMatter
	rowForm.stepInput.text = precraft.step

	-- Прячем виджеты шаг/адрес, в зависимости от использования материи
	if precraft.isMatter then
		rowForm.stepInput.hidden = true
		rowForm.redstoneAddressBox.hidden = false
	else
		rowForm.stepInput.hidden = false
		rowForm.redstoneAddressBox.hidden = true
	end

	local updateRow = nil  -- Предопределяем функцию updateRow

	-- Находит все метки, подходящие под название файла и засовывает их в комбобокс
	local setItemLabels = function()
		rowForm.itemLabelsBox:clear()
		local labels = utils.getItemLabels(rowForm.itemInput.text)
		for i, label in ipairs(labels) do
			rowForm.itemLabelsBox:addItem(label).onTouch = function()
				rowData.label = label
				updateRow()
			end
		end
		-- Устанавливаем запомненный выбор метки
		local chosenIndex = utils.indexOfItem(labels, rowData.label)
		if not chosenIndex then  -- Если сохранённый лейбл не найден
			chosenIndex = 1
		end
		rowForm.itemLabelsBox.selectedItem = chosenIndex
	end

	-- Проверяет правильность введённых данных и выводит результат
	local validate = function()
		if CM.isPrecraftValid(rowData) then
			rowForm.isValidLabel.text = "Valid"
		else
			rowForm.isValidLabel.text = "Not valid"
		end
	end

	-- Сохраняет данные строки в общий JSON файл. Вызывается каждый раз при изменении строки
	local saveRowToJSON = function()
		rowData.name = rowForm.itemInput.text

		local labelItem = rowForm.itemLabelsBox:getItem(rowForm.itemLabelsBox.selectedItem)
		if labelItem then
			rowData.label = labelItem.text
		else
			rowData.label = "Предмет не найден"
		end

		rowData.maxAmount = rowForm.amountInput.text
		rowData.isMatter = rowForm.isMatterSwitch.switch.state
		rowData.step = rowForm.stepInput.text
		rowData.redstoneAddress = rowForm.redstoneAddressBox:getItem(rowForm.redstoneAddressBox.selectedItem).text
		model.savePrecraftsToJSON()
	end

	-- Обновляет и сохраняет состояние строки
	updateRow = function()
		setItemLabels()
		saveRowToJSON()
		validate()
	end

	-- Заполнение поля "Имя предмета"
	rowForm.itemInput.onInputFinished = function()
		updateRow()
	end

	-- Заполнение поля "Макс. количество"
	rowForm.amountInput.onInputFinished = function()
		updateRow()
	end

	-- Переключение "Материи"
	rowForm.isMatterSwitch.switch.onStateChanged = function()
		rowForm.stepInput.hidden = rowForm.isMatterSwitch.switch.state
		rowForm.redstoneAddressBox.hidden = not rowForm.isMatterSwitch.switch.state
		updateRow()
	end

	-- Заполнение поля "Шаг"
	rowForm.stepInput.onInputFinished = function()
		updateRow()
	end

	-- Заполение адресов контроллеров красного камня
	for i, address in ipairs(utils.getRedstoneAddresses()) do
		rowForm.redstoneAddressBox:addItem(address).onTouch = function()
			updateRow()
		end
	end
	-- Устанавливаем выбранный ранее адрес
	local chosenAddressIndex = utils.indexOfItem(utils.getRedstoneAddresses(), precraft.redstoneAddress)
	if not chosenAddressIndex then
		rowForm.redstoneAddressBox.selectedItem = 1
	else
		rowForm.redstoneAddressBox.selectedItem = chosenAddressIndex
	end

	-- Нажатие кнопки "Удалить"
	rowForm.removeButton.onTouch = function()
		rowForm.rowLayout:remove()
		local rowIndex = utils.indexOfItem(model.precrafts, rowData)
		table.remove(model.precrafts, rowIndex)
		model.savePrecraftsToJSON()
	end

	updateRow()
end


function model.startMonitoring()
	CM.startMonitoring(model.precrafts)
end

function model.stopMonitoring()
	CM.stopMonitoring()
end


return model