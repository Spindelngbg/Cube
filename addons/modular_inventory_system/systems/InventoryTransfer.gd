class_name InventoryTransfer
extends RefCounted

static func transfer(source: Inventory, target: Inventory, source_slot_index: int, amount: int = 0) -> int:
	if not source or not target or source_slot_index < 0:
		return 0
	
	var src_slot = source.get_slot(source_slot_index)
	if not src_slot or src_slot.is_empty():
		return 0
	
	var item = src_slot.item
	var available = min(amount, src_slot.count) if amount > 0 else src_slot.count
	if available <= 0:
		return 0
	
	var moved = 0
	var remaining = available
	
	for i in target.capacity:
		if remaining <= 0: break
		var tgt_slot = target.get_slot(i)
		if tgt_slot and tgt_slot.item == item and not tgt_slot.is_empty():
			var space = item.max_stack_size - tgt_slot.count
			if space > 0 and target.can_accept_at_slot(item, i, remaining):
				var to_add = min(space, remaining)
				tgt_slot.count += to_add
				remaining -= to_add
				moved += to_add
				target.slot_changed.emit(i)
	
	for i in target.capacity:
		if remaining <= 0:
			break
		var tgt_slot = target.get_slot(i)
		if tgt_slot and tgt_slot.is_empty() and target.can_accept_at_slot(item, i, remaining):
			var to_add = min(item.max_stack_size, remaining)
			tgt_slot.set_value(item, to_add)
			remaining -= to_add
			moved += to_add
			target.slot_changed.emit(i)
	
	if moved > 0:
		src_slot.count -= moved
		if src_slot.count <= 0:
			src_slot.clear()
		source.slot_changed.emit(source_slot_index)
		source.inventory_changed.emit()
		target.inventory_changed.emit()
	
	return moved

static func drop_to_slot(source: Inventory, target: Inventory, source_slot_index: int, target_slot_index: int, amount: int) -> bool:
	if not source or not target: return false
	
	if amount <= 0: return false
	
	var src_slot = source.get_slot(source_slot_index)
	var tgt_slot = target.get_slot(target_slot_index)
	if not src_slot or src_slot.is_empty(): return false
	
	var src_item = src_slot.item
	var tgt_item = tgt_slot.item
	var src_count = src_slot.count
	
	var is_swap = not tgt_slot.is_empty() and tgt_item != src_item
	
	if is_swap:
		if amount < src_count:
			return false

		var tgt_def = target.slot_definitions[target_slot_index] if target_slot_index < target.slot_definitions.size() else null
		if tgt_def and not tgt_def.can_accept_item(src_item, target_slot_index, target, amount):
			return false
			
		var src_def = source.slot_definitions[source_slot_index] if source_slot_index < source.slot_definitions.size() else null
		if src_def and not src_def.can_accept_item(tgt_item, source_slot_index, source, tgt_slot.count):
			return false
			
		var temp_item = tgt_slot.item
		var temp_count = tgt_slot.count
		var temp_dur = tgt_slot.current_durability
		
		tgt_slot.set_value(src_item, src_count, src_slot.current_durability)
		src_slot.set_value(temp_item, temp_count, temp_dur)
		
		_emit_changes(source, target, source_slot_index, target_slot_index)
		return true
		
	else:
		if not target.can_accept_at_slot(src_item, target_slot_index, amount):
			return false

		if tgt_slot.is_empty():
			var max_allowed = src_item.max_stack_size
			if target_slot_index < target.slot_definitions.size():
				var tgt_def = target.slot_definitions[target_slot_index]
				if tgt_def:
					max_allowed = tgt_def.get_max_allowed_amount(src_item, 0, target)
					
			var transfer_amount = mini(max_allowed, amount)
			if transfer_amount <= 0: return false
			
			var durability_to_transfer = 0
			if src_item.has_durability:
				durability_to_transfer = max(0, int(src_slot.current_durability * float(transfer_amount) / float(src_count)))
				
			tgt_slot.set_value(src_item, transfer_amount, durability_to_transfer)
			src_slot.count -= transfer_amount
			if src_item.has_durability:
				src_slot.current_durability -= durability_to_transfer
				if src_slot.current_durability < 0: src_slot.current_durability = 0
			if src_slot.count <= 0: src_slot.clear()
		elif tgt_item == src_item:
			var max_allowed = src_item.max_stack_size
			if target_slot_index < target.slot_definitions.size():
				var tgt_def = target.slot_definitions[target_slot_index]
				if tgt_def:
					max_allowed = tgt_def.get_max_allowed_amount(src_item, tgt_slot.count, target)
					
			var space = max_allowed - tgt_slot.count
			var to_add = mini(space, amount)
			if to_add > 0:
				if src_item.has_durability:
					var total_dur = (tgt_slot.current_durability * tgt_slot.count) + (src_slot.current_durability * to_add)
					var total_count = tgt_slot.count + to_add
					tgt_slot.current_durability = int(float(total_dur) / float(total_count))
				tgt_slot.count += to_add
				src_slot.count -= to_add
				if src_slot.count <= 0: src_slot.clear()
				
		_emit_changes(source, target, source_slot_index, target_slot_index)
		return true
			
	return false

static func _emit_changes(source: Inventory, target: Inventory, src_idx: int, tgt_idx: int) -> void:
	source.slot_changed.emit(src_idx)
	source.inventory_changed.emit()
	if target != source:
		target.slot_changed.emit(tgt_idx)
		target.inventory_changed.emit()

static func quick_move(source: Inventory, target: Inventory, source_slot_index: int) -> bool:
	var src_slot = source.get_slot(source_slot_index)
	if not src_slot or src_slot.is_empty():
		return false
	
	var item = src_slot.item
	var count = src_slot.count
	var moved = 0
	
	for i in target.capacity:
		if count <= 0: break
		var tgt_slot = target.get_slot(i)
		if tgt_slot and tgt_slot.item == item and not tgt_slot.is_empty():
			if target.can_accept_at_slot(item, i, count):
				var space = item.max_stack_size - tgt_slot.count
				if space > 0:
					var to_add = mini(space, count)
					if item.has_durability:
						var total_dur = (tgt_slot.current_durability * tgt_slot.count) + (src_slot.current_durability * to_add)
						var total_count = tgt_slot.count + to_add
						tgt_slot.current_durability = int(float(total_dur) / float(total_count))
					tgt_slot.count += to_add
					count -= to_add
					moved += to_add
					target.slot_changed.emit(i)
	for i in target.capacity:
		if count <= 0: break
		var tgt_slot = target.get_slot(i)
		if tgt_slot and tgt_slot.is_empty():
			if target.can_accept_at_slot(item, i, count):
				var to_add = mini(item.max_stack_size, count)
				var dur_to_transfer = 0
				if item.has_durability:
					dur_to_transfer = max(0, int(src_slot.current_durability * float(to_add) / float(src_slot.count)))
				tgt_slot.set_value(item, to_add, dur_to_transfer)
				if item.has_durability:
					src_slot.current_durability -= dur_to_transfer
				count -= to_add
				moved += to_add
				target.slot_changed.emit(i)
				
	if moved > 0:
		src_slot.count -= moved
		if src_slot.count <= 0:
			src_slot.clear()
		source.slot_changed.emit(source_slot_index)
		source.inventory_changed.emit()
		target.inventory_changed.emit()
		return true
		
	return false
