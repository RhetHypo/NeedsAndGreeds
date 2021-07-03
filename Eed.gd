extends TextureRect

export var need = 1
export var greed = 1
export var balance = 5
#export var volatility = 1
export var type = "None"

var rng = RandomNumberGenerator.new()

var status = STATUS.ALIVE

enum STATUS {ALIVE, DEAD}

func _ready():
	rng.randomize()

func init(set_need, set_greed, set_type):
	need = set_need
	greed = set_greed
	#volatility = set_vol
	balance = 0
	type = set_type
	hint_tooltip = "Type: " + type + ", Need: " + str(need) + ", Greed: " + str(greed) + ", Current: " + str(balance)
	set_status(STATUS.ALIVE)

func work(volatility = 0):
	if status != STATUS.DEAD:
		self.balance = self.balance + self.greed + rng.randi_range(-volatility, volatility)
		survive()

func tax(volatility = 0, partial = 0):
	if status != STATUS.DEAD:
		self.balance = self.balance + self.greed
	if partial != 0:
		if balance > partial:
			var temp = partial
			balance = balance - partial
			return temp
		else:
			var temp = balance
			balance = 0
			return temp
	else:
		var temp = balance
		balance = 0
		return temp

func stim(partial):
	balance = balance + partial

func survive():
	balance = balance - need
	hint_tooltip = "Type: " + type + ", Need: " + str(need) + ", Greed: " + str(greed) + ", Current: " + str(balance)
	if balance < 0:
		balance = 0
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