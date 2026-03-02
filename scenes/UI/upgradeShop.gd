extends Control

func _on_damage_upgrade_pressed() -> void:
	if Globals.minerals >= 3:
		Globals.minerals -= 3
		Globals.attackDamage += 1
		$purchase.play()

func _on_health_upgrade_pressed() -> void:
	if Globals.minerals >= 3:
		Globals.minerals -= 3
		Globals.damageReduction -= 0.3  # takes less damage (since damage = amount * damageReduction)
		$purchase.play()

func _on_replenish_health_pressed() -> void:
	if Globals.minerals >= 1:
		Globals.minerals -= 1
		Globals.health = 100
		$purchase.play()

func _process(delta):
	$MineralsLabel.text = str(Globals.minerals)
