#!/bin/bash
bitcoin-cli -regtest createwallet "btrustwallet" 2>/dev/null \
  || bitcoin-cli -regtest loadwallet "btrustwallet"
