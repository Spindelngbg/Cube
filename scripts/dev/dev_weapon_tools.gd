class_name DevWeaponTools
extends RefCounted

## Dev-hjälpare för att ge och testa vapen i spelet.


static func grant_slimeshooter(show_toast: bool = true) -> bool:
	if not WeaponManager.grant_slimeshooter(true):
		return false
	if show_toast:
		QuestManager.story_toast.emit(
			"Dev — Slimeshooter",
			"Vapnet lades till i inventory och utrustades."
		)
	return true


static func remove_slimeshooter(show_toast: bool = true) -> bool:
	if not InventoryManager.has_item(WeaponManager.SLIMESHOOTER_ID):
		return false
	WeaponManager.unequip()
	InventoryManager.remove_item(WeaponManager.SLIMESHOOTER_ID)
	if show_toast:
		QuestManager.story_toast.emit(
			"Dev — Slimeshooter",
			"Vapnet togs bort från inventory."
		)
	return true