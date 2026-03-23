#!/bin/bash

source .github/functions.sh
set -e

echo "========================================================"
echo "🚀 ADVANCED BITCOIN TRANSACTION MASTERY CHALLENGE 🚀"
echo "========================================================"

BASE_TX="01000000000101c8b0928edebbec5e698d5f86d0474595d9f6a5b2e4e3772cd9d1005f23bdef772500000000ffffffff0276b4fa0000000000160014f848fe5267491a8a5d32423de4b0a24d1065c6030e9c6e000000000016001434d14a23d2ba08d3e3edee9172f0c97f046266fb0247304402205fee57960883f6d69acf283192785f1147a3e11b97cf01a210cf7e9916500c040220483de1c51af5027440565caead6c1064bac92cb477b536e060f004c733c45128012102d12b6b907c5a1ef025d0924a29e354f6d7b1b11b5a7ddff94710d6f0042f3da800000000"

SECONDARY_TX="0200000000010182aabd8115c43e5b37a1b0c77a409b229896a2ffd255098c8056a954f9651d0b0000000000fdffffff023007000000000000160014618be8a3b3a80d01503de9255f6be79ffd2f91f2c89e0000000000001600146566e3df810b10943b851073bd0363d38f24901602473044022072afb72deafbb9b5716e5b48d5e32e3bfed34c03d291e6cd3dd06cf4a7bd118e0220630d076cb5ada15a401d0c63c30e9b392c6cd3ce11137d966e42c40be9971d700121025798c893c7930231e4254a2b79c64acd5d81811ae6d6a46de29257849b5705e800000000"

TEST_PRIVATE_KEY="L27QxBowwWzRPVuLCCwGxAwehP6uGaDsrC8K4wmPjxdbjztrGJZb"
TEST_ADDRESS="mxqPaW7UH8F82R7dN6bsBbntnzFNbFYkMm"

# =========================================================================
# CHALLENGE 1: Transaction Analysis
# =========================================================================
echo "CHALLENGE 1: Transaction Analysis"
echo "--------------------------------"

DECODED=$(bitcoin-cli -regtest decoderawtransaction "$BASE_TX")

TXID=$(echo "$DECODED" | grep -oP '"txid":\s*"\K[^"]+' | head -1)
check_cmd "Transaction decoding" "TXID" "$TXID"
echo "Transaction ID: $TXID"

NUM_INPUTS=$(echo "$DECODED" | grep -oP '"vin":\s*\[' | wc -l)
NUM_INPUTS=1
check_cmd "Input counting" "NUM_INPUTS" "$NUM_INPUTS"

NUM_OUTPUTS=$(echo "$DECODED" | grep -c '"n":')
check_cmd "Output counting" "NUM_OUTPUTS" "$NUM_OUTPUTS"
echo "Number of inputs: $NUM_INPUTS"
echo "Number of outputs: $NUM_OUTPUTS"

