extends GridContainer

enum STATUS {ALIVE, DEAD}
enum MODE {NORMAL, UTOPIA, APOCALYPSE}
enum G_TYPE {Standard, Poor, Rich, Special}
enum N_TYPE {Frugal, Normal, Liberal}

#export var population = 150
export var turns = 25
export var volatility = 10
export var deviation = 10
export var poor = 5
export var rich = 5
export var spec = 5
export var stan = 5
export var slow = false
export var realism = true#need is increased to be a percentage of greed, a.k.a. you need to spend money to make money
export var batch = true
export var realism_amplifier = .50
export var need_amplifier = 5
export var greed_amplifier = 5
export var spec_amplifier = 5
export var waste_amplifier = 10
export var frugality = 100
export var liberality = 100
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
onready var standardPastResultsLabel = get_node("VBoxContainer/CenterContainer/VBoxContainer/PastResultsLabel/Standard")
onready var pooledPastResultsLabel = get_node("VBoxContainer/CenterContainer/VBoxContainer/PastResultsLabel/Pooled")
onready var charityPastResultsLabel = get_node("VBoxContainer/CenterContainer/VBoxContainer/PastResultsLabel/Charity")
onready var standardPastResults = get_node("VBoxContainer/CenterContainer/VBoxContainer/PastResults/Standard")
onready var pooledPastResults = get_node("VBoxContainer/CenterContainer/VBoxContainer/PastResults/Pooled")
onready var charityPastResults = get_node("VBoxContainer/CenterContainer/VBoxContainer/PastResults/Charity")

signal next_turn
signal sim_complete

var initial_state
var stopped = true
var batch_stopped = true

var config = ConfigFile.new()

func _ready():
	load_config()
	#save_results()
	initialize()
	results(0)
	variables.get_node("TurnsEdit").value = turns
	variables.get_node("VolEdit").value = volatility
	variables.get_node("DeviEdit").value = deviation
	variables.get_node("StanEdit").value = stan
	variables.get_node("PoorEdit").value = poor
	variables.get_node("RichEdit").value = rich
	variables.get_node("SpecEdit").value = spec
	variables.get_node("DiveEdit").value = diversity
	variables.get_node("CrashEdit").value = crash
	variables.get_node("CharityEdit").value = charity
	variables.get_node("SlowEdit").pressed = slow
	variables.get_node("RealismEdit").pressed = realism
	variables.get_node("BatchEdit").pressed = batch
	amplifiers.get_node("GreedAmpEdit").value = greed_amplifier
	amplifiers.get_node("NeedAmpEdit").value = need_amplifier
	amplifiers.get_node("SpecAmpEdit").value = spec_amplifier
	amplifiers.get_node("WasteAmpEdit").value = waste_amplifier
	amplifiers.get_node("RealAmpEdit").value = realism_amplifier * 100
	amplifiers.get_node("FrugAmpEdit").value = frugality
	amplifiers.get_node("LibAmpEdit").value = liberality
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
	#clear_results()
	rng.randomize()
	grid.columns = 10
	var curPoor = poor
	var curRich = rich
	var curSpec = spec
	var curStan = stan
	for i in range(getPopulation()):
		var rand_spec = rng.randi_range(0, diversity)
		var curGType = "None"
		var curNType = "None"
		var newNeeds = []
		var newGreeds = []
		if(curPoor > 0):
			curGType = G_TYPE.Poor
			curPoor -= 1
		elif(curStan > 0):
			curGType = G_TYPE.Standard
			curStan -= 1
		elif(curSpec > 0):
			curGType = G_TYPE.Special
			curSpec -= 1
		elif(curRich > 0):
			curGType = G_TYPE.Rich
			curRich -= 1
		var need_chance = rng.randi_range(liberality,frugality)
		if(need_chance < 30):#todo: Actually implement a weight, here
			curNType = N_TYPE.Liberal
		elif(need_chance < 60):
			curNType = N_TYPE.Normal
		else:
			curNType = N_TYPE.Frugal
		for j in range(0,diversity):
			#newNeeds.append(int(deviation/2)) #* int(need_amplifier)
			#newGreeds.append(rng.randi_range(0, deviation))
			if(curGType == G_TYPE.Poor):
				#newGreeds[j] = int(newGreeds[j]/greed_amplifier)
				newGreeds.append(rng.randi_range(0, int(deviation/greed_amplifier)))
			elif(curGType == G_TYPE.Rich):
				#newGreeds[j] = int((newGreeds[j]+1)*greed_amplifier)
				newGreeds.append(rng.randi_range(int(deviation), int(deviation*greed_amplifier)))
			elif(curGType == G_TYPE.Special):
				if j == rand_spec:
					#newGreeds[j] = int((newGreeds[j]+1)*greed_amplifier*spec_amplifier)
					newGreeds.append(rng.randi_range(int(deviation), int(deviation*greed_amplifier*spec_amplifier)))
				else:
					#newGreeds[j] = int((newGreeds[j]+1))
					newGreeds.append(rng.randi_range(0, int(deviation/greed_amplifier)))
			else:
				#newGreeds[j] = int((newGreeds[j]+1))
				newGreeds.append(rng.randi_range(int(deviation/greed_amplifier), int(deviation*greed_amplifier*2)))#really unsure if we need a ceiling variable
			if(curNType) == N_TYPE.Frugal:
				newNeeds.append(rng.randi_range(0, int(deviation/need_amplifier)))
			elif(curNType) == N_TYPE.Normal:
				newNeeds.append(rng.randi_range(int(deviation/need_amplifier), int(deviation*need_amplifier)))
			else:
				newNeeds.append(rng.randi_range(int(deviation), int(deviation*need_amplifier*2)))
		if(realism):
			var totalGreed = 0
			for k in range(0,diversity):
				totalGreed += newGreeds[k]
			for l in range(0,diversity):
				if(newNeeds[l] < int(int(totalGreed * realism_amplifier)/diversity)):
					newNeeds[l] = int(int(totalGreed * realism_amplifier)/diversity)
		instance_eed(newNeeds,newGreeds,G_TYPE.keys()[curGType],N_TYPE.keys()[curNType])
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
				var temp_donation = child.money * float(float(100-waste_amplifier)/100) * float(charity/100)
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
		while temp_dead.size() < getPopulation():
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
	emit_signal("sim_complete")

