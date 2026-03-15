extends Control

var mainPrices := [3, 5, 8]
var replenishPrices := [1, 2, 2, 3, 3]

func getCost(prices: Array, count: int) -> int:
	if count >= prices.size():
		return -1  # -1 means maxed out
	return prices[count]

func _ready():
	shopPricingUpdateText()
	whatCanBuy()

func _on_damage_upgrade_pressed() -> void:
	var cost = getCost(mainPrices, Globals.damageUpgradeCount)
	if cost > 0 and Globals.minerals >= cost:
		Globals.minerals -= cost
		Globals.attackDamage += 1
		Globals.damageUpgradeCount += 1
		$purchase.play()
		shopPricingUpdateText()
		whatCanBuy()
		mainHUD.setMinerals(Globals.minerals);

func _on_health_upgrade_pressed() -> void:
	var cost = getCost(mainPrices, Globals.armorUpgradeCount)
	if cost > 0 and Globals.minerals >= cost:
		Globals.minerals -= cost
		Globals.damageReduction -= 0.3
		Globals.armorUpgradeCount += 1
		$purchase.play()
		shopPricingUpdateText()
		whatCanBuy()
		mainHUD.setMinerals(Globals.minerals);

func _on_replenish_health_pressed() -> void:
	var cost = getCost(replenishPrices, Globals.replenishCount)
	if cost > 0 and Globals.minerals >= cost:
		Globals.minerals -= cost
		Globals.health = 100
		Globals.replenishCount += 1
		$purchase.play()
		shopPricingUpdateText()
		whatCanBuy()
		mainHUD.setMinerals(Globals.minerals);

func _process(_delta):
	$MineralsLabel.text = str(Globals.minerals)

func whatCanBuy():
	var upgradeWeapon = $HBoxContainer/VBoxContainer/upgradeWeapon
	var upgradeArmor = $HBoxContainer/VBoxContainer/upgradeArmor
	var replenishHealth = $HBoxContainer/VBoxContainer/ReplenishHealth

	var damageCost = getCost(mainPrices, Globals.damageUpgradeCount)
	var armorCost = getCost(mainPrices, Globals.armorUpgradeCount)
	var replenishCost = getCost(replenishPrices, Globals.replenishCount)

	# Disable if maxed out or can't afford
	upgradeWeapon.disabled = damageCost < 0 or Globals.minerals < damageCost
	upgradeArmor.disabled = armorCost < 0 or Globals.minerals < armorCost

	if replenishCost < 0 or Globals.minerals < replenishCost or Globals.health > 80:
		replenishHealth.disabled = true
	else:
		replenishHealth.disabled = false

func shopPricingUpdateText():
	var upgradeWeapon = $HBoxContainer/VBoxContainer/upgradeWeapon
	var upgradeArmor = $HBoxContainer/VBoxContainer/upgradeArmor
	var replenishHealth = $HBoxContainer/VBoxContainer/ReplenishHealth

	var damageCost = getCost(mainPrices, Globals.damageUpgradeCount)
	var armorCost = getCost(mainPrices, Globals.armorUpgradeCount)
	var replenishCost = getCost(replenishPrices, Globals.replenishCount)

	if damageCost > 0:
		upgradeWeapon.text = "Upgrade Weapon (-%d)" % damageCost
	else:
		upgradeWeapon.text = "Upgrade Weapon (maxed)"

	if armorCost > 0:
		upgradeArmor.text = "Upgrade Armor (-%d)" % armorCost
	else:
		upgradeArmor.text = "Upgrade Armor (maxed)"

	if replenishCost > 0:
		replenishHealth.text = "Replenish Health (-%d)" % replenishCost
	else:
		replenishHealth.text = "Replenish Health (maxed)"
