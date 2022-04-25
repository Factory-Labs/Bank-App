from brownie import accounts, MerkleLib, MerkleDropFactory, MerkleResistor, MerkleVesting


def main():
    acct = accounts.load('mgmt')
    MerkleLib.deploy({'from': acct})
    MerkleDropFactory.deploy({'from': acct})
    MerkleVesting.deploy({'from': acct})
    MerkleResistor.deploy({'from': acct})


def publish_source():
    MerkleLib.publish_source(MerkleLib[-1])
    MerkleDropFactory.publish_source(MerkleDropFactory[-1])
    MerkleVesting.publish_source(MerkleVesting[-1])
    MerkleResistor.publish_source(MerkleResistor[-1])