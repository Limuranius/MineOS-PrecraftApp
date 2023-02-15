local DIR = "/Precraft"

local GUI = require("GUI")
local ME = component.me_controller
local json = require("JSON")
local filesystem = require("Filesystem")
local CM = require(DIR.."/CraftManager.lua")
local utils = require(DIR.."/utils.lua")
local event = require("Event")

local ROWS_ON_PAGE = 5
local ITEM_NAME_WIDTH = 30
local ITEM_LABEL_WIDTH = 20
local ITEM_COUNT_WIDTH = 10
local MAX_AMOUNT_WIDTH = 15
local SWITCH_WIDTH = 16
local STEP_WIDTH = 15
local DELETE_BUTTON_WIDTH = 15
local VALID_LABEL_WIDTH = 15
local SPACING = 2

------------------------------------------------------------------------------------------

local workspace = GUI.workspace()
workspace:addChild(GUI.panel(1, 1, workspace.width, workspace.height, 0x2D2D2D))
local layout = workspace:addChild(GUI.layout(1, 5, workspace.width, workspace.height, 1, 1))

-- Данные о прекрафтах
local precrafts = {}

-- GUI-шные формы прекрафтов
local forms = {}

-- Все процессы, работающие на фоне
local handlers = {}

-- Загружает JSON файл с прекрафтами
function loadPrecraftsJSON()
	return json.decode(filesystem.read(DIR.."/PrecraftStructure.json"))
end

-- Сохраняет все данные о страницах в JSON файл
function savePrecraftsToJSON()
	filesystem.write(DIR.."/PrecraftStructure.json", json.encode(precrafts))
end