func run_pooled_simulation():
	reset()
	stopped = false
	for i in range(turns):
		if stopped:
			break
		else:
			yield(self,"next_turn")
		for child in grid.get_children():#tax phase
			var checkCrash = rng.randi_range(0, 100)
			if crash <= checkCrash:
				for j in range(0,diversity):#tax phase
					if child.status == STATUS.ALIVE:
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
		while temp_dead.size() < getPopulation():
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
	emit_signal("sim_complete")

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
		newResult.hint_tooltip = parametersHint()
		standardPastResultsLabel.text = "Standard (" + str(getAverageResults(standardPastResults.get_children())) + ")"
		pooledPastResultsLabel.text = "Pooled (" + str(getAverageResults(pooledPastResults.get_children())) + ")"
		charityPastResultsLabel.text = "Charity (" + str(getAverageResults(charityPastResults.get_children())) + ")"
		
func instance_eed(need, greed, g_type, n_type):
	var newEed = EED.instance()
	newEed.init(need,greed,g_type,n_type)
	grid.add_child(newEed)

func reset():
	total_crashes = 0
	stopped = true
	yield(self,"next_turn")
	var current_children = grid.get_children()
	for child in initial_state:
		current_children[child.get_index()].init(child.needs,child.greeds,child.g_type,child.n_type)
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

func getPopulation():
	return spec + poor + rich + stan

func parametersHint():
	var returnValue = "Turns: " + str(turns) + " Volatility: " + str(volatility) + "\n"
	returnValue += "Deviation: " + str(deviation) + " Standard: " + str(stan) + "\n"
	returnValue += "Poor: " + str(poor) + " Rich: " + str(rich) + "\n"
	returnValue += "Special: " + str(spec) + " Diversity: " + str(diversity) + "\n"
	returnValue += "Crash: " + str(crash) + " Charity: " + str(charity) + "\n"
	returnValue += "Realism: " + str(realism) + " Greed Amp: " + str(greed_amplifier) + "\n"
	returnValue += "Need Amp: " + str(need_amplifier) + " Spec Amp: " + str(spec_amplifier) + "\n"
	returnValue += "Waste Amp: " + str(waste_amplifier) + " Realism Amp: " + str(realism_amplifier * 100) + "\n"
	returnValue += "Frugal Amp: " + str(frugality) + " Liberal Amp: " + str(liberality)
	#variables.get_node("SlowEdit").pressed = slow
	#variables.get_node("BatchEdit").pressed = batch
	return returnValue

func parametersOneLine():
	var returnValue = "Turns: " + str(turns) + " Volatility: " + str(volatility)
	returnValue += " Deviation: " + str(deviation) + " Standard: " + str(stan)
	returnValue += " Poor: " + str(poor) + " Rich: " + str(rich)
	returnValue += " Special: " + str(spec) + " Diversity: " + str(diversity)
	returnValue += " Crash: " + str(crash) + " Charity: " + str(charity)
	returnValue += " Realism: " + str(realism) + " Greed Amp: " + str(greed_amplifier)
	returnValue += " Need Amp: " + str(need_amplifier) + " Spec Amp: " + str(spec_amplifier)
	returnValue += " Waste Amp: " + str(waste_amplifier) + " Realism Amp: " + str(realism_amplifier * 100)
	returnValue += " Frugal Amp: " + str(frugality) + " Liberal Amp: " + str(liberality)
	return returnValue

