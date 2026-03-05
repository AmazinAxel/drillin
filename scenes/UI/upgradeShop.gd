extends Control

func _ready():
	whatCanBuy()

func _on_damage_upgrade_pressed() -> void:
	if Globals.minerals >= 3:
		Globals.minerals -= 3
		Globals.attackDamage += 1
		$purchase.play()
		whatCanBuy()

func _on_health_upgrade_pressed() -> void:
	if Globals.minerals >= 3:
		Globals.minerals -= 3
		Globals.damageReduction -= 0.3
		$purchase.play()
		whatCanBuy()

func _on_replenish_health_pressed() -> void:
	if Globals.minerals >= 1:
		Globals.minerals -= 1
		Globals.health = 100
		$purchase.play()
		whatCanBuy()

func _process(delta):
	$MineralsLabel.text = str(Globals.minerals)

func whatCanBuy():
	var upgradeWeapon = $HBoxContainer/VBoxContainer/upgradeWeapon
	var upgradeArmor = $HBoxContainer/VBoxContainer/upgradeArmor
	var replenishHealth = $HBoxContainer/VBoxContainer/ReplenishHealth

	if Globals.minerals > 0:
		if Globals.health > 80:
			replenishHealth.disabled = true
	else:
		replenishHealth.disabled = true

	if Globals.minerals < 3:
		upgradeWeapon.disabled = true
		upgradeArmor.disabled = true
