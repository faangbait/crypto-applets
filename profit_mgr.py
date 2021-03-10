#!/usr/bin/python3

#{'id': '31e1e1bcf3417b37586b0801d7a98d2346c9f30e', 'coin': 'ETH', 'name': 'Ethereum', 'type': 'coin',
#'algorithm': 'Ethash', 'network_hashrate': 409215469352615, 'difficulty': 5271420406384171,
#'reward': 2.9261840839941e-12, 'reward_unit': 'ETH', 'reward_block': 4.2847629147786, 'price': 2016.43637518, 'volume': 29443526968.141, 'updated': 1613793383}

import requests
import json
import sys

ELECTRIC_COST_PER_KWH=0.029
WATTS_CONSUMED=140
MEGAHASH_RATE=50
FEES=.02
SAFETY_FACTOR=2
RUN_IF_SAFE_PROFIT_GREATER_THAN=0.05

r = requests.get("https://api.minerstat.com/v2/coins", params={'list':'ETH'})
current = r.json()[0]

reward_per_hour = current.get("reward")*MEGAHASH_RATE*1000*1000
print(f"Per Hour: {reward_per_hour} {current.get('reward_unit')}")

usd_per_hour = reward_per_hour*current.get("price")
print(f"Per Hour: {usd_per_hour} USD")
print(f"Per Day: {usd_per_hour*24} USD")

pool_fee = usd_per_hour*FEES
print(f"Pool/Dev Fee: {pool_fee} USD")

electric_cost = ELECTRIC_COST_PER_KWH*(WATTS_CONSUMED/1000) # Cost per KwH * KwH Consumed
print(f"Elec Cost: {electric_cost} per Hour")
print(f"Elec Cost: {electric_cost*24*30.5} per Month")

print(f"Actual Profit = {usd_per_hour-pool_fee-electric_cost} USD")
print(f"Monthly Profit = {24*30.5*(usd_per_hour-pool_fee-electric_cost)} USD")

safe_profit = ((1-FEES)*(reward_per_hour*(current.get('price')))/SAFETY_FACTOR)-electric_cost

print(f"Profit if ETH was to 1/{SAFETY_FACTOR} = {safe_profit*24*30.5} USD/mo")

print(f"RUN? {safe_profit > RUN_IF_SAFE_PROFIT_GREATER_THAN}")

if safe_profit > RUN_IF_SAFE_PROFIT_GREATER_THAN:
    sys.exit(0)
else:
    sys.exit(1)
