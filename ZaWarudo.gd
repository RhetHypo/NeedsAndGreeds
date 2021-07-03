extends CenterContainer

export var population = 25
export var turns = 50
export var volatility = 1
export var deviation = 10
export var poor = 10
export var rich = 10
export var slow = false
export var realism = true#need is increased to be a percentage of greed, a.k.a. you need to spend money to make money
export var realism_amplifier = .75
export var need_amplifier = 5
export var greed_amplifier = 5
export var bank = 0

var rng = RandomNumberGenerator.new()

enum STATUS {ALIVE, DEAD}

const EED = preload("res://Eed.tscn")

onready var grid = get_node("VBoxContainer/GridContainer")
onready var results = get_node("VBoxContainer/CenterContainer/Label")
onready var variables = get_node("VBoxContainer/Variables")

signal next_turn

var initial_state
var stopped = true

func _ready():
	initialize()
	results(0)
	variables.get_node("PopEdit").value = population
	variables.get_node("TurnsEdit").value = turns
	variables.get_node("VolEdit").value = volatility
	variables.get_node("DeviEdit").value = deviation
	variables.get_node("PoorEdit").value = poor
	variables.get_node("RichEdit").value = rich
	variables.get_node("SlowEdit").pressed = slow
	variables.get_node("RealismEdit").pressed = realism
	
func initialize():
	for child in grid.get_children():
		grid.remove_child(child)
	rng.randomize()
	grid.columns = sqrt(population)
	var curPoor = poor
	var curRich = rich
	for i in range(population):
		var curType = "None"
		var newNeed = int(deviation/2) #* int(need_amplifier)
		var newGreed = rng.randi_range(0, deviation)
		if(curPoor > 0):
			newGreed = int(newGreed/greed_amplifier)
			curPoor -= 1
			curType = "Poor"
		elif(curRich > 0):
			newGreed = int((newGreed+1)*greed_amplifier)
			curRich -= 1
			curType = "Rich"
		else:
			newGreed = newGreed
		print(int(newGreed * realism_amplifier))
		if(realism):
			if(newNeed < int(newGreed * realism_amplifier)):
				newNeed = int(newGreed * realism_amplifier)
		instance_eed(newNeed,newGreed,volatility,curType)
	initial_state = grid.get_children().duplicate()

func run_standard_simulation():
	stopped = false
	for i in range(turns):
		if stopped:
			break
		else:
			yield(self,"next_turn")
		for child in grid.get_children():
			if stopped:
				break
			child.work(volatility)
			if slow:
				child.select(true)
				yield(self,"next_turn")
				child.select(false)
		results(i + 1)

func run_pooled_simulation():
	stopped = false
	for i in range(turns):
		if stopped:
			break
		else:
			yield(self,"next_turn")
		for child in grid.get_children():
			var tax = child.tax(volatility)
			bank = bank + tax
		results(i + 1)
		for child in grid.get_children():
			if bank > child.need and child.status == STATUS.ALIVE:
				child.stim(child.need)
				bank = bank - child.need
		results(i + 1)
		for child in grid.get_children():
			child.survive()
			if slow:
				child.select(true)
				yield(self,"next_turn")
				child.select(false)
			results(i + 1)
		results(i + 1)

func results(i):
	var alive = []
	var dead = []
	for child in grid.get_children():
		if child.status == STATUS.DEAD:
			dead.append(child)
		elif child.status == STATUS.ALIVE:
			alive.append(child)
	results.text = "Turn: " + str(i)
	results.text = results.text + "\n" + "ALIVE: " + str(alive.size())
	results.text = results.text + "\n" + "DEAD: " + str(dead.size())
	results.text = results.text + "\n" + "BANK: " + str(bank)
	
func instance_eed(need, greed, vol, type):
	var newEed = EED.instance()
	newEed.init(need,greed,type)
	grid.add_child(newEed)

func reset():
	stopped = true
	yield(self,"next_turn")
	var current_children = grid.get_children()
	for child in initial_state:
		current_children[child.get_index()].init(child.need,child.greed,child.type)
	bank = 0
	results(0)

func _on_Reset_pressed():
	reset()


func _on_Standard_pressed():
	run_standard_simulation()


func _on_Pooled_pressed():
	run_pooled_simulation()


func _on_Reset_Stats_pressed():
	initialize()
	reset()


func _on_TurnTimer_timeout():
	emit_signal("next_turn")


func _on_Pause_pressed():
	if get_tree().paused:
		get_tree().paused = false
	else:
		get_tree().paused = true


func _on_Stop_pressed():
	stopped = true

func _on_PopEdit_value_changed(value):
	population = value


func _on_TurnsEdit_value_changed(value):
	turns = value

func _on_DeviEdit_value_changed(value):
	deviation = value


func _on_PoorEdit_value_changed(value):
	poor = value


func _on_RichEdit_value_changed(value):
	rich = value


func _on_CheckBox_toggled(button_pressed):
	slow = button_pressed


func _on_RealismEdit_toggled(button_pressed):
	realism = button_pressed


func _on_VolEdit_value_changed(value):
	volatility = value
