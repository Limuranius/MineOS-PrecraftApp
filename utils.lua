local ME = component.me_controller


local utils = {}


function utils.getRedstoneAddresses()
	local result = {}
	for k, v in component.list("redstone") do
		table.insert(result, k)
	end
	return result
end

function utils.getIndexOfRedstoneAddress(address)
	for i, v in ipairs(utils.getRedstoneAddresses()) do
		if v == address then
			return i
		end
	end
	return 1
end


function utils.itemExist(item_name)
	local item = ME.getItemsInNetwork({name=item_name})
	return item.n ~= 0
end


function utils.itemCraftable(item_name)
	local item = ME.getItemsInNetwork({name=item_name})
	if item.n == 0 then
		return false
	end
	return item[1].isCraftable
end


function utils.getItemCount(item_name)
	local item = ME.getItemsInNetwork({name=item_name})
	if item.n == 0 then
		return 0
	else
		return item[1].size
	end
end

function utils.getItemLabel(item_name)
 	local item = ME.getItemsInNetwork({name=item_name})
	if item.n == 0 then
		return "Предмет не найден"
	else
		return item[1].label
	end
end

return utils