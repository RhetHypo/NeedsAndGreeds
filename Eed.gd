extends TextureRect

export var needs = []
export var greeds = []
export var balances = []
export var money = 0
#export var volatility = 1
export var type = "None"

var rng = RandomNumberGenerator.new()

var status = STATUS.ALIVE

enum STATUS {ALIVE, DEAD}

func _ready():
	rng.randomize()

func init(set_need, set_greed, set_type):
	needs = set_need.duplicate()
	greeds = set_greed.duplicate()
	#volatility = set_vol
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
			if vol_mod > 0:
				print("VOL: ", vol_mod)
			self.balances[i] = self.balances[i] + self.greeds[i] + vol_mod
	#survive()

func tax(index, volatility = 0, partial = 0):
	if status != STATUS.DEAD:
		var vol_mod = rng.randi_range(-volatility, volatility)
		if vol_mod > 0:
			print("VOL: ", vol_mod)
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

func sell(index, price, waste):
	var profit = balances[index] - needs[index]
	profit = profit * int(float(100-waste)/100)
	if profit > 0:
		money += profit * price
		balances[index] -= profit
		return profit
	return 0

func survive():
	if self.status != STATUS.DEAD:
		for i in range(0,needs.size()):
			balances[i] = balances[i] - needs[i]
			hint_tooltip = "Type: " + type + ", Need: " + str(needs) + ", Greed: " + str(greeds) + ", Current: " + str(balances)
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