## ERC-20 TOKEN STANDARD TRANSFER PROPERTIES 
| ID               | Name                                                                                                                                                           | Property definition                                                            |
| --------------   | -------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| ERC20-STDPROP-01 | [prove_transfer](https://github.com/joaovaladares/tcc-hevm-smart-contracts/blob/main/test/OpenZeppelinERC20.t.sol#L43)                                         | Non-self `transfer` succeeds if the `msg.receiver` is not the zero address, the `amt` sent is not higher than the balance of the `msg.sender` and it doesn't result in an overflow on the `msg.receiver`'s balance|
| ERC20-STDPROP-02 | [prove_transferToSelf](https://github.com/joaovaladares/tcc-hevm-smart-contracts/blob/main/test/OpenZeppelinERC20.t.sol#L67)                                   | Self `transfer` calls succeeds if the `amt` sent is not higher than the balance of the `msg.sender` |
| ERC20-STDPROP-03 | [prove_transferCorrectAmount](https://github.com/joaovaladares/tcc-hevm-smart-contracts/blob/main/test/OpenZeppelinERC20.t.sol#L88)                            | Successful non-self `transfer` calls should send the correct `amt` to the `msg.receiver` address and deduct the same `amt` for the `msg.sender`|
| ERC20-STDPROP-04 | [prove_transferSelfCorrectAmount](https://github.com/joaovaladares/tcc-hevm-smart-contracts/blob/main/test/OpenZeppelinERC20.t.sol#L113)                       | Successful self `transfer` calls should send the correct `amt` to the `msg.receiver` address and deduct the same `amt` for the `msg.sender` (here since the sender and receiver is the same the idea is that the `balance` remains the same)|
| ERC20-STDPROP-05 | [prove_transferChangeState](https://github.com/joaovaladares/tcc-hevm-smart-contracts/blob/main/test/OpenZeppelinERC20.t.sol#L136)                             | Any `transfer` call should not have any unexpected state changes on non-revert calls |
| ERC20-STDPROP-06 | [prove_transferZeroAmount](https://github.com/joaovaladares/tcc-hevm-smart-contracts/blob/main/test/OpenZeppelinERC20.t.sol#L177)                              | Zero amount `transfer` calls should not break accounting                       |
| ERC20-STDPROP-07 | [prove_transferFalseNoStateChange](https://github.com/joaovaladares/tcc-hevm-smart-contracts/blob/main/test/OpenZeppelinERC20.t.sol#L200)                      | If a contract allows false return to sinalize a fail call to `transfer`, all the states should remain the same before and after the call |
| ERC20-STDPROP-08 | [prove_transferToZeroAddressReverts](https://github.com/joaovaladares/tcc-hevm-smart-contracts/blob/main/test/OpenZeppelinERC20.t.sol#L222)                    | Any `transfer` call to the Zero Address should fail and revert                 |
| ERC20-STDPROP-09 | [prove_transferNotEnoughBalanceReverts](https://github.com/joaovaladares/tcc-hevm-smart-contracts/blob/main/test/OpenZeppelinERC20.t.sol#L246)                 | Any `transfer` call for more than account balance should revert.               |
| ERC20-STDPROP-10 | [prove_transferOverflowReceiverReverts](https://github.com/joaovaladares/tcc-hevm-smart-contracts/blob/main/test/OpenZeppelinERC20.t.sol#L269)                 | Overflow should not happen on `msg.receiver` balance                           |
| ERC20-STDPROP-11 | [prove_transferNeverReturnsFalse](https://github.com/joaovaladares/tcc-hevm-smart-contracts/blob/main/test/OpenZeppelinERC20.t.sol#L303)                       | `transfer`s should not return false to indicate a failure, instead it should revert |