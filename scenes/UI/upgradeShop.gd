extends Control

func _on_damage_upgrade_pressed() -> void:
	if Globals.minerals >= 3:
		Globals.minerals -= 3
		Globals.attackDamage += 1

func _on_health_upgrade_pressed() -> void:
	if Globals.minerals >= 3:
		Globals.minerals -= 3
		Globals.damageReduction -= 0.1  # takes less damage (since damage = amount * damageReduction)

func _on_risk_upgrade_pressed() -> void:
	if Globals.minerals >= 1:
		Globals.minerals -= 1
		Globals.riskChance -= 0.1  

func _process(delta):
	$MineralsLabel.text = str(Globals.minerals)
