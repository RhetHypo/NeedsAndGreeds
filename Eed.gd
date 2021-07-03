extends TextureRect

export var needs = []
export var greeds = []
export var balances = []
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
	hint_tooltip = "Type: " + type + ", Need: " + str(needs) + ", Greed: " + str(greeds) + ", Current: " + str(balances)
	set_status(STATUS.ALIVE)

func work(volatility = 0):
	for i in needs.size():
		if status != STATUS.DEAD:
			self.balances[i] = self.balances[i] + self.greeds[i] + rng.randi_range(-volatility, volatility)
	survive()

func tax(index, volatility = 0, partial = 0):
	for i in range(0,needs.size()-1):
		if status != STATUS.DEAD:
			self.balances[i] = self.balances[i] + self.greeds[i]
			if partial != 0:
				if balances[i] > partial:
					var temp = partial
					balances[i] = balances[i] - partial
					return temp
				else:
					var temp = balances[i]
					balances[i] = 0
					return temp
			else:
				var temp = balances[i]
				balances[i] = 0
				return temp
		else:
			var temp = balances[i]
			balances[i] = 0
			return temp

func stim(partial,i):
	balances[i] = balances[i] + partial

func buy():
	pass

func sell():
	pass

func survive():
	for i in range(0,needs.size()-1):
		balances[i] = balances[i] - needs[i]
		hint_tooltip = "Type: " + type + ", Need: " + str(needs) + ", Greed: " + str(greeds) + ", Current: " + str(balances)
		if balances[i] < 0 and self.status != STATUS.DEAD:
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