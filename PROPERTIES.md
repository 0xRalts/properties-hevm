# ERC-20 Token Standard Properties

## transfer properties

| ID | NAME | PROPERTY DEFINITION |
|----|------|---------------------|
| ERC20-STDPROP-01|[prove_transfer](https://github.com/0xRalts/properties-hevm/blob/main/test/ERC20PropertiesTest.t.sol#L41)| `transfer` succeeds if `receiver` is not the zero address, the `amount` on `sender` is enough and doesn't overflow `receiver`'s balance |
|ERC20-STDPROP-02 |[prove_transferToSelf](https://github.com/0xRalts/properties-hevm/blob/main/test/ERC20PropertiesTest.t.sol#L65)| self-`transfer`s succeeds if `amount` does not exceeds `sender`'s balance |
| ERC20-STDPROP-03 | [prove_transferCorrectAmount](https://github.com/0xRalts/properties-hevm/blob/main/test/ERC20PropertiesTest.t.sol#L86) | non-self succesful `transfer` calls should correctly handle the `amount` on `sender` and `receiver` |
| ERC20-STDPROP-04 | [prove_transferSelfCorrectAmount](https://github.com/0xRalts/properties-hevm/blob/main/test/ERC20PropertiesTest.t.sol#L114) | self-`transfer` calls should not break accounting |
| ERC20-STDPROP-05 | [prove_transferChangeState](https://github.com/0xRalts/properties-hevm/blob/main/test/ERC20PropertiesTest.t.sol#L137) | `transfer` should not have any unexpected state changes on non-revert calls |
| ERC20-STDPROP-06 | [prove_transferZeroAmount](https://github.com/0xRalts/properties-hevm/blob/main/test/ERC20PropertiesTest.t.sol#L178) | successful zero `amount` `transfer` calls should not break accounting |
| ERC20-STDPROP-07 | [prove_transferToZeroAddressReverts](https://github.com/0xRalts/properties-hevm/blob/main/test/ERC20PropertiesTest.t.sol#L198) | any `transfer` call to the zero address should fail and revert. |
| ERC20-STDPROP-08 | [prove_transferNotEnoughBalanceReverts](https://github.com/0xRalts/properties-hevm/blob/main/test/ERC20PropertiesTest.t.sol#L221) | `transfer` should fail and revert if account balance is lowers than total `amount` trying to be sent|
| ERC20-STDPROP-09 | [prove_transferOverflowReceiverReverts](https://github.com/0xRalts/properties-hevm/blob/main/test/ERC20PropertiesTest.t.sol#L245) | `transfer` should prevent overflow on `receiver` and revert |
| ERC20-STDPROP-10 | [prove_transferNeverReturnsFalse](https://github.com/0xRalts/properties-hevm/blob/main/test/ERC20PropertiesTest.t.sol#L283) | `transfer` should not return false on failure, it should revert instead |
| ERC20-STDPROP-11 | [prove_transferSuccessReturnsTrue](https://github.com/0xRalts/properties-hevm/blob/main/test/ERC20PropertiesTest.t.sol#L302) | `transfer`  calls returns `true` to indicate it succeeded | 

## transferFrom properties
| ID | NAME | PROPERTY DEFINITION |
|----|------|---------------------|
| ERC20-STDPROP-12 | [prove_transferFrom](https://github.com/0xRalts/properties-hevm/blob/main/test/ERC20PropertiesTest.t.sol#L334) | `transferFrom` calls should update accounting accordingly when succeeding |
| ERC20-STDPROP-13 | [prove_transferFromToSelf](https://github.com/0xRalts/properties-hevm/blob/main/test/ERC20PropertiesTest.t.sol#L371) | a call where `from` and `to` address are the same on `transferFrom` should not break accounting | 
| ERC20-STDPROP-14 | [prove_transferFromCorrectAmount](https://github.com/0xRalts/properties-hevm/blob/main/test/ERC20PropertiesTest.t.sol#L411) | non-self `transferFrom` calls sends the correct `amount` |
| ERC20-STDPROP-15 | [prove_transferFromToSelfCorrectAmount](https://github.com/0xRalts/properties-hevm/blob/main/test/ERC20PropertiesTest.t.sol#L447) | self `transferFrom` calls send the correct `amount` (meaning balance won't change) |
| ERC20-STDPROP-16 | [prove_transferFromChangeState](https://github.com/0xRalts/properties-hevm/blob/main/test/ERC20PropertiesTest.t.sol#L484) | `transferFrom` should not have any unexpected state changes on non-revert calls |
| ERC20-STDPROP-17 | [prove_transferFromZeroAmount](https://github.com/0xRalts/properties-hevm/blob/main/test/ERC20PropertiesTest.t.sol#L525) | zero `amount` `transferFrom` calls should not break accounting |
| ERC20-STDPROP-18 | [prove_transferFromCorrectAllowance](https://github.com/0xRalts/properties-hevm/blob/main/test/ERC20PropertiesTest.t.sol#L556) | non-reverting `transferFrom` calls updates `allowance` correctly |
| ERC20-STDPROP-19 | [prove_transferFromToZeroAddressReverts](https://github.com/0xRalts/properties-hevm/blob/main/test/ERC20PropertiesTest.t.sol#L588) | all `transferFrom` calls to zero address should revert |
| ERC20-STDPROP-20 | [prove_transferFromNotEnoughBalanceReverts](https://github.com/0xRalts/properties-hevm/blob/main/test/ERC20PropertiesTest.t.sol#L618) | all `transferFrom` calls where `amount` is higher than the available `balance` should revert |
| ERC20-STDPROP-21 | [prove_transferFromNotEnoughAllowanceReverts](https://github.com/0xRalts/properties-hevm/blob/main/test/ERC20PropertiesTest.t.sol#L652) | all `transferFrom` calls where `amount` is higher than the `allowance` available should revert|
| ERC20-STDPROP-22 | [prove_transferFromOverflowReceiverReverts](https://github.com/0xRalts/properties-hevm/blob/main/test/ERC20PropertiesTest.t.sol#L688) | `transferFrom` should prevent overflow on the receiver |
| ERC20-STDPROP-23 | [prove_transferFromNeverReturnsFalse](https://github.com/0xRalts/properties-hevm/blob/main/test/ERC20PropertiesTest.t.sol#L733) | `transferFrom` should not return false on failure, it should revert instead |
| ERC20-STDPROP-24 | [prove_transferFromSuccessReturnsTrue](https://github.com/0xRalts/properties-hevm/blob/main/test/ERC20PropertiesTest.t.sol#L754) | `transferFrom` calls returns `true` to indicate it succeeded |

## approve properties
| ID | NAME | PROPERTY DEFINITION |
|----|------|---------------------|
| ERC20-STDPROP-25 | [prove_approve](https://github.com/0xRalts/properties-hevm/blob/main/test/ERC20PropertiesTest.t.sol#L784) | `approve` should succeed if the `spender` is not the zero address and `amount` approved is higher than 0 |
| ERC20-STDPROP-26 | [prove_approveCorrectAmount](https://github.com/0xRalts/properties-hevm/blob/main/test/ERC20PropertiesTest.t.sol#L805) | non-reverting `approve` calls should update `allowance` correctly |
| ERC20-STDPROP-27 | [prove_approveCorrectAmountTwice](https://github.com/0xRalts/properties-hevm/blob/main/test/ERC20PropertiesTest.t.sol#L822) | any number of non-reverting `approve` calls should update `allowance` correctly |
| ERC20-STDPROP-28 | [prove_approveDoesNotChangeState](https://github.com/0xRalts/properties-hevm/blob/main/test/ERC20PropertiesTest.t.sol#L849) | any non-reverting `approve` call should not change the state of other variables |
| ERC20-STDPROP-29 | [prove_approveRevertZeroAddress](https://github.com/0xRalts/properties-hevm/blob/main/test/ERC20PropertiesTest.t.sol#L883) | any call to `approve` where `spender` is the zero address should revert |
| ERC20-STDPROP-30 | [prove_approveNeverReturnFalse](https://github.com/0xRalts/properties-hevm/blob/main/test/ERC20PropertiesTest.t.sol#L899) | `approve` should not return `false` to indicate that it failed |
| ERC20-STDPROP-31 | [prove_approveSuccessReturnsTrue](https://github.com/0xRalts/properties-hevm/blob/main/test/ERC20PropertiesTest.t.sol#L914) | `approve` should return `true` to indicate it succeeded |  
 