#!/usr/bin/python3
"""
Displays a continuously-updating ticker for statistics related to Ethereum mining.
"""

import requests
import json
import sys, os
from time import sleep

ELECTRIC_COST_PER_KWH=0.029
WATTS_CONSUMED=140
MEGAHASH_RATE=46
FEES=.02

if True:
	try:
		r = requests.get("https://api.minerstat.com/v2/coins", params={'list':'ETH'})
		api_fetch = r.json()[0]

		"""
		Available keys in 'api_fetch':
		id			string		Unique identifier of the coin.
		coin			string		Coin's ticker.
		name			string		Coin's name.
		type			string		Coin's type. It can be coin or pool, where pool is multi pool, such as NiceHash, Zpool, etc.
		algorithm		string		Coin's algorithm.
		network_hashrate	integer	Coin's network hashrate in H/s. If coin has no data on network hashrate, the network hashrate is -1.
		difficulty		real		Coin's difficulty. If coin has no data on difficulty, the difficulty is -1.
		reward			real		Coin's reward for 1 H/s for 1 hour of mining based on the most current difficulty. If coin has no data on reward, the reward is -1.
		reward_unit		string		Coin's reward unit. If a coin is multi pool, the reward unit can be BTC or XMR or whichever reward is provided by the multi pool.
		reward_block		real		Coin's block reward. If coin has no data on the block's reward, the block's reward is -1.
		price			real		Coin's price in USD. If coin has no data on price, the price is -1.
		volume			real		Coin's last 24h volume in USD. If coin has no data on volume, the volume is -1.
		updated			integer		The UNIX timestamp of the last time the coin was updated.
		"""

		network_hashrate = api_fetch.get("network_hashrate")
		difficulty = api_fetch.get("difficulty")
		reward = api_fetch.get("reward")
		reward_block = api_fetch.get("reward_block")
		price = api_fetch.get("price")
		volume = api_fetch.get("volume")

	except Exception as e:
		print(f"Exception occurred while requesting current ETH price: {e}")

	eth_reward_per_hour = reward * MEGAHASH_RATE * 1000 * 1000
	usd_reward_per_hour = eth_reward_per_hour*price
	usd_reward_per_month = usd_reward_per_hour * 24 * 30.5
	electric_cost_per_month = ELECTRIC_COST_PER_KWH*(WATTS_CONSUMED/1000)*24*30.5
	usd_reward_per_month_less_costs = usd_reward_per_month - (usd_reward_per_month*FEES) - electric_cost_per_month

	print(f"${usd_reward_per_month:.2f}/mo\n---")
	print("Start Mining | bash='sudo /usr/bin/systemctl start cryptomining.service' terminal=false")
	print("Stop Mining | bash='sudo /usr/bin/systemctl stop cryptomining.service' terminal=false")
	print("---")
	print(f"ETH Price:\t\t${price:.2f}")
	print(f"Reward:\t\t{reward_block:.2f} ETH")
	print(f"Net Profit:\t\t${usd_reward_per_month_less_costs:.2f}/mo")

	# We divide the reward by the percentage of the block which are transaction fees.
	# e.g. A 4ETH block would be a 2ETH block after London, so we would slash our monthly profit by /2
	# e.g. A 6ETH block would be a 2ETH block after London, so we would slash our monthly profit by /3

	print(f"After London:\t${((usd_reward_per_month*(1-FEES))/(reward_block/2)) - electric_cost_per_month:.2f}/mo") 
	print("---")

	with open('/sys/class/drm/card0/device/hwmon/hwmon1/temp3_input','r') as gpu_temp_file:
		gpu_temp = int(gpu_temp_file.read())/1000

	with open('/sys/class/drm/card0/device/hwmon/hwmon1/fan1_input','r') as fan_speed_file:
		fan_speed = int(fan_speed_file.read())

	print(f"GPU Temp:\t\t{gpu_temp}C")
	print(f"Fan Speed:\t\t{fan_speed}rpm")
