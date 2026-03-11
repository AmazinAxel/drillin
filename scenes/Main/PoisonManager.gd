extends Node

signal poison_applied(stacks: int)

var stacks: int = 0
var max_stacks: int = 5

func add_stack():
	stacks = min(stacks + 1, max_stacks)
	emit_signal("poison_applied", stacks)

func clear():
	stacks = 0
	emit_signal("poison_applied", 0)
