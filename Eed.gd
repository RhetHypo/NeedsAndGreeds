extends TextureRect

export var needs = []
export var greeds = []
export var balances = []
export var money = 0
#export var volatility = 1
export var type = "None"

var rng = RandomNumberGenerator.new()

onready var greedDisplay = get_node("ColorRectGreed/CenterContainer/Label")
onready var needDisplay = get_node("ColorRectNeed/CenterContainer/Label")
onready var typeDisplay = get_node("ColorRectType/CenterContainer/Label")

var status = STATUS.ALIVE

enum STATUS {ALIVE, DEAD}

func _ready():
	rng.randomize()
	var tempGreed = 0
	var tempNeed = 0
	for greed in greeds:
		tempGreed += greed
	for need in needs:
		tempNeed += need
	greedDisplay.text = str(tempGreed)
	needDisplay.text = str(tempNeed)
	typeDisplay.text = type
	

func init(set_need, set_greed, set_type):
	needs = set_need.duplicate()
	greeds = set_greed.duplicate()
	money = 0
	balances = set_need.duplicate()#not sure why I can't just loop by size and append
	for i in range(0,balances.size()):
		balances[i] = 0
	type = set_type
	hint_tooltip = "Type: " + type + ", Need: " + str(needs) + ", Greed: " + str(greeds) + ", Current: " + str(balances) + ", Money: " + str(money)
	set_status(STATUS.ALIVE)

func work(volatility = 0):
	for i in range(0,needs.size()):
		if status != STATUS.DEAD:
			var vol_mod = rng.randi_range(-volatility, volatility)
			self.balances[i] = self.balances[i] + self.greeds[i] + vol_mod
	#survive()

func tax(index, volatility = 0, partial = 0):
	if status != STATUS.DEAD:
		var vol_mod = rng.randi_range(-volatility, volatility)
		self.balances[index] = self.balances[index] + self.greeds[index] + vol_mod
		if partial != 0:
			if balances[index] > partial:
				var temp = partial
				balances[index] = balances[index] - partial
				return temp
	var temp = self.balances[index]
	self.balances[index] = 0
	return temp

func stim(partial,i):
	balances[i] = balances[i] + partial

func buy(index, price, max_amount):
	var required_amount = needs[index] - balances[index]
	var required_price = (required_amount) * price
	if required_amount > 0 and required_amount <= max_amount and required_price < money:
		money -= required_price
		balances[index] += required_amount
		return required_amount
	return 0

func needs_charity(index, price, max_amount, donations):
	var required_amount = needs[index] - balances[index]
	var required_price = (required_amount) * price
	if required_amount > 0 and required_amount <= max_amount and required_price < donations + money:
		return true
	return false

func get_charity_donation(index, price, max_amount, donations):
	var required_amount = needs[index] - balances[index]
	var required_price = (required_amount) * price
	if required_price < donations + money:
		var charity_amount = required_price - money
		money += charity_amount
		return charity_amount
	return 0#I don't think this should ever happen

func sell(index, price, waste):
	var profit = balances[index] - needs[index]
	profit = int(profit * float(float(100-waste)/100))
	if profit > 0:
		money += profit * price
		balances[index] -= profit
		return profit
	return 0

func survive():
	if self.status != STATUS.DEAD:
		for i in range(0,needs.size()):
			balances[i] = balances[i] - needs[i]
			hint_tooltip = "Type: " + type + ", Need: " + str(needs) + ", Greed: " + str(greeds) + ", Current: " + str(balances) + ", Money: " + str(money)
			if balances[i] < 0:
				balances[i] = 0
				self.set_status(STATUS.DEAD)

func set_status(new_status):
	status = new_status
	if new_status == STATUS.ALIVE:
		self.modulate = Color(1,1,1)
	elif new_status == STATUS.DEAD:
		self.modulate = Color(1,0,0)

func select(select = false):
	if select:
		if status == STATUS.ALIVE:
			self.modulate = Color(1,1,1,.5)
		elif STATUS.DEAD:
			self.modulate = Color(1,0,0,.25)
	else:
		if status == STATUS.ALIVE:
			self.modulate = Color(1,1,1,1)
		elif STATUS.DEAD:
			self.modulate = Color(1,0,0,1)