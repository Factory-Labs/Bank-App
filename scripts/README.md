There are many contracts here, all regarding distributing fungible crypto assets to many addresses.

To use the airdrop script, 
- put a single column CSV of addresses into `data/airdrop.csv`
- if you haven't already, run `brownie accounts generate airdrop` to generate a wallet with the name 'airdrop'
- fund your wallet
- add the network you want, e.g. `brownie networks add ethereum palm-mainnet host=https://palm-mainnet.public.blastapi.io chainid=11297108109`
- from the terminal, navigate to the repository root director and run `brownie run ./scripts/airdrop.py --network palm-mainnet` filling in your desired network
- you will be prompted for the password to decrypt your wallet with the name 'airdrop'

Each transaction will send the same amount to up to 500 addresses. If the airdrop gets into an infinite loop at some point because it is failing, hit Ctrl+C to exit. Probably one of the addresses was a contract. 
- Remove the addresses you already sent crypto to from the csv
- Change line 12 in scripts/airdrop.py to `check_contracts = True`
- Rerun the script, it will take longer now because it is checking each address to see if it is a contract
- It will tell you how many contracts there were, you can continue and it will skip them
- You can set line 12 back to `check_contracts = False` for next time