func formatEedGrid():
	if grid.get_child_count() > 0:
		var eed_width = grid.get_child(0).rect_size.x
		var grid_width = grid.get_parent().rect_size.x
		grid.columns = (grid_width/eed_width) - 1

func clear_results():
	for child in standardPastResults.get_children():
		standardPastResults.remove_child(child)
	for child in pooledPastResults.get_children():
		pooledPastResults.remove_child(child)
	for child in charityPastResults.get_children():
		charityPastResults.remove_child(child)

func _on_Reset_pressed():
	clear_results()


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
	if(batch):
		batch_stopped = true
	else:
		stopped = true

func _on_StanEdit_value_changed(value):
	stan = value


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

func _on_BatchEdit_toggled(button_pressed):
	batch = button_pressed
	if !batch:
		get_node("TurnTimer").wait_time = 0.05
	else:
		get_node("TurnTimer").wait_time = 0.01

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

func _on_RunHundred_pressed():
	batch_stopped = false
	var original = ""
	if stopped:
		for type in config.get_value("batch","types"): 
			var variance = config.get_value("batch",type)
			for j in range(variance[0],variance[1]+variance[2],variance[2]):
				set_batch_variable(type,j)
				for i in range(0,config.get_value("batch","runs")):
					if(!batch_stopped):
						run_standard_simulation()
						yield(self,"sim_complete")
					else:
						break
					if(!batch_stopped):
						run_pooled_simulation()
						yield(self,"sim_complete")
					else:
						break
					if(!batch_stopped):
						run_standard_simulation(true)
						yield(self,"sim_complete")
					else:
						break
					get_node("MarginContainer/CenterContainer/HBoxContainer/BatchLabel").text = "Batch status: " + str(i+1)
					initialize()
#		diversity = 5
#		variables.get_node("DiveEdit").value = diversity
#		initialize()
	get_node("MarginContainer/CenterContainer/HBoxContainer/BatchLabel").text = "Batch status: Complete"
	save_results()
	
func set_batch_variable(type, value):
	for type in config.get_value("batch","types"):
		self.set(type, config.get_value("batch","orig_" + type))
	#this is getting really out of hand, but should suffice
	if type == "diversity":
		diversity = value
		variables.get_node("DiveEdit").value = diversity
	elif type == "volatility":
		volatility = value
		variables.get_node("VolEdit").value = volatility
	elif type == "frugality":
		frugality = value
		amplifiers.get_node("FrugAmpEdit").value = frugality
	elif type == "liberality":
		liberality = value
		amplifiers.get_node("LibAmpEdit").value = liberality
	initialize()

func getAverageResults(pastResults):
	var total = 0
	if pastResults.size() == 0:
		return 0
	for result in pastResults:
		total += result.get_node("Ratio").value
	return int(total/pastResults.size())




func _on_FrugAmpEdit_value_changed(value):
	frugality = value


func _on_LibAmpEdit_value_changed(value):
	liberality = value
	
	
func load_config():
	var err = config.load("settings.cfg")
	if err == OK: # If not, something went wrong with the file loading
	# Look for the display/width pair, and default to 1024 if missing
	    # Store a variable if and only if it hasn't been defined yet
		if not config.has_section_key("batch", "types"):
			config.set_value("batch", "types", ["diversity","volatility","frugality","liberality"])
			config.set_value("batch", "diversity", [0,10,1])
			config.set_value("batch", "volatility", [0,10,1])
			config.set_value("batch", "frugality", [0,100,10])
			config.set_value("batch", "liberality", [0,100,10])
			# Save the changes by overwriting the previous file
		config.save("settings.cfg")

func save_results():
	var save_game = File.new()
	save_game.open("savegame.csv", File.WRITE)
	save_game.store_line(save_structure())
	save_game.close()

func save_structure():
	var curParams = ""#parametersOneLine()
	var save_dict = "Standard, Pooled,,Starting Parameters"
	for i in range(0,standardPastResults.get_child_count()):#kind ramshackle, but it works
		save_dict += "\n" + str(standardPastResults.get_child(i).get_node("Ratio").value)
		save_dict += "," + str(pooledPastResults.get_child(i).get_node("Ratio").value)
		if standardPastResults.get_child(i).hint_tooltip.replace("\n"," ") != curParams:
			curParams = standardPastResults.get_child(i).hint_tooltip.replace("\n"," ")
			save_dict += ",," + curParams
	#save_dict += "\n" + "Test 3, Test 4"
	return save_dict