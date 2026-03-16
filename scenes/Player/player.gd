extends CharacterBody2D

const SPEED = 10
const JUMP_VELOCITY = -350.0 # jump thingy

var dropTimer := 0.0
var isDropping := false
var isThrown := false
var poisonTick := 0.0

var isCrouching := false
var crouch_tween: Tween
const CROUCH_SCALE_Y = 0.9

func _physics_process(delta: float) -> void:
	if Globals.isDead:
		return # do not move when dead!!!
	
	# crouchin
	var wantsCrouch = Input.is_action_pressed("down")
	if wantsCrouch and not isCrouching:
		_set_crouch(true)
	elif not wantsCrouch and isCrouching:
		_set_crouch(false)
	
	# attackin
	if Input.is_action_pressed("down"):
		isDropping = true
		dropTimer = 0.15
	if Input.is_action_pressed("attack") and not Globals.isAttacking and not isThrown:
		attack()
	elif Input.is_action_pressed("throw"): # throwin
		throwPickaxe()
	
	# pickaxe animation
	if isDropping:
		dropTimer -= delta
		if dropTimer <= 0:
			isDropping = false
	set_collision_layer_value(6, not isDropping)
	set_collision_mask_value(6, not isDropping)

	if not is_on_floor():
		velocity += get_gravity() * delta
	if Input.is_action_pressed("up") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	var direction := Input.get_axis("left", "right")

	if direction:
		velocity.x = lerp(direction * SPEED, direction * SPEED * 2, 10)
		$playerSprite.flip_h = direction > 0
		$pickaxe.flip_h = direction > 0
		$pickaxe.flip_v = direction < 0
		
		var lightDirection
		if direction > 0:
			lightDirection = 89.5
			Globals.baseRotation = 0
		else:
			lightDirection = -89.5
			Globals.baseRotation = 30
			
		$flashlight.rotation = lightDirection
		$playerSprite.play("default")
		if is_on_floor():
			$walkingParticles.emitting = true

	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		$playerSprite.set_frame_and_progress(0, 0)
		$playerSprite.pause()

	# jump n move
	move_and_slide()
	if !is_on_floor():
		$playerSprite.play("jump")

	var mouse_pos = get_global_mouse_position()
	var mouseDirection = mouse_pos - global_position
	var angle = mouseDirection.angle()

	$pickaxe.rotation = angle + Globals.baseRotation
	var radius = 10 
	$pickaxe.position = Vector2.RIGHT.rotated(angle) * radius

	if $healthBar:
		$healthBar.value = Globals.health
		
	handlePoisonDamage(delta)

func take_damage(amount):
	if Globals.isDead:
		return
	if Globals.inDrill:
		return # no damage in drill

	var actual_damage = amount * Globals.damageReduction
	Globals.health -= actual_damage
	Globals.health = max(Globals.health, 0)

	Globals.screen_shake(5, 0.2)

	if randf() < 0.5:
		$ouch.play()
	else:
		$ow.play()

	var rand_int = randi_range(1, 4)

	if (rand_int == 1):
		$ohParticles.emitting = true
	elif (rand_int == 2):
		$uhParticles.emitting = true
	elif (rand_int == 3):
		$ouchParticles.emitting = true
	elif (rand_int == 4):
		$unfriendlyOuchParticles.emitting = true

	if $healthBar:
		$healthBar.value = Globals.health
	modulate = Color.RED
	await get_tree().create_timer(0.15).timeout
	modulate = Color.WHITE
	if Globals.health <= 0:
		die()

func _on_attack_delay_timeout() -> void:
	Globals.isAttacking = false

func _on_damage_area_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		return
	elif body.name == "TileMapLayer":
		return

	if body.has_method("take_damage"):
		body.take_damage(Globals.attackDamage)

func die():
	Globals.isDead = true
	velocity = Vector2.ZERO
	$walkingParticles.emitting = false

	$playerSprite.play("death")
	$skullParticles.emitting = true
	
	PoisonGlobals.clear_poison()
	
	$pickaxe.visible = false;
	$healthBar.visible = false;
	$Heart.visible = false;

	if is_inside_tree():
		get_tree().create_timer(2.0).timeout.connect(playAgain, CONNECT_ONE_SHOT)

