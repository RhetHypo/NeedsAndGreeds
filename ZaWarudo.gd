extends GridContainer

enum STATUS {ALIVE, DEAD}
enum MODE {NORMAL, UTOPIA, APOCALYPSE}

export var population = 30
export var turns = 20
export var volatility = 10
export var deviation = 10
export var poor = 10
export var rich = 10
export var spec = 10
export var slow = false
export var realism = true#need is increased to be a percentage of greed, a.k.a. you need to spend money to make money
export var realism_amplifier = .50
export var need_amplifier = 5
export var greed_amplifier = 5
export var spec_amplifier = 5
export var waste_amplifier = 10
export var bank = []
export var donations = 0
export var prices = []
export var gdp = []
export var gdp_cost = []
export var temp_dead = []#just used for a quick workaround with apocalypse
export var diversity = 3
export var charity = 10
export var crash = 0
export var run_mode = MODE.NORMAL

var rng = RandomNumberGenerator.new()
var total_crashes = 0

const EED = preload("res://Eed.tscn")
const RESULT = preload("res://Result.tscn")

onready var grid = get_node("InnerWarudo/GridContainer")
onready var results = get_node("VBoxContainer/CenterContainer/VBoxContainer")
onready var variables = get_node("VBoxContainer/Variables")
onready var amplifiers = get_node("AmpifiersSection/Amplifiers")
onready var survivors = get_node("VBoxContainer/CenterContainer/VBoxContainer/Survivors")
onready var standardPastResults = get_node("VBoxContainer/CenterContainer/VBoxContainer/PastResults/Standard")
onready var pooledPastResults = get_node("VBoxContainer/CenterContainer/VBoxContainer/PastResults/Pooled")
onready var charityPastResults = get_node("VBoxContainer/CenterContainer/VBoxContainer/PastResults/Charity")

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
	variables.get_node("SpecEdit").value = spec
	variables.get_node("DiveEdit").value = diversity
	variables.get_node("CrashEdit").value = crash
	variables.get_node("CharityEdit").value = charity
	variables.get_node("SlowEdit").pressed = slow
	variables.get_node("RealismEdit").pressed = realism
	amplifiers.get_node("GreedAmpEdit").value = greed_amplifier
	amplifiers.get_node("NeedAmpEdit").value = need_amplifier
	amplifiers.get_node("SpecAmpEdit").value = spec_amplifier
	amplifiers.get_node("WasteAmpEdit").value = waste_amplifier
	amplifiers.get_node("RealAmpEdit").value = realism_amplifier * 100
	match run_mode:
		MODE.NORMAL:
			variables.get_node("NormalButton").pressed = true
		MODE.UTOPIA:
			variables.get_node("UtopiaButton").pressed = true
		MODE.APOCALYPSE:
			variables.get_node("ApocButton").pressed = true
	
