local GUI = require("GUI")

local ROWS_ON_PAGE = 7
local ITEM_NAME_WIDTH = 30
local ITEM_LABEL_WIDTH = 20
local ITEM_COUNT_WIDTH = 10
local MAX_AMOUNT_WIDTH = 15
local SWITCH_WIDTH = 16
local STEP_WIDTH = 15
local DELETE_BUTTON_WIDTH = 15
local VALID_LABEL_WIDTH = 15
local SPACING = 2

local PREV_PAGE_BUTTON_X = 1
local NEXT_PAGE_BUTTON_X = 40
local ADD_PRECRAFT_BUTTON_X = 72
local EXIT_BUTTON_X = 104

local view = {}


-- Функции интерфейса, которые необходимо реализовать и связать с моделью
view.addPrecraftButtonFunc = nil
view.exitButtonFunc = nil


local workspace = GUI.workspace()
workspace:addChild(GUI.panel(1, 1, workspace.width, workspace.height, 0x2D2D2D))
local layout = workspace:addChild(GUI.layout(1, 5, workspace.width, workspace.height, 1, 1))

-- GUI-шные формы прекрафтов
view.forms = {}

local currentPage = 1


-- Возвращает количество страниц
function getPageCount()
	return math.ceil(#view.forms / ROWS_ON_PAGE)
end


local currPageLabel = workspace:addChild(GUI.label(30, 1, 10, 3, 0xFFFFFF, ""))
currPageLabel:setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_CENTER)


