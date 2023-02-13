There are many contracts here, all regarding distributing fungible crypto assets to many addresses.

To use the airdrop script, 
- put a single column CSV of addresses into `data/airdrop.csv`
- if you haven't already, run `brownie accounts generate airdrop` to generate a wallet with the name 'airdrop'
- fund your wallet
- from the terminal, navigate to the repository root director and run `brownie run ./scripts/airdrop.py --network ????` filling in your desired network
- you will be prompted for the password to decrypt your wallet with the name 'airdrop'
