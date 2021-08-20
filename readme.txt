Here is some basic documentation of what does what. As far as I know this should all be up to date, and

Buttons:
	Reset: Resets the simulation to starting parameters. This was originally very important, but most of the run functions call it implicitly, so it’s somewhat vestigial at this point.
	*Run Standard: Runs the standard simulation. Phases are produce, sell, buy, then survive.
	*Run Pooled: Runs the pooled simulation. Phases are produce, tax, stim, then survive.
	*Run charity: Runs an alternate standard simulation that includes a charity scheme that donates a configurable excess currency for others that need resources to be able to pull from.
	Reset Stats: All stats are generated before hand, and maintained for all runs and between resets. This will reshuffle them, and clear out the result log. Use this after making changes to any of the parameters. (some parameters don’t require a stat reset to take effect… I still recommend a stat reset)
	Pause: Can pause the simulation. Mostly useful for debugging.
	Stop: Option to abandon a currently running simulation.
	Run Batch: Runes a batch of simulations using the settings config file, batch section

* I use standard, pooled, and charity to better describe these as apolitical, and governed solely by logic. Capitalism and communism very much have a political aspect to them, and we are not concerned with that in this analysis.

Amplifiers:
	Need: Multiplies the consumption value of each Eed, known as Need.
	Max Frugality: The threshold for how frugal an Eed can be, which is weighted by available values
	Min Frugality: The threshold for how unfrugal an Eed can be, which is weighted by available values
	Greed: Multiplies the production value of each Eed, known as Greed.
	Spec: A multiplier to production that only applies to Specialists
	Waste%: Percentage of resources lost during a transaction. Applied in tax phase for pooled, and the sell phase for standard.
	Realism%: When realism is active, the percentage to which needs are raised for high producers.
Variables:
	Standard: Total number of standard type Eeds. They have a moderate range of values for both Need and Greed.
	Poverty: The number of poor type Eeds. Greed is somewhere between zero and deviation divided by the greed amplifier.
	Wealthy: The number of rich type Eeds. Greed is somewhere between the value of deviation and need times the greed amplifier.
	Specialists: The number of specialist type Eeds. A single type of greed is placed somewhere between the value of deviation and deviation times the greed amplifier, times the spec amplifier. All other greeds use the same formula for poor type Eeds.
	Crash %: How likely a crash is to occur for each Eed during a turn, which prevents production.
	Turns: Number of turns the simulation runs before stopping and producing results.
	Volatility: Potential random variation in production, which can be both positive and negative.
	Deviation: A baseline that sets scale for both needs and greeds.
	Diversity: The number of different types of needs and greeds.
	Charity: The percentage of available resources that are donated in charity mode
Batch Mode: Reduces wait time between turns when on
Slow mode: Shows the simulation iterating through each Eed. This isn’t particularly useful beyond debugging, similar to the pause functionality, but I left it in anyways.
Realism: This toggles the realism mode, which both applies waste and the realism percent markup to needs above the specified threshold.
Run Modes:
	Normal: Runs for the set number of turns, then produces results.
	Apocalypse: Runs for the set number of turns, then ends production and runs until all resources run out. 
	Utopia: Everything is fine.
Results:
	Clear Results: Button to clear results lists.
	There is a separate column for each economic system, to easily compare results. Most recent run will move towards top. 