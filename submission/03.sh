#!/bin/bash
# Create segwit address
SEGWIT_ADDR=$(bitcoin-cli -regtest -rpcwallet=btrustwallet getnewaddress "segwit" "bech32")

# Fund it by mining to it
bitcoin-cli -regtest generatetoaddress 101 $SEGWIT_ADDR > /dev/null 2>&1

# Return only the address
echo $SEGWIT_ADDR
