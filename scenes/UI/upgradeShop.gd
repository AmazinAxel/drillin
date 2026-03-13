extends Control

var damagePrices := [3, 4, 6, 9, 13]
var armorPrices := [3, 5, 8, 12]
var replenishPrices := [1, 1, 2, 2, 3]

# Track how many times each has been purchased
var damageUpgradeCount := 0
var armorUpgradeCount := 0
var replenishCount := 0

func getCost(prices: Array, count: int) -> int:
	if count >= prices.size():
		return -1  # -1 means maxed out
	return prices[count]

func _ready():
	#shopPricingUpdateText()
	whatCanBuy()

func _on_damage_upgrade_pressed() -> void:
	var cost = getCost(damagePrices, damageUpgradeCount)
	if cost > 0 and Globals.minerals >= cost:
		Globals.minerals -= cost
		Globals.attackDamage += 1
		damageUpgradeCount += 1
		$purchase.play()
		#shopPricingUpdateText()
		whatCanBuy()

func _on_health_upgrade_pressed() -> void:
	var cost = getCost(armorPrices, armorUpgradeCount)
	if cost > 0 and Globals.minerals >= cost:
		Globals.minerals -= cost
		Globals.damageReduction -= 0.3
		armorUpgradeCount += 1
		$purchase.play()
		#shopPricingUpdateText()
		whatCanBuy()

func _on_replenish_health_pressed() -> void:
	var cost = getCost(replenishPrices, replenishCount)
	if cost > 0 and Globals.minerals >= cost:
		Globals.minerals -= cost
		Globals.health = 100
		replenishCount += 1
		$purchase.play()
		#shopPricingUpdateText()
		whatCanBuy()

func _process(_delta):
	$MineralsLabel.text = str(Globals.minerals)

func whatCanBuy():
	var upgradeWeapon = $HBoxContainer/VBoxContainer/upgradeWeapon
	var upgradeArmor = $HBoxContainer/VBoxContainer/upgradeArmor
	var replenishHealth = $HBoxContainer/VBoxContainer/ReplenishHealth

	var damageCost = getCost(damagePrices, damageUpgradeCount)
	var armorCost = getCost(armorPrices, armorUpgradeCount)
	var replenishCost = getCost(replenishPrices, replenishCount)

	# Disable if maxed out or can't afford
	upgradeWeapon.disabled = damageCost < 0 or Globals.minerals < damageCost
	upgradeArmor.disabled = armorCost < 0 or Globals.minerals < armorCost

	if replenishCost < 0 or Globals.minerals < replenishCost or Globals.health > 80:
		replenishHealth.disabled = true
	else:
		replenishHealth.disabled = false
