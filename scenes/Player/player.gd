extends CharacterBody2D

const SPEED = 10
const JUMP_VELOCITY = -350.0

var dropTimer := 0.0
var isDropping := false

var isCrouching := false
var crouch_tween: Tween
const CROUCH_SCALE_Y = 0.9

func _physics_process(delta: float) -> void:
	if Globals.isDead:
		return # stop all input/movement when ded
	
	var wantsCrouch = Input.is_action_pressed("down")

	if wantsCrouch and not isCrouching:
		_set_crouch(true)
	elif not wantsCrouch and isCrouching:
		_set_crouch(false)
		
	if Input.is_action_pressed("down"):
		isDropping = true
		dropTimer = 0.15
		
	if isDropping:
		dropTimer -= delta
		if dropTimer <= 0:
			isDropping = false
	
	set_collision_layer_value(6, not isDropping)
	set_collision_mask_value(6, not isDropping)

	if not is_on_floor():
		velocity += get_gravity() * delta
	if Input.is_action_just_pressed("up") and is_on_floor():
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

	move_and_slide()

	# jump sprite
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

func take_damage(amount):
	if Globals.isDead:
		return
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
	
	$pickaxe.visible = false;
	$healthBar.visible = false;
	$Heart.visible = false;

	if is_inside_tree():
		get_tree().create_timer(2.0).timeout.connect(playAgain, CONNECT_ONE_SHOT)

func playAgain():
	var tree = get_tree()
	
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0)
	overlay.size = get_viewport().get_visible_rect().size
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var canvas = CanvasLayer.new()
	canvas.layer = 100
	canvas.add_child(overlay)
	tree.root.add_child(canvas)
	
	var tween = tree.create_tween()
	tween.tween_property(overlay, "color:a", 1.0, 0.5)
	tween.tween_callback(func():
		Globals.resetVars()
		tree.change_scene_to_file("res://scenes/Main/Main.tscn")
		
		var tween2 = overlay.create_tween()
		tween2.tween_interval(0.1)
		tween2.tween_property(overlay, "color:a", 0.0, 0.5)
		tween2.tween_callback(canvas.queue_free)
	)
#
# PICKAXE
#

@export var thrownPickaxeScene: PackedScene
var swing_tween: Tween
var thrown_instance = null

func _unhandled_input(event: InputEvent) -> void:
	if Globals.isDead:
		return # no pickaxe when ded

	if event.is_action_pressed("attack") and not Globals.isAttacking:
		attack()

	# Throw pickaxe	
	elif event.is_action_pressed("throw") and not Globals.isAttacking:

		if not thrownPickaxeScene:
			return
		if thrown_instance != null:
			return
			
		$woosh.play()

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
	
	# damage during the swing
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

	var target_scale_y = CROUCH_SCALE_Y if crouching else 1.0

	crouch_tween.tween_property($playerSprite, "scale:y", target_scale_y, 0.12)

	
	var col = $collisionBox
	if col and col.shape:
		var base_height = col.shape.height  
		var target_height = (col.shape.height / (1.0 / target_scale_y)) if crouching else col.shape.height
		crouch_tween.parallel().tween_method(
			func(h): col.shape.height = h,
			col.shape.height,
			16.0 if crouching else 32.0,
			0.12
		)
