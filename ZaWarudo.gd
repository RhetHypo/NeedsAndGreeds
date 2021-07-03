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
export var bank = []
export var prices = []
export var gdp = []
export var diversity = 2

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
	variables.get_node("DiveEdit").value = diversity
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
		var newNeeds = []
		var newGreeds = []
		if(curPoor > 0):
			curType = "Poor"
			curPoor -= 1
		elif(curRich > 0):
			curType = "Rich"
			curRich -= 1
		for j in range(0,diversity):
			newNeeds.append(int(deviation/2)) #* int(need_amplifier)
			newGreeds.append(rng.randi_range(0, deviation))
			if(curType == "Poor"):
				newGreeds[j] = int(newGreeds[j]/greed_amplifier)
			elif(curType == "Rich"):
				newGreeds[j] = int((newGreeds[j]+1)*greed_amplifier)
			if(realism):
				if(newNeeds[j] < int(newGreeds[j] * realism_amplifier)):
					newNeeds[j] = int(newGreeds[j] * realism_amplifier)
		instance_eed(newNeeds,newGreeds,curType)
	for j in range(0,diversity):
		bank.append(0)
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
		for j in range(0,diversity):
			for child in grid.get_children():
				if child.status == STATUS.ALIVE:
					var tax = child.tax(j,volatility)
					bank[j] = bank[j] + tax
			results(i + 1)
		for j in range(0,diversity):
			for child in grid.get_children():
				if bank[j] > child.needs[j] and child.status == STATUS.ALIVE:
					child.stim(child.needs[j], j)
					bank[j] = bank[j] - child.needs[j]
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
	var need = []
	gdp = []
	for i in range(0,diversity):
		gdp.append(0)
		need.append(0)
	for child in grid.get_children():
		for i in child.needs.size():
			need[i] += child.needs[i]
		for i in child.greeds.size():
			gdp[i] += child.greeds[i]
		if child.status == STATUS.DEAD:
			dead.append(child)
		elif child.status == STATUS.ALIVE:
			alive.append(child)
	prices()
	results.text = "Turn: " + str(i)
	results.text = results.text + "\n" + "ALIVE: " + str(alive.size())
	results.text = results.text + "\n" + "DEAD: " + str(dead.size())
	results.text = results.text + "\n" + "BANK: " + str(bank)
	results.text = results.text + "\n" + "PRICES: " + str(prices)
	results.text = results.text + "\n" + "TOTAL NEEDS:  " + str(need)
	results.text = results.text + "\n" + "TOTAL GREEDS: " + str(gdp)
	
func instance_eed(need, greed, type):
	var newEed = EED.instance()
	newEed.init(need,greed,type)
	grid.add_child(newEed)

func reset():
	stopped = true
	yield(self,"next_turn")
	var current_children = grid.get_children()
	for child in initial_state:
		current_children[child.get_index()].init(child.needs,child.greeds,child.type)
	bank = []
	for j in range(0,diversity):
		bank.append(0)
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


func _on_DiveEdit_value_changed(value):
	diversity = value