func playAgain():
	var tree = get_tree()
	Globals.transitioningOut = true;
	
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0)
	overlay.size = get_viewport().get_visible_rect().size
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	var canvas = CanvasLayer.new()
	canvas.layer = 128
	canvas.add_child(overlay)
	tree.root.add_child(canvas)
	
	var tween = tree.create_tween()
	tween.tween_property(overlay, "color:a", 1.0, 0.5)
	
	Globals.lives -= 1;
	
	if Globals.lives <= 1:
		# load and add the warning scene
		var warning_scene = preload("res://scenes/UI/livesWarning.tscn").instantiate()
		warning_scene.modulate.a = 0.0
		canvas.add_child(warning_scene)
		
		if Globals.lives == 1:
			warning_scene.get_node("Label2").text = "1 life remaining"
		else:
			warning_scene.get_node("Label2").text = "No lives remaining"
		
		# fade in warning
		tween.tween_property(warning_scene, "modulate:a", 1.0, 0.5)
		# hold on screen
		tween.tween_interval(1.5)
		# fade out warning
		tween.tween_property(warning_scene, "modulate:a", 0.0, 0.5)
		
		if Globals.lives == 0:
			Globals.level = 0;
			Globals.started = false;
			tween.tween_callback(func():
				Globals.resetVars()
				tree.change_scene_to_file("res://scenes/UI/PlayUI.tscn")
				
				# fix
				mainHUD.setMinerals(Globals.minerals);
				mainHUD.setMinerals(Globals.lives);
			)
			tween.tween_interval(0.1)
			tween.tween_property(overlay, "color:a", 0.0, 0.5)
			tween.tween_callback(canvas.queue_free);
			
			return
	
	tween.tween_callback(func():
		Globals.resetToSpawnpoint()
		get_tree().call_deferred("change_scene_to_file", "res://scenes/Main/Main.tscn");
		Globals.transitioningOut = false;
	)
	
	# wait a frame for the new scene to load, then fade out
	tween.tween_interval(0.1)
	tween.tween_property(overlay, "color:a", 0.0, 0.5)
	tween.tween_callback(canvas.queue_free)

#
# PICKAXE
#

@export var thrownPickaxeScene: PackedScene
var swing_tween: Tween
var thrown_instance = null


func throwPickaxe():
	if not thrownPickaxeScene:
		return
	if thrown_instance != null:
		return
		
	$woosh.play()
	isThrown = true

	$pickaxe.visible = false
	Globals.isAttacking = true

	thrown_instance = thrownPickaxeScene.instantiate()
	get_tree().current_scene.add_child(thrown_instance)
	
	var dir = (get_global_mouse_position() - global_position).normalized()
	thrown_instance.global_position = $pickaxe.global_position 
	thrown_instance.rotation = dir.angle()
	thrown_instance.launch(dir, self)

	velocity += -dir * 150.0
	
	await get_tree().create_timer(0.5).timeout
	if is_instance_valid(thrown_instance):
		thrown_instance.returning = true
		isThrown = false
		
func catch_pickaxe():
	$pickaxe.visible = true
	Globals.isAttacking = false
	thrown_instance = null

func attack():
	if Globals.isDead:
		return 
	if (self.name == "Player"):
		Globals.isAttacking = true
		swing_pickaxe()
		var timer = get_node("attackDelay")
		timer.start()

func swing_pickaxe():
	if Globals.isDead:
		return 
	if swing_tween:
		swing_tween.kill()
		
	swing_tween = create_tween()
	Globals.screen_shake(2, 0.1)
	
	var current_angle = $pickaxe.rotation
	var swing_amount = deg_to_rad(90)
	
	if $playerSprite.flip_h:
		swing_amount = -swing_amount
	
	$pickaxe/damageArea.monitoring = true
	
	swing_tween.tween_property($pickaxe, "rotation", current_angle + swing_amount, 0.1)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_BACK)
	swing_tween.tween_property($pickaxe, "rotation", current_angle, 0.1)\
		.set_ease(Tween.EASE_IN)\
		.set_trans(Tween.TRANS_SINE)
	
	# no more damage when swing ends
	swing_tween.tween_callback(func(): $pickaxe/damageArea.monitoring = false)

func _set_crouch(crouching: bool) -> void:
	isCrouching = crouching

	if crouch_tween:
		crouch_tween.kill()
	crouch_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)

	var target_scale_y = (CROUCH_SCALE_Y if crouching else 1.0)

	crouch_tween.tween_property($playerSprite, "scale:y", target_scale_y, 0.12)

	
	var col = $collisionBox
	if col and col.shape:
		var base_height = col.shape.height  
		var target_height = (col.shape.height / (1.0 / target_scale_y)) if crouching else col.shape.height
		crouch_tween.parallel().tween_method(
			func(h): col.shape.height = h,
			col.shape.height,
			28.0 if crouching else 32.0,
			0.12
		)

func handlePoisonDamage(delta: float) -> void:
	if PoisonGlobals.intensity > 0.05:
		poisonTick += delta
		if poisonTick >= 1.0:
			poisonTick = 0.0
			$poisonParticles.emitting = true
			take_damage(2.0)
	else:
		$poisonParticles.emitting = false
		poisonTick = 0.0

func playPickupSound():
	$MineralPickup.play()