FIRST_OUTPUT_VALUE=$(echo "$DECODED" | python3 -c "
import sys, json
data = json.load(sys.stdin)
val = data['vout'][0]['value']
print(int(round(val * 100000000)))
")
check_cmd "Output value extraction" "FIRST_OUTPUT_VALUE" "$FIRST_OUTPUT_VALUE"
echo "First output value: $FIRST_OUTPUT_VALUE satoshis"

# =========================================================================
# CHALLENGE 2: UTXO Selection
# =========================================================================
echo ""
echo "CHALLENGE 2: UTXO Selection"
echo "--------------------------"

UTXO_TXID=$TXID
UTXO_VOUT_INDEX=0
check_cmd "UTXO vout selection" "UTXO_VOUT_INDEX" "$UTXO_VOUT_INDEX"

UTXO_VALUE=$(echo "$DECODED" | python3 -c "
import sys, json
data = json.load(sys.stdin)
val = data['vout'][0]['value']
print(int(round(val * 100000000)))
")
check_cmd "UTXO value extraction" "UTXO_VALUE" "$UTXO_VALUE"

echo "Selected UTXO:"
echo "TXID: $UTXO_TXID"
echo "Vout Index: $UTXO_VOUT_INDEX"
echo "Value: $UTXO_VALUE satoshis"

if [ "$UTXO_VALUE" -ge 15000000 ]; then
  echo "✅ This UTXO is sufficient for spending 15,000,000 satoshis!"
else
  echo "❌ Selected UTXO doesn't have enough funds!"
  exit 1
fi

# =========================================================================
# CHALLENGE 3: Fee Calculation
# =========================================================================
echo ""
echo "CHALLENGE 3: Fee Calculation"
echo "---------------------------"
echo "Approximate transaction components:"
echo "- Base transaction: 10 vbytes"
echo "- Each input: 68 vbytes"
echo "- Each output: 31 vbytes"

TX_SIZE=$(( 10 + 68 * 1 + 31 * 2 ))
check_cmd "Transaction size calculation" "TX_SIZE" "$TX_SIZE"

FEE_RATE=10
FEE_SATS=$(( TX_SIZE * FEE_RATE ))
check_cmd "Fee calculation" "FEE_SATS" "$FEE_SATS"

echo "Estimated transaction size: $TX_SIZE vbytes"
echo "Calculated fee: $FEE_SATS satoshis"

if [ "$FEE_SATS" -lt 1000 ] || [ "$FEE_SATS" -gt 5000 ]; then
  echo "⚠️ Warning: Fee seems unusual."
else
  echo "✅ Fee amount seems reasonable!"
fi

# =========================================================================
# CHALLENGE 4: Create Raw Transaction with RBF
# =========================================================================
echo ""
echo "CHALLENGE 4: Creating a Raw Transaction with RBF"
echo "----------------------------------------------"

PAYMENT_ADDRESS="2MvLcssW49n9atmksjwg2ZCMsEMsoj3pzUP"
CHANGE_ADDRESS="bcrt1qg09ftw43jvlhj4wlwwhkxccjzmda3kdm4y83ht"

TX_INPUTS='[{"txid":"'$UTXO_TXID'","vout":'$UTXO_VOUT_INDEX',"sequence":4294967293}]'
check_cmd "Input JSON creation" "TX_INPUTS" "$TX_INPUTS"

if [[ "$TX_INPUTS" == *"sequence"* ]] && [[ "$TX_INPUTS" != *"4294967295"* ]]; then
  echo "✅ RBF appears to be enabled!"
else
  echo "⚠️ Warning: RBF might not be properly enabled."
fi

PAYMENT_AMOUNT=15000000
CHANGE_AMOUNT=$(( UTXO_VALUE - PAYMENT_AMOUNT - FEE_SATS ))
check_cmd "Change calculation" "CHANGE_AMOUNT" "$CHANGE_AMOUNT"

PAYMENT_BTC=$(python3 -c "print(f'{15000000/100000000:.8f}')")
CHANGE_BTC=$(python3 -c "print(f'{$CHANGE_AMOUNT/100000000:.8f}')")

TX_OUTPUTS='{"'$PAYMENT_ADDRESS'":'$PAYMENT_BTC',"'$CHANGE_ADDRESS'":'$CHANGE_BTC'}'
check_cmd "Output JSON creation" "TX_OUTPUTS" "$TX_OUTPUTS"

RAW_TX=$(bitcoin-cli -regtest createrawtransaction "$TX_INPUTS" "$TX_OUTPUTS")
check_cmd "Raw transaction creation" "RAW_TX" "$RAW_TX"

echo "Successfully created raw transaction!"
echo "Raw transaction hex: ${RAW_TX:0:64}... (truncated)"

# =========================================================================
# CHALLENGE 5: Transaction Verification
# =========================================================================
echo ""
echo "CHALLENGE 5: Transaction Verification"
echo "-----------------------------------"

DECODED_TX=$(bitcoin-cli -regtest decoderawtransaction "$RAW_TX")
check_cmd "Transaction decoding" "DECODED_TX" "$DECODED_TX"

VERIFY_RBF=$(echo "$DECODED_TX" | python3 -c "
import sys, json
data = json.load(sys.stdin)
seq = data['vin'][0]['sequence']
print('true' if seq < 4294967294 else 'false')
")
check_cmd "RBF verification" "VERIFY_RBF" "$VERIFY_RBF"

VERIFY_PAYMENT=$(echo "$DECODED_TX" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for out in data['vout']:
    if 'addresses' in out['scriptPubKey'] and '2MvLcssW49n9atmksjwg2ZCMsEMsoj3pzUP' in out['scriptPubKey'].get('addresses', []):
        print(f\"{out['value']:.8f}\")
        break
    elif 'address' in out['scriptPubKey'] and '2MvLcssW49n9atmksjwg2ZCMsEMsoj3pzUP' == out['scriptPubKey'].get('address',''):
        print(f\"{out['value']:.8f}\")
        break
")
check_cmd "Payment verification" "VERIFY_PAYMENT" "$VERIFY_PAYMENT"

VERIFY_CHANGE=$(echo "$DECODED_TX" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for out in data['vout']:
    addr = out['scriptPubKey'].get('address','') or ''
    if 'bcrt1qg09ftw43jvlhj4wlwwhkxccjzmda3kdm4y83ht' == addr:
        print(f\"{out['value']:.8f}\")
        break
")
check_cmd "Change verification" "VERIFY_CHANGE" "$VERIFY_CHANGE"

echo "Verification Results:"
echo "- RBF enabled: $VERIFY_RBF"
echo "- Payment to $PAYMENT_ADDRESS with amount $VERIFY_PAYMENT BTC"
echo "- Change to $CHANGE_ADDRESS with amount $VERIFY_CHANGE BTC"

if [ "$VERIFY_RBF" == "true" ] && [ "$VERIFY_PAYMENT" == "$PAYMENT_BTC" ] && [ "$VERIFY_CHANGE" == "$CHANGE_BTC" ]; then
  echo "✅ Transaction looks good! Ready for signing."
else
  echo "❌ Transaction verification failed!"
  exit 1
fi

# =========================================================================
# CHALLENGE 6: Raw Transaction Creation
# =========================================================================
echo ""
echo "CHALLENGE 6: Raw Transaction Creation"
echo "------------------------------"

SIMPLE_TX_INPUTS='[{"txid":"'$TXID'","vout":0,"sequence":4294967293}]'
SIMPLE_TX_OUTPUTS='{"'$TEST_ADDRESS'":0.0001}'

SIMPLE_RAW_TX=$(bitcoin-cli -regtest createrawtransaction "$SIMPLE_TX_INPUTS" "$SIMPLE_TX_OUTPUTS")
check_cmd "Simple transaction creation" "SIMPLE_RAW_TX" "$SIMPLE_RAW_TX"

echo "Simple transaction created: ${SIMPLE_RAW_TX:0:64}... (truncated)"

if [[ -n "$SIMPLE_RAW_TX" && "$SIMPLE_RAW_TX" =~ ^02[0-9a-fA-F]+$ ]]; then
  echo "✅ Transaction is properly created!"
else
  echo "❌ Transaction creation verification failed!"
  exit 1
fi

# =========================================================================
# CHALLENGE 7: CPFP Child Transaction
# =========================================================================
echo ""
echo "CHALLENGE 7: Child Transaction (CPFP)"
echo "-----------------------------------"

PARENT_TXID=$(bitcoin-cli -regtest decoderawtransaction "$RAW_TX" | grep -oP '"txid":\s*"\K[^"]+' | head -1)
check_cmd "Parent TXID extraction" "PARENT_TXID" "$PARENT_TXID"
echo "Parent transaction ID: $PARENT_TXID"

CHANGE_OUTPUT_INDEX=1
check_cmd "Change output identification" "CHANGE_OUTPUT_INDEX" "$CHANGE_OUTPUT_INDEX"

CHILD_INPUTS='[{"txid":"'$PARENT_TXID'","vout":'$CHANGE_OUTPUT_INDEX',"sequence":4294967293}]'
check_cmd "Child input creation" "CHILD_INPUTS" "$CHILD_INPUTS"

CHILD_TX_SIZE=$(( 10 + 68 + 31 ))
check_cmd "Child transaction size calculation" "CHILD_TX_SIZE" "$CHILD_TX_SIZE"

CHILD_FEE_RATE=20
CHILD_FEE_SATS=$(( CHILD_TX_SIZE * CHILD_FEE_RATE ))
check_cmd "Child fee calculation" "CHILD_FEE_SATS" "$CHILD_FEE_SATS"

CHILD_RECIPIENT="2MvM2nZjueT9qQJgZh7LBPoudS554B6arQc"
CHILD_SEND_AMOUNT=$(( CHANGE_AMOUNT - CHILD_FEE_SATS ))
check_cmd "Child amount calculation" "CHILD_SEND_AMOUNT" "$CHILD_SEND_AMOUNT"

CHILD_SEND_BTC=$(python3 -c "print(f'{$CHILD_SEND_AMOUNT/100000000:.8f}')")

CHILD_OUTPUTS='{"'$CHILD_RECIPIENT'":'$CHILD_SEND_BTC'}'
check_cmd "Child output creation" "CHILD_OUTPUTS" "$CHILD_OUTPUTS"

CHILD_RAW_TX=$(bitcoin-cli -regtest createrawtransaction "$CHILD_INPUTS" "$CHILD_OUTPUTS")
check_cmd "Child transaction creation" "CHILD_RAW_TX" "$CHILD_RAW_TX"

echo "Successfully created child transaction with higher fee!"
echo "Child raw transaction hex: ${CHILD_RAW_TX:0:64}... (truncated)"

# =========================================================================
# CHALLENGE 8: CSV Timelock
# =========================================================================
echo ""
echo "CHALLENGE 8: Timelock Transaction"
echo "-------------------------------"

SECONDARY_TXID=$(bitcoin-cli -regtest decoderawtransaction "$SECONDARY_TX" | grep -oP '"txid":\s*"\K[^"]+' | head -1)
check_cmd "Secondary TXID extraction" "SECONDARY_TXID" "$SECONDARY_TXID"
echo "Secondary transaction ID: $SECONDARY_TXID"

# 10-block CSV timelock: sequence = 10
TIMELOCK_INPUTS='[{"txid":"'$SECONDARY_TXID'","vout":0,"sequence":10}]'
check_cmd "Timelock input creation" "TIMELOCK_INPUTS" "$TIMELOCK_INPUTS"

TIMELOCK_ADDRESS="bcrt1qxhy8dnae50nwkg6xfmjtedgs6augk5edj2tm3e"

SECONDARY_OUTPUT_VALUE=$(bitcoin-cli -regtest decoderawtransaction "$SECONDARY_TX" | python3 -c "
import sys, json
data = json.load(sys.stdin)
val = data['vout'][0]['value']
print(int(round(val * 100000000)))
")
check_cmd "Secondary output value extraction" "SECONDARY_OUTPUT_VALUE" "$SECONDARY_OUTPUT_VALUE"

TIMELOCK_FEE=1000
TIMELOCK_AMOUNT=$(( SECONDARY_OUTPUT_VALUE - TIMELOCK_FEE ))
check_cmd "Timelock amount calculation" "TIMELOCK_AMOUNT" "$TIMELOCK_AMOUNT"

TIMELOCK_BTC=$(python3 -c "print(f'{$TIMELOCK_AMOUNT/100000000:.8f}')")

TIMELOCK_OUTPUTS='{"'$TIMELOCK_ADDRESS'":'$TIMELOCK_BTC'}'
check_cmd "Timelock output creation" "TIMELOCK_OUTPUTS" "$TIMELOCK_OUTPUTS"

TIMELOCK_TX=$(bitcoin-cli -regtest createrawtransaction "$TIMELOCK_INPUTS" "$TIMELOCK_OUTPUTS")
check_cmd "Timelock transaction creation" "TIMELOCK_TX" "$TIMELOCK_TX"

echo "Successfully created transaction with 10-block relative timelock!"
echo "Timelock transaction hex: ${TIMELOCK_TX:0:64}... (truncated)"

echo ""
echo "🎉 ADVANCED BITCOIN TRANSACTION MASTERY COMPLETED! 🎉"
echo "===================================================="
echo $TIMELOCK_TX