function showPage(page)
	-- Прячем строки с предыдущей страницы
	local hide_begin_index = (currentPage-1) * ROWS_ON_PAGE + 1
	local hide_end_index = math.min(currentPage * ROWS_ON_PAGE, #view.forms)
	for i = hide_begin_index, hide_end_index, 1 do
		view.forms[i].hidden = true
	end

	local begin_index = (page-1) * ROWS_ON_PAGE + 1
	local end_index = math.min(page * ROWS_ON_PAGE, #view.forms)
	for i = begin_index, end_index, 1 do
		view.forms[i].hidden = false
	end
	currentPage = page
	currPageLabel.text = tostring(page)
end


function isRowOnCurrentPage(rowIndex)
	local begin_index = (currentPage-1) * ROWS_ON_PAGE + 1
	local end_index = currentPage * ROWS_ON_PAGE
	return rowIndex >= begin_index and rowIndex <= end_index
end


-- Добавляет заполненную форму для прекрафта в конец последней страницы
function view.addPrecraftRow()
	local rowForm = {}  -- Таблица, содержащая указатели на все нужные виджеты формы

	rowForm.rowLayout = layout:setPosition(1, 1, layout:addChild(GUI.layout(1, 1, layout.width, 3, 8, 1)))
	table.insert(view.forms, rowForm.rowLayout)

	-- Устанавливаем ширины столбцов
	rowForm.rowLayout:setColumnWidth(1, GUI.SIZE_POLICY_ABSOLUTE, ITEM_NAME_WIDTH + SPACING)
	rowForm.rowLayout:setColumnWidth(2, GUI.SIZE_POLICY_ABSOLUTE, ITEM_LABEL_WIDTH + SPACING)
	rowForm.rowLayout:setColumnWidth(3, GUI.SIZE_POLICY_ABSOLUTE, ITEM_COUNT_WIDTH + SPACING)
	rowForm.rowLayout:setColumnWidth(4, GUI.SIZE_POLICY_ABSOLUTE, MAX_AMOUNT_WIDTH + SPACING)
	rowForm.rowLayout:setColumnWidth(5, GUI.SIZE_POLICY_ABSOLUTE, SWITCH_WIDTH + SPACING)
	rowForm.rowLayout:setColumnWidth(6, GUI.SIZE_POLICY_ABSOLUTE, STEP_WIDTH + SPACING)
	rowForm.rowLayout:setColumnWidth(7, GUI.SIZE_POLICY_ABSOLUTE, DELETE_BUTTON_WIDTH + SPACING)
	rowForm.rowLayout:setColumnWidth(8, GUI.SIZE_POLICY_ABSOLUTE, VALID_LABEL_WIDTH + SPACING)

	-- Прячем строку, если она добавляется не на текущую страницу
	local rowIndex = #view.forms
	if not isRowOnCurrentPage(rowIndex) then
		rowForm.rowLayout.hidden = true
	end

	-- Создаём виджеты формы прекрафта
	rowForm.itemInput = rowForm.rowLayout:setPosition(1, 1, rowForm.rowLayout:addChild(GUI.input(1, 1, ITEM_NAME_WIDTH, 3, 0xEEEEEE, 0x555555, 0x999999, 0xFFFFFF, 0x2D2D2D, "", "Имя предмета")))
	rowForm.itemLabelsBox = rowForm.rowLayout:setPosition(2, 1, rowForm.rowLayout:addChild(GUI.comboBox(1, 1, ITEM_LABEL_WIDTH, 3, 0xEEEEEE, 0x2D2D2D, 0xCCCCCC, 0x888888)))
	rowForm.itemCount = rowForm.rowLayout:setPosition(3, 1, rowForm.rowLayout:addChild(GUI.text(1, 1, 0xFFFFFF, "")))
	rowForm.amountInput = rowForm.rowLayout:setPosition(4, 1, rowForm.rowLayout:addChild(GUI.input(1, 1, MAX_AMOUNT_WIDTH, 3, 0xEEEEEE, 0x555555, 0x999999, 0xFFFFFF, 0x2D2D2D, "", "Макс. количество")))
	rowForm.isMatterSwitch = rowForm.rowLayout:setPosition(5, 1, rowForm.rowLayout:addChild(GUI.switchAndLabel(1, 1, SWITCH_WIDTH, 4, 0x66DB80, 0x1D1D1D, 0xEEEEEE, 0x999999, "Из материи?", false)))
	rowForm.stepInput = rowForm.rowLayout:setPosition(6, 1, rowForm.rowLayout:addChild(GUI.input(1, 1, STEP_WIDTH, 3, 0xEEEEEE, 0x555555, 0x999999, 0xFFFFFF, 0x2D2D2D, "", "Шаг")))
	rowForm.redstoneAddressBox = rowForm.rowLayout:setPosition(6, 1, rowForm.rowLayout:addChild(GUI.comboBox(1, 1, STEP_WIDTH, 3, 0xEEEEEE, 0x2D2D2D, 0xCCCCCC, 0x888888)))
	rowForm.removeButton = rowForm.rowLayout:setPosition(7, 1, rowForm.rowLayout:addChild(GUI.button(1, 1, DELETE_BUTTON_WIDTH, 3, 0xFFFFFF, 0x555555, 0x880000, 0xFFFFFF, "Удалить")))
	rowForm.isValidLabel = rowForm.rowLayout:setPosition(8, 1, rowForm.rowLayout:addChild(GUI.text(1, 1, 0xFFFFFF, "Not Valid")))

	return rowForm
end


-- Кнопки верхнего меню ------------------

local prevButton = workspace:addChild(GUI.button(PREV_PAGE_BUTTON_X, 1, 30, 3, 0xFFFFFF, 0x555555, 0x880000, 0xFFFFFF, "Предыдущая страница"))
prevButton.onTouch = function()
	if currentPage - 1 <= 0 then
		showPage(1)
	else
		showPage(currentPage - 1)
	end
end

local nextButton = workspace:addChild(GUI.button(NEXT_PAGE_BUTTON_X, 1, 30, 3, 0xFFFFFF, 0x555555, 0x880000, 0xFFFFFF, "Следующая страница"))
nextButton.onTouch = function()
	local pageCount = getPageCount() 
	if pageCount == 0 then
		showPage(1)
	elseif currentPage + 1 > pageCount then
		showPage(pageCount)
	else
		showPage(currentPage + 1)
	end
end

local addPrecraftButton = workspace:addChild(GUI.button(ADD_PRECRAFT_BUTTON_X, 1, 30, 3, 0xFFFFFF, 0x555555, 0x880000, 0xFFFFFF, "Добавить прекрафт"))
addPrecraftButton.onTouch = function() view.addPrecraftButtonFunc() end

local exitButton = workspace:addChild(GUI.button(EXIT_BUTTON_X, 1, 30, 3, 0xFFFFFF, 0x555555, 0x880000, 0xFFFFFF, "Выйти"))
exitButton.onTouch = function() view.exitButtonFunc() end


function view.start()
	showPage(1)
	workspace:draw()
	workspace:start()
end

function view.exit()
	view.forms = {}
	workspace:stop()
end


return view