-- Возвращает количество страниц
function getPageCount()
	return math.ceil(#precrafts / ROWS_ON_PAGE)
end

-- Возвращает количество строк
function getRowCount()
	return #precrafts
end

local currentPage = 1
function showPage(page)
	-- Прячем строки с предыдущей страницы
	local hide_begin_index = (currentPage-1) * ROWS_ON_PAGE + 1
	local hide_end_index = math.min(currentPage * ROWS_ON_PAGE, #forms)
	for i = hide_begin_index, hide_end_index, 1 do
		forms[i].hidden = true
	end

	local begin_index = (page-1) * ROWS_ON_PAGE + 1
	local end_index = math.min(page * ROWS_ON_PAGE, #forms)
	for i = begin_index, end_index, 1 do
		forms[i].hidden = false
	end
	currentPage = page
end

function isRowOnCurrentPage(row)
	local begin_index = (currentPage-1) * ROWS_ON_PAGE + 1
	local end_index = currentPage * ROWS_ON_PAGE
	return row >= begin_index and row <= end_index
end


-- Добавляет заполненную форму для прекрафта в конец последней страницы
function addPrecraftRow(precraft)
	table.insert(precrafts, {
		name=precraft.name,
		label=precraft.label,
		maxAmount=precraft.maxAmount,
		isMatter=precraft.isMatter,
		step=precraft.step,
		redstoneAddress=precraft.redstoneAddress
	})
	local row_index = getRowCount()
	local row_layout = layout:setPosition(1, 1, layout:addChild(GUI.layout(1, 1, layout.width, 3, 8, 1)))

	-- Устанавливаем ширины столбцов
	row_layout:setColumnWidth(1, GUI.SIZE_POLICY_ABSOLUTE, ITEM_NAME_WIDTH + SPACING)
	row_layout:setColumnWidth(2, GUI.SIZE_POLICY_ABSOLUTE, ITEM_LABEL_WIDTH + SPACING)
	row_layout:setColumnWidth(3, GUI.SIZE_POLICY_ABSOLUTE, ITEM_COUNT_WIDTH + SPACING)
	row_layout:setColumnWidth(4, GUI.SIZE_POLICY_ABSOLUTE, MAX_AMOUNT_WIDTH + SPACING)
	row_layout:setColumnWidth(5, GUI.SIZE_POLICY_ABSOLUTE, SWITCH_WIDTH + SPACING)
	row_layout:setColumnWidth(6, GUI.SIZE_POLICY_ABSOLUTE, STEP_WIDTH + SPACING)
	row_layout:setColumnWidth(7, GUI.SIZE_POLICY_ABSOLUTE, DELETE_BUTTON_WIDTH + SPACING)
	row_layout:setColumnWidth(8, GUI.SIZE_POLICY_ABSOLUTE, VALID_LABEL_WIDTH + SPACING)

	-- Прячем строку, если она добавляется не на текущую страницу
	if not isRowOnCurrentPage(row_index) then
		row_layout.hidden = true
	end

	table.insert(forms, row_layout)

	-- Создаём виджеты формы прекрафта
	local itemInput = row_layout:setPosition(1, 1, row_layout:addChild(GUI.input(1, 1, ITEM_NAME_WIDTH, 3, 0xEEEEEE, 0x555555, 0x999999, 0xFFFFFF, 0x2D2D2D, precraft.name, "Имя предмета")))
	local itemLabelsBox = row_layout:setPosition(2, 1, row_layout:addChild(GUI.comboBox(1, 1, ITEM_LABEL_WIDTH, 3, 0xEEEEEE, 0x2D2D2D, 0xCCCCCC, 0x888888)))
	local itemCount = row_layout:setPosition(3, 1, row_layout:addChild(GUI.text(1, 1, 0xFFFFFF, "")))
	local amountInput = row_layout:setPosition(4, 1, row_layout:addChild(GUI.input(1, 1, MAX_AMOUNT_WIDTH, 3, 0xEEEEEE, 0x555555, 0x999999, 0xFFFFFF, 0x2D2D2D, precraft.maxAmount, "Макс. количество")))
	local isMatterSwitch = row_layout:setPosition(5, 1, row_layout:addChild(GUI.switchAndLabel(1, 1, SWITCH_WIDTH, 4, 0x66DB80, 0x1D1D1D, 0xEEEEEE, 0x999999, "Из материи?", precraft.isMatter)))
	
	local stepInput = row_layout:setPosition(6, 1, row_layout:addChild(GUI.input(1, 1, STEP_WIDTH, 3, 0xEEEEEE, 0x555555, 0x999999, 0xFFFFFF, 0x2D2D2D, precraft.step, "Шаг")))
	local redstoneAddressBox = row_layout:setPosition(6, 1, row_layout:addChild(GUI.comboBox(1, 1, STEP_WIDTH, 3, 0xEEEEEE, 0x2D2D2D, 0xCCCCCC, 0x888888)))
	
	local removeButton = row_layout:setPosition(7, 1, row_layout:addChild(GUI.button(1, 1, DELETE_BUTTON_WIDTH, 3, 0xFFFFFF, 0x555555, 0x880000, 0xFFFFFF, "Удалить")))
	local isValidLabel = row_layout:setPosition(8, 1, row_layout:addChild(GUI.text(1, 1, 0xFFFFFF, "")))
	
	-- Прячем виджеты, в зависимости от использования материи
	if precraft.isMatter then
		stepInput.hidden = true
		redstoneAddressBox.hidden = false
	else
		stepInput.hidden = false
		redstoneAddressBox.hidden = true
	end

	-- Находит все метки, подходящие под название файла и засовывает их в комбобокс
	local updateRow = nil
	local setItemLabels = function()
		itemLabelsBox:clear()
		local labels = utils.getItemLabels(itemInput.text)
		for i, label in ipairs(labels) do
			itemLabelsBox:addItem(label).onTouch = function()
				precrafts[row_index].label = label
				updateRow()
			end
		end
		local chosenIndex = utils.indexOfItem(labels, precrafts[row_index].label)
		if not chosenIndex then  -- Если сохранённый лейбл не найден
			chosenIndex = 1
		end
		itemLabelsBox.selectedItem = chosenIndex
	end

	-- Проверяет правильность введённых данных и выводит результат
	local validate = function()
		if CM.isPrecraftValid(precrafts[row_index]) then
			isValidLabel.text = "Valid"
		else
			isValidLabel.text = "Not valid"
		end
	end

	-- Сохраняет данные строки в общий JSON файл. Вызывается каждый раз при изменении строки
	local saveRowToJSON = function()
		precrafts[row_index].name = itemInput.text

		local labelItem = itemLabelsBox:getItem(itemLabelsBox.selectedItem)
		if labelItem then
			precrafts[row_index].label = labelItem.text
		else
			precrafts[row_index].label = "Предмет не найден"
		end

		precrafts[row_index].maxAmount = tonumber(amountInput.text)
		precrafts[row_index].isMatter = isMatterSwitch.switch.state
		precrafts[row_index].step = tonumber(stepInput.text)
		precrafts[row_index].redstoneAddress = redstoneAddressBox:getItem(redstoneAddressBox.selectedItem).text
		savePrecraftsToJSON()
	end

	-- Обновляет и сохраняет состояние строки
	updateRow = function()
		setItemLabels()
		saveRowToJSON()
		validate()
	end

	-- Заполнение поля "Имя предмета"
	itemInput.onInputFinished = function()
		updateRow()
	end

	-- Заполнение поля "Макс. количество"
	amountInput.onInputFinished = function()
		updateRow()
	end

	-- Переключение "Материи"
	isMatterSwitch.switch.onStateChanged = function()
		stepInput.hidden = isMatterSwitch.switch.state
		redstoneAddressBox.hidden = not isMatterSwitch.switch.state
		updateRow()
	end

	-- Заполнение поля "Шаг"
	stepInput.onInputFinished = function()
		updateRow()
	end

	-- Заполение адресов контроллеров красного камня
	for i, address in ipairs(utils.getRedstoneAddresses()) do
		redstoneAddressBox:addItem(address).onTouch = function()
			updateRow()
		end
	end
	-- Устанавливаем выбранный адрес
	local chosenAddressIndex = utils.indexOfItem(utils.getRedstoneAddresses(), precraft.redstoneAddress)
	if not chosenAddressIndex then
		redstoneAddressBox.selectedItem = 1
	else
		redstoneAddressBox.selectedItem = chosenAddressIndex
	end

	-- Нажатие кнопки "Удалить"
	removeButton.onTouch = function()
		row_layout:remove()
		table.remove(precrafts, row_index)
		savePrecraftsToJSON()
	end

	updateRow()
end

function addPrecraftEmptyRow()
	addPrecraftRow({
		name="", 
		label="Предмет не найден", 
		maxAmount=nil,
		isMatter=false,
		step=nil,
		redstoneAddress=nil})
end

function PrecraftsJSONtoForms()
	local loaded_json = loadPrecraftsJSON()
	for i = 1, #loaded_json, 1 do
		local precraft = loaded_json[i]
		addPrecraftRow(precraft)
	end
end

local prevButton = workspace:addChild(GUI.button(1, 1, 30, 3, 0xFFFFFF, 0x555555, 0x880000, 0xFFFFFF, "Предыдущая страница"))
prevButton.onTouch = function()
	showPage(currentPage - 1)
end

local nextButton = workspace:addChild(GUI.button(32, 1, 30, 3, 0xFFFFFF, 0x555555, 0x880000, 0xFFFFFF, "Следующая страница"))
nextButton.onTouch = function()
	showPage(currentPage + 1)
end

local addPrecraftButton = workspace:addChild(GUI.button(64, 1, 30, 3, 0xFFFFFF, 0x555555, 0x880000, 0xFFFFFF, "Добавить прекрафт"))
addPrecraftButton.onTouch = function()
	addPrecraftEmptyRow()
	savePrecraftsToJSON()
end

local exitButton = workspace:addChild(GUI.button(96, 1, 30, 3, 0xFFFFFF, 0x555555, 0x880000, 0xFFFFFF, "Выйти"))
exitButton.onTouch = function()
	exit()
end


------------------------------------------------------------------------------------------

function exit()
	CM.stopMonitoring()
	for i, v in ipairs(handlers) do
		event.removeHandler(v)
	end
	workspace:stop()
end

function main()
	PrecraftsJSONtoForms()
	CM.startMonitoring(precrafts)

	showPage(currentPage)
	workspace:draw()
	workspace:start()
end

main()
