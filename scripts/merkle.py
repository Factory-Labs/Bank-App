from merkle import createMerkleTree
from glob import glob
import pandas as pd
import json

csvs = glob('./scripts/*.csv')

merkle_roots = []

for csv in csvs:
    df = pd.read_csv(csv)
    j = json.loads(df.to_json(orient='records'))
    for x in j:
        x['allocation_wei'] = int(x['allocation_wei'])
    m = createMerkleTree(j, ['address', 'uint256'], ['recipient', 'allocation_wei'])
    merkle_roots.append(m['root'])

print(merkle_roots)