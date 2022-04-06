from defi_live_data import gremlins, defi_live_users, coins
from numpy.random import choice
import json

defi_live_pct = 0.2
gremlin_pct = 1 - defi_live_pct

total_coin_value = sum([coin['num_tokens'] * coin['price'] for coin in coins])
defi_live_pot = total_coin_value * defi_live_pct
gremlin_pot = total_coin_value - defi_live_pot
gremlin_share = gremlin_pot / len(gremlins)
defi_live_share = defi_live_pot / len(defi_live_users)

for coin in coins:
    coin['defi_live_allocation_tokens'] = defi_live_share / coin['price'] # usd / (usd / token) == token
    coin['gremlin_allocation_tokens'] = gremlin_share / coin['price']
    coin['recipients'] = []
    coin['total_usd_value'] = coin['num_tokens'] * coin['price']
    coin['remaining_amount'] = coin['num_tokens']

for defi_liver in defi_live_users:

    # for coin in coins:
    #     if coin['remaining_amount'] >= coin['defi_live_allocation_tokens']:
    #         coin['remaining_amount'] -= coin['defi_live_allocation_tokens']
    #         break
    while True:
        coin = choice(coins)
        if coin['remaining_amount'] >= coin['defi_live_allocation_tokens']:
            coin['remaining_amount'] -= coin['defi_live_allocation_tokens']
            break
    coin['recipients'].append({
        'recipient': defi_liver,
        'allocation': coin['defi_live_allocation_tokens'],
        'allocation_wei': coin['defi_live_allocation_tokens'] * 1e18
    })


for gremlin in gremlins:
    for coin in coins:
        if coin['remaining_amount'] >= coin['gremlin_allocation_tokens']:
            coin['remaining_amount'] -= coin['gremlin_allocation_tokens']
            break
    # while True:
    #     coin = choice(coins)
    #     if coin['remaining_amount'] >= coin['gremlin_allocation_tokens']:
    #         coin['remaining_amount'] -= coin['gremlin_allocation_tokens']
    #         break
    coin['recipients'].append({
        'recipient': gremlin,
        'allocation': coin['gremlin_allocation_tokens'],
        'allocation_wei': coin['gremlin_allocation_tokens'] * 1e18
    })


json.dump(coins, open('./distribution.json', 'w'), indent=4)
