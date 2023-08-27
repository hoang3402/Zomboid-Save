local EasyLiterature = EasyLiterature

EasyLiterature.ISInventoryTransferAction_perform =
	EasyLiterature.ISInventoryTransferAction_perform or ISInventoryTransferAction.perform
local ISInventoryTransferAction_perform = EasyLiterature.ISInventoryTransferAction_perform

function ISInventoryTransferAction:perform()

	if #self.queueList == 0 then

		ISInventoryTransferAction_perform(self)

		return

	end

	local queue_items = self.queueList[1].items

	ISInventoryTransferAction_perform(self)

	if not EasyLiterature:GetSettingsValue("AutoMarkTransferedLiterature") then
		return
	end
	
	if self.hasBeenCancelled then
		return
	end

	for i = 1, #queue_items do
	
		EasyLiterature:PostItemTransfer(
			self.character,
			queue_items[i],
			self.srcContainer,
			self.destContainer
		)

	end

end

function EasyLiterature:PostItemTransfer(character, item, source_containter, destination_inventory)

	local literature_type = self:GetLiteratureItemType(item)

	if not literature_type then
		return
	end

	local item_id = self:GetLiteratureItemID(item, literature_type)

	if self.ModData.Data[item_id] then
		return
	end

	self.ModData.Data[item_id] = true

end