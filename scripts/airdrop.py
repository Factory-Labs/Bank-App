from brownie.convert import to_address
from brownie import *
from collections import Counter
from time import sleep, time

amount = 0.0000001
amt = int(amount * 1e18)
print("Amount: {} amt: {}".format(amount, amt))
# amount_str = "{} ether".format(str(amount))
# amount = 1

check_contracts = False

def read_address_file(filepath):
    good_addrs = []
    bad_addrs = []
    duplicates = 0
    contracts = 0
    already_seen = set()
    with open(filepath, 'r') as f:
        for line in f.readlines():
            line = line.replace('\n', '')
            try:
                if line in already_seen:
                    print('Not including duplicate: {}'.format(line))
                    duplicates += 1
                    continue
                checksum = to_address(line)
                if check_contracts and len(web3.eth.getCode(checksum)) > 0:
                    print('Not supporting contracts {}'.format(line))
                    contracts += 1
                    continue
                good_addrs.append(line)
            except Exception as e:
                print(e)
                bad_addrs.append(line)
            already_seen.add(line)

    print("# Bad addrs: {}".format(len(bad_addrs)))
    print("# Good addrs: {}".format(len(good_addrs)))
    print("# Duplicates: {}".format(duplicates))
    print("# Contracts: {}".format(contracts))

    total_cost = amount * len(good_addrs)
    print("Total cost to send {} ether to each: {} ether".format(amount, total_cost))
    balance = web3.eth.getBalance(accounts[0])
    print("Your wallet balance: {}".format(balance))
    if balance < total_cost * 1.001:
        print("Aborting, not enough funds")
    else:
        response = ''
        while response != 'n':
            response = input('Continue? y/n')
            if response == 'y':
                return good_addrs
    exit(0)


def send_funds(addresses):
    value = amt * len(addresses)
    while True:
        try:
#             print(addresses, value)
            tx = MultiSender[-1].multisend(addresses, amt, { "from": accounts[0], "required_confs": 0, "value": value })
            print("Sent tx {}".format(tx.txid))
            break
        except Exception as e:
            print('Encountered exception {}, retrying in 10 seconds'.format(e))
            sleep(10)
    return tx


def main():
    print(network)
    #     accounts.load()
    accounts.load("airdrop")
    print('Sending funds from {}'.format(accounts[0]))
    addrs = read_address_file('./data/airdrop.csv')

    start_time = time()
    step_size = 500
    txs = [
        send_funds(addrs[i: i+step_size])
        for i in range(0, len(addrs), step_size)
    ]
    end_time = time()
    print("Txs created in {} - {} = {} second".format(end_time, start_time, end_time - start_time))
    while True:
        status = [tx.status for tx in txs]
        freqs = Counter(status)
        print("Successful: {} Reverted: {} Pending: {} Dropped: {}".format(freqs[1], freqs[0], freqs[-1], freqs[-2]))
        if freqs[1] == len(txs):
            print("Complete!")
        if freqs[-1] == 0:
            print("All txs sent.")
            completed = [tx.txid for tx in txs if tx.status == 1]
            reverted = [tx.txid for tx in txs if tx.status == 0]
            dropped = [tx.txid for tx in txs if tx.status == -2]
            t = str(int(time()))
            with open('./data/output/completed-txs-{}.csv'.format(t), 'w') as f:
                f.writelines('\n'.join(completed))
            with open('./data/output/reverted-txs-{}.csv'.format(t), 'w') as f:
                f.writelines('\n'.join(reverted))
            with open('./data/output/dropped-txs-{}.csv'.format(t), 'w') as f:
                f.writelines('\n'.join(dropped))
            break
        sleep(5)