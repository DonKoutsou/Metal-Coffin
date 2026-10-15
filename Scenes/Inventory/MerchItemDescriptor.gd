extends ItemDescriptor

class_name MerchItemDescriptor

func SetMerchData(Itm : Item, Ships : Array[MapShip], ShowDesc : bool = false) -> void:
	for g in CardPlecement.get_children():
		g.queue_free()
	
	#set_physics_process(false)
	DescribedItem = Itm
	#ItemIcon.texture = It.ItemIcon
	#ItemDesc.text = Itm.GetItemDesc()
	
	var col = ColorManager.GetCurrentColor().to_html()
	ItemDesc.text = Itm.GetItemDesc().replace("#ffc315", "{0}".format([col]))
	#TransferButton.visible = It.CanTransfer
	TransferButton.visible = false
	if (!ShowDesc):
		
		ItemDesc.text = GetMerchItemDesc(Ships, Itm).replace("#ffc315", "{0}".format([col]))
	else:
		ItemDesc.text = Itm.GetWorkshopItemDesc().replace("#ffc315", "{0}".format([col]))
	ItemName.text = Itm.GetItemName().replace("#ffc315", "{0}".format([col]))
	#Ship Parts
	#if (Itm is ShipPart):
	ItemDesc.visible = true
	UpgradeButton.visible = false
	CancelUpgradeButton.visible = false
	UpgradeLabel.visible = false
		#UpgradeLabel.visible = true
	#else: if (Itm is AmmoItem):
		#UpgradeButton.visible = false
		#UpgradeLabel.visible = false
		#
	#else: if (Itm is MissileItem):
		#UpgradeButton.visible = false
		#UpgradeLabel.visible = false
		#ItemDesc.text = Itm.GetMerchItemDesc(Ships)
	#else :
		#
		#UpgradeButton.visible = false
		#UpgradeLabel.visible = false

	if (Itm.CardProviding.size() > 0):
		var CardsChecked : Array[CardStats]
		for g in Itm.CardProviding:
			if (CardsChecked.has(g)):
				continue
			CardsChecked.append(g)
			
			var CardS = g.duplicate() as CardStats
			CardS.Tier = Itm.Tier
			var card = CardScene.instantiate() as Card

			card.SetCardStats(CardS, Itm.CardProviding.count(g))
			CardPlecement.add_child(card)
			card.Dissable()
		CardSection.visible = true
	else:
		CardSection.visible = false

func GetMerchItemDesc(Ships : Array[MapShip], it : Item) -> String:
	var requirement : CardStats.WeaponType  = CardStats.WeaponType.NONE
	var requirementText : String = ""
	if (it is AmmoItem):
		requirement = it.WType
		requirementText = CardStats.WeaponType.keys()[it.WType]
		
	else: if (it is MissileItem):
		requirement = CardStats.WeaponType.ML
		requirementText = "MISSILE POD"
	else:
		return ""
		
	var UsableOn : Array[MapShip]
	for g in Ships:
		if (g.Cpt.GetCharacterInventory().HasWeapon(requirement)):
			UsableOn.append(g)
	
	var UsableOnText = "CAN BE USED BY : [color=#ffc315]"
	
	for g in UsableOn.size():
		UsableOnText += UsableOn[g].Cpt.GetCaptainName()
		if (g < UsableOn.size() - 1):
			UsableOnText += ", "
			
	UsableOnText += "[/color]\n"
		
	var Desc = "[color=#ffc315]REQUIRES {0}[/color]\n{2}".format([requirementText ,ItemDesc, UsableOnText])
	return Desc
