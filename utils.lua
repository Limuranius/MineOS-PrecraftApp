local ME = component.me_controller


local utils = {}


function utils.getRedstoneAddresses()
	local result = {}
	for k, v in component.list("redstone") do
		table.insert(result, k)
	end
	return result
end


-- Возвращает индекс элемента в массиве или nil, если его в массиве нет
function utils.indexOfItem(arr, target)
	for i, v in ipairs(arr) do
		if v == target then
			return i
		end
	end
	return nil
end


function utils.itemExist(name, label)
	local item = ME.getItemsInNetwork({name=name, label=label})
	return item.n ~= 0
end


function utils.itemCraftable(name, label)
	local item = ME.getItemsInNetwork({name=name, label=label})
	if item.n == 0 then
		return false
	end
	return item[1].isCraftable
end


function utils.getItemCount(name, label)
	local item = ME.getItemsInNetwork({name=name, label=label})
	if item.n == 0 then
		return 0
	else
		return item[1].size
	end
end


function utils.getItemLabels(item_name)
 	local items = ME.getItemsInNetwork({name=item_name})
 	local labels = {}
	for i, item in ipairs(items) do
		table.insert(labels, item.label)
	end
	return labels
end


return utils