func initialize():
	for child in grid.get_children():
		grid.remove_child(child)
	clear_results()
	rng.randomize()
	grid.columns = 10
	var curPoor = poor
	var curRich = rich
	var curSpec = spec
	for i in range(population):
		var rand_spec = rng.randi_range(0, diversity)
		var curType = "None"
		var newNeeds = []
		var newGreeds = []
		if(curPoor > 0):
			curType = "Poor"
			curPoor -= 1
		elif(curSpec > 0):
			curType = "Spec"
			curSpec -= 1
		elif(curRich > 0):
			curType = "Rich"
			curRich -= 1
		for j in range(0,diversity):
			newNeeds.append(int(deviation/2)) #* int(need_amplifier)
			#newGreeds.append(rng.randi_range(0, deviation))
			if(curType == "Poor"):
				#newGreeds[j] = int(newGreeds[j]/greed_amplifier)
				newGreeds.append(rng.randi_range(0, int(deviation/greed_amplifier)))
			elif(curType == "Rich"):
				#newGreeds[j] = int((newGreeds[j]+1)*greed_amplifier)
				newGreeds.append(rng.randi_range(int(deviation), int(deviation*greed_amplifier)))
			elif(curType == "Spec"):
				if j == rand_spec:
					#newGreeds[j] = int((newGreeds[j]+1)*greed_amplifier*spec_amplifier)
					newGreeds.append(rng.randi_range(int(deviation), int(deviation*greed_amplifier*spec_amplifier)))
				else:
					#newGreeds[j] = int((newGreeds[j]+1))
					newGreeds.append(rng.randi_range(0, int(deviation/greed_amplifier)))
			else:
				#newGreeds[j] = int((newGreeds[j]+1))
				newGreeds.append(rng.randi_range(int(deviation/greed_amplifier), int(deviation*greed_amplifier)))
		if(realism):
			var totalGreed = 0
			for k in range(0,diversity):
				totalGreed += newGreeds[k]
			for l in range(0,diversity):
				if(newNeeds[l] < int(int(totalGreed * realism_amplifier)/diversity)):
					newNeeds[l] = int(int(totalGreed * realism_amplifier)/diversity)
		instance_eed(newNeeds,newGreeds,curType)
	for j in range(0,diversity):
		bank.append(0)
	initial_state = grid.get_children().duplicate()
	formatEedGrid()

func run_standard_simulation(give_charity = false):
	reset()
	stopped = false
	for i in range(turns):
		if stopped:
			break
		else:
			yield(self,"next_turn")
		for child in grid.get_children():#work phase
			if stopped:
				break
			var checkCrash = rng.randi_range(0, 100)
			if crash <= checkCrash:
				child.work(volatility)
			else:
				total_crashes += 1
			if slow:
				child.select(true)
				if stopped:
					break
				else:
					yield(self,"next_turn")
				child.select(false)
		for child in grid.get_children():#sell phase
			for j in range(0,diversity):
				if realism:#apply waste
					bank[j] += child.sell(j,prices[j], waste_amplifier)
				else:#don't apply waste
					bank[j] += child.sell(j,prices[j], 0)
		for child in grid.get_children():#buy/survive phase
			for j in range(0,diversity):
				bank[j] -= child.buy(j,prices[j],bank[j])
			if give_charity and child.money > 0:#TODO: IMPLEMENT PEOPLE TAKING FROM CHARITY WHEN NEEDED
				var temp_donation = child.money * float(float(100-waste_amplifier)/100)
				donations = temp_donation
				child.money = child.money - temp_donation
			for j in range(0,diversity):#if below threshold, check charity
				var charityCheck = child.needs_charity(j,prices[j],bank[j],donations)
				if charityCheck:#this COULD potentially be simplified...
					var temp_donation = child.get_charity_donation(j,prices[j],bank[j],donations)
					if temp_donation > 0:
						donations -= temp_donation
						bank[j] -= child.buy(j,prices[j],bank[j])
#					var temp_donation = child.get_charity_donation(donations)
#					donations -= temp_donation
#					bank[j] -= child.buy(j,prices[j],bank[j])
			if run_mode != MODE.UTOPIA:
				child.survive()
		results(i + 1)
	if run_mode != MODE.APOCALYPSE:
		if give_charity:
			results(turns,3)
		else:
			results(turns,1)
	else:
		var extra_turns = 0
		while temp_dead.size() < population:
			for child in grid.get_children():#buy/survive phase
				for j in range(0,diversity):
					bank[j] -= child.buy(j,prices[j],bank[j])
				if give_charity and child.money > 0:
					var temp_donation = child.money * float(float(100-waste_amplifier)/100)
					donations = temp_donation
					child.money = child.money - temp_donation 
				child.survive()
			extra_turns += 1
			results(turns+extra_turns)
		if give_charity:
			results(turns+1+extra_turns,3)
		else:
			results(turns+1+extra_turns,1)
	stopped = true

func run_pooled_simulation():
	reset()
	stopped = false
	for i in range(turns):
		if stopped:
			break
		else:
			yield(self,"next_turn")
		for j in range(0,diversity):#tax phase
			for child in grid.get_children():
				if child.status == STATUS.ALIVE:
					var checkCrash = rng.randi_range(0, 100)
					if crash <= checkCrash:
						var tax = child.tax(j,volatility)
						if realism:#apply waste
							tax = int(tax * float(100-waste_amplifier)/100)
						bank[j] = bank[j] + tax
					else:
						total_crashes += 1
			#results(i + 1)
		for j in range(0,diversity):#stimulus phase
			for child in grid.get_children():
				if bank[j] > child.needs[j] and child.status == STATUS.ALIVE:
					child.stim(child.needs[j], j)
					bank[j] = bank[j] - child.needs[j]
			#results(i + 1)
		for child in grid.get_children():#survive phase
			if run_mode != MODE.UTOPIA:
				child.survive()
			if slow:
				child.select(true)
				if stopped:
					break
				else:
					yield(self,"next_turn")
				child.select(false)
			#results(i + 1)
		results(i + 1)
	if run_mode != MODE.APOCALYPSE:
		results(turns,2)
	else:
		var extra_turns = 0
		while temp_dead.size() < population:
			for j in range(0,diversity):#stimulus phase
				for child in grid.get_children():
					if bank[j] > child.needs[j] and child.status == STATUS.ALIVE:
						child.stim(child.needs[j], j)
						bank[j] = bank[j] - child.needs[j]
				#results(i + 1)
			for child in grid.get_children():#survive phase
				child.survive()
				if slow:
					child.select(true)
					if stopped:
						break
					else:
						yield(self,"next_turn")
					child.select(false)
				#results(i + 1)
			results(turns+1+extra_turns)
		results(turns+1+extra_turns,2)
	stopped = true

func results(i, final=0):
	var alive = []
	var dead = []
	var need = []
	for child in grid.get_children():
		if child.status == STATUS.DEAD:
			dead.append(child)
		elif child.status == STATUS.ALIVE:
			alive.append(child)
	temp_dead = dead.duplicate()
	calc_gpd()
	calc_prices()
#	results.text = "Turn: " + str(i)
#	results.text = results.text + "\n" + "ALIVE: " + str(alive.size())
#	results.text = results.text + "\n" + "DEAD: " + str(dead.size())
#	results.text = results.text + "\n" + "BANK: " + str(bank)
#	results.text = results.text + "\n" + "PRICES: " + str(prices)
#	results.text = results.text + "\n" + "TOTAL NEEDS:  " + str(gdp_cost)
#	results.text = results.text + "\n" + "TOTAL GREEDS: " + str(gdp)
	results.get_node("TurnsLabel").text = "TURN: " + str(i)
	results.get_node("PopLabel").text = "ALIVE: " + str(alive.size()) + ", DEAD: " + str(dead.size())
	results.get_node("BankLabel").text = "BANK: " + str(bank)
	results.get_node("PriceLabel").text = "PRICES: " + str(prices)
	results.get_node("TotalNeeds").text = "TOTAL NEEDS:  " + str(gdp_cost)
	results.get_node("TotalGreeds").text = "TOTAL GREEDS: " + str(gdp)
	survivors.get_node("Alive").text = "Alive:" + "\n" + str(alive.size())
	survivors.get_node("Dead").text = "Dead:" + "\n" + str(dead.size())
	var ratio = 100
	if(dead.size() > 0):
		ratio = alive.size()*100/(dead.size() + alive.size())
	survivors.get_node("Ratio").value = ratio
	if final != 0:
		var newResult = RESULT.instance()
		if final == 1:
			standardPastResults.add_child(newResult)
			standardPastResults.move_child(newResult, 0)
		elif final == 2:
			pooledPastResults.add_child(newResult)
			pooledPastResults.move_child(newResult, 0)
		elif final == 3:
			charityPastResults.add_child(newResult)
			charityPastResults.move_child(newResult, 0)
		if run_mode == MODE.NORMAL:
			newResult.get_node("Result").text = "Crashes: " + str(total_crashes)
			newResult.get_node("Ratio").value = ratio
		elif run_mode == MODE.APOCALYPSE:
			newResult.get_node("Apoc").visible = true
			newResult.get_node("Apoc").text = "TURNS: " + str(i)
			newResult.get_node("Result").text = "Crashes: " + str(total_crashes)
			newResult.get_node("Ratio").visible = false
		elif run_mode == MODE.UTOPIA:
			newResult.get_node("Result").text = "Everything is fine."
			newResult.get_node("Ratio").value = ratio
			
func instance_eed(need, greed, type):
	var newEed = EED.instance()
	newEed.init(need,greed,type)
	grid.add_child(newEed)

func reset():
	total_crashes = 0
	stopped = true
	yield(self,"next_turn")
	var current_children = grid.get_children()
	for child in initial_state:
		current_children[child.get_index()].init(child.needs,child.greeds,child.type)
	bank = []
	for j in range(0,diversity):
		bank.append(0)
	results(0)
	
func calc_prices():
	var gross = 0
	prices = []
	for good in gdp:
		gross += good
	for good in gdp:
		if good == 0:
			prices.append(1)
		else:
			prices.append(float(float(gross)/float(good)/gdp.size()))

func calc_gpd():
	gdp = []
	gdp_cost = []
	for i in range(0,diversity):
		gdp.append(0)
		gdp_cost.append(0)
	for child in grid.get_children():
		if child.status != STATUS.DEAD:
			for i in child.greeds.size():
				gdp[i] += child.greeds[i]
			for i in child.needs.size():
				gdp_cost[i] += child.needs[i]

func formatEedGrid():
	if grid.get_child_count() > 0:
		var eed_width = grid.get_child(0).rect_size.x
		var grid_width = grid.get_parent().rect_size.x
		grid.columns = grid_width/eed_width
func clear_results():
	for child in standardPastResults.get_children():
		standardPastResults.remove_child(child)
	for child in pooledPastResults.get_children():
		pooledPastResults.remove_child(child)
	for child in charityPastResults.get_children():
		charityPastResults.remove_child(child)

func _on_Reset_pressed():
	reset()


func _on_Standard_pressed():
	if stopped:
		run_standard_simulation()


func _on_Pooled_pressed():
	if stopped:
		run_pooled_simulation()

func _on_Charity_pressed():
	if stopped:
		run_standard_simulation(true)

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

func _on_SpecEdit_value_changed(value):
	spec = value

func _on_CheckBox_toggled(button_pressed):
	slow = button_pressed


func _on_RealismEdit_toggled(button_pressed):
	realism = button_pressed


func _on_VolEdit_value_changed(value):
	volatility = value


func _on_DiveEdit_value_changed(value):
	diversity = value

func _on_CrashEdit_value_changed(value):
	crash = value

func _on_CharityEdit_value_changed(value):
	charity = value

func _on_InnerWarudo_resized():
	if stopped:
		formatEedGrid()

func _on_NormalButton_button_up():
	run_mode = MODE.NORMAL

func _on_UtopiaButton_button_up():
	run_mode = MODE.UTOPIA

func _on_ApocButton_button_up():
	run_mode = MODE.APOCALYPSE

func _on_NeedAmpEdit_value_changed(value):
	need_amplifier = value

func _on_GreedAmpEdit_value_changed(value):
	greed_amplifier = value

func _on_SpecAmpEdit_value_changed(value):
	spec_amplifier = value

func _on_WasteAmpEdit_value_changed(value):
	waste_amplifier = value

func _on_RealAmpEdit_value_changed(value):
	realism_amplifier = float(value / 100)

func _on_Button_pressed():
	clear_results()
