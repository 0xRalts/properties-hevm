// SPDX-License-Identifier: MIT

/** 
*   @dev
*   This file is meant to implement the tests for 
*   OpenZeppelin's ERC20 token standard implementation
*   in order to show that it satisfies the properties
*   defined for our research. 
*   Those properties will be listed out in a README.md
*   in the 'test/' folder of this repository, please notice
*   that it's not possible yet to have many properties tested
*   because of time limit of my part.
*/

pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {OpenZeppelinERC20} from "src/OpenZeppelinERC20.sol";
import "test/PropertiesHelper.sol";

contract OpenZeppelinERC20Test is Test, PropertiesAsserts {
    OpenZeppelinERC20 token;

    function setUp() public {
        token = new OpenZeppelinERC20(); 
    }

    /**********************************************************************************************/
    /*                                                                                            */
    /*                            TRANSFER FUNCTION PROPERTIES                                    */
    /*                                                                                            */
    /**********************************************************************************************/

    /** 
    *  @dev
    *  property ERC20-STDPROP-01 implementation
    *
    *  transfer succeeds if the following conditions are met:
    *  - the 'to' address is not the zero address
    *  - amount does not exceed the balance of msg.sender (address(this)) 
    *  - transfering amount to 'to' address does not results in a overflow  
    */  
    function prove_transfer(uint256 supply, address to, uint256 amount) public {
        require(to != address(0));
        token._mint(address(this), supply);
        require(amount <= token.balanceOf(address(this)));
        require(token.balanceOf(to) + amount < type(uint256).max); //no overflow on receiver
        
        uint256 prebal = token.balanceOf(to);
        bool success = token.transfer(to, amount);
        uint256 postbal = token.balanceOf(to);

        uint256 expected = to == address(this)
                        ? 0     // no self transfer allowed here
                        : amount;  // otherwise amount has been transfered to to
        assertTrue(expected == postbal - prebal, "Incorrect expected value returned");
        assertTrue(success, "Transfer function failed");
    } 

    /** 
    *  @dev
    *  property ERC20-STDPROP-02 implementation
    *
    *  transfer can succeed in self transfers if the following is met:
    *  - amount does not exceeds the balance of msg.sender (address(this))
    */
    function prove_transferToSelf(uint256 amount) public {
        require(amount > 0);
        token._mint(address(this), amount);
        uint256 prebal = token.balanceOf(address(this));
        require(prebal >= amount);

        bool success = token.transfer(address(this), amount);

        uint256 postbal = token.balanceOf(address(this));
        assertEq(prebal, postbal, "Value of prebal and postbal doesn't match");
        assertTrue(success, "Self transfer failed");
    }

    /** 
    *  @dev
    *  property ERC20-STDPROP-03 implementation
    *
    *  transfer should send the correct amount in Non-self transfers:
    *  - if a transfer call returns true (doesn't revert), it must subtract the value 'amount'
    *  - from the msg.sender and add that same value to the 'to' address
    */ 
    function prove_transferCorrectAmount(address to, uint256 amount) public {
        require(amount > 1);
        require(to != msg.sender);
        require(to != address(0));
        require(msg.sender != address(0));
        token._mint(msg.sender, amount);
        uint256 prebalSender = token.balanceOf(msg.sender);
        uint256 prebalReceiver = token.balanceOf(to);
        require(prebalSender > 0);

        bool success = token.transfer(to, amount);
        uint256 postbalSender = token.balanceOf(msg.sender);
        uint256 postbalReceiver = token.balanceOf(to);

        assert(postbalSender == prebalSender - amount);
        assert(postbalReceiver == prebalReceiver + amount);
        assert(success);
    }

    /** 
    *  @dev
    *  property ERC20-STDPROP-04 implementation
    *
    *  transfer should send correct amount in self-transfers:
    *  - if a self-transfer call returns true (doesn't revert), it must subtract the value 'amount'
    *  - from the msg.sender and add that same value to the 'to' address
    */ 
    function prove_transferSelfCorrectAmount(uint256 amount) public {
        require(amount > 1);
        require(amount != UINT256_MAX);
        token._mint(address(this), amount);
        uint256 prebalSender = token.balanceOf(address(this));
        require(prebalSender > 0);

        bool success = token.transfer(address(this), amount);
        uint256 postbalSender = token.balanceOf(address(this));

        assertTrue(postbalSender == prebalSender);
        assertTrue(success);
    }

    /** 
    *  @dev
    *  property ERC20-STDPROP-05 implementation
    *
    *  transfer should not have any unexpected state changes on non-revert calls as follows:
    *  - must only modify the balance of msg.sender (caller) and the address 'to' the transfer is being made 
    *  - any other state e.g. allowance, totalSupply, balances of an address not involved in the transfer call
    *  - should not change 
    */ 
    function prove_transferChangeState(address to, uint256 amount) public {
        require(amount > 0);
        require(to != address(0));
        require(to != msg.sender);
        require(msg.sender != address(0));
        token._mint(msg.sender, amount);
        require(token.balanceOf(msg.sender) > 0);

        //Create an address that is not involved in the transfer call
        address addr = address(bytes20(keccak256(abi.encode(block.timestamp))));
        require(addr != address(0));
        require(addr != msg.sender);
        require(addr != to);
        token._mint(addr, amount);

        uint256 initialSupply = token.totalSupply();
        uint256 senderInitialBalance = token.balanceOf(msg.sender);
        uint256 receiverInitialBalance = token.balanceOf(to);

        uint256 addrInitialBalance = token.balanceOf(addr);
        uint256 allowanceForAddr = 100;
        token.approve(addr, allowanceForAddr);
        uint256 addrInitialAllowance = token.allowance(address(this), addr);
        
        bool success = token.transfer(to, amount);
        require(success, "Transfer failed!");

        assert(token.balanceOf(msg.sender) == senderInitialBalance - amount);
        assert(token.balanceOf(to) == receiverInitialBalance + amount);

        assert(token.totalSupply() == initialSupply);
        assert(token.balanceOf(addr) == addrInitialBalance);
        assert(token.allowance(address(this), addr) == addrInitialAllowance);
    }

    /** 
    *  @dev
    *  property ERC20-STDPROP-06 implementation
    *
    *  zero amount transfer should not break accounting
    */ 
    function prove_transferZeroAmount(address usr) public {
        token._mint(address(this), 1);
        token._mint(usr, 2);
        uint256 balanceSender = token.balanceOf(address(this));
        uint256 balanceReceiver = token.balanceOf(usr);
        require(balanceSender > 0);

        bool success = token.transfer(usr, 0);
        assert(success);
        assert(token.balanceOf(address(this)) == balanceSender);
        assert(token.balanceOf(usr) == balanceReceiver);
    }

    /** 
    *  @dev
    *  property ERC20-STDPROP-07 implementation
    *
    *  any transfer call to address 0 should fail and revert.
    */ 
    function prove_transferToZeroAddressReverts(uint256 supply, uint256 amount) public {   
        require(supply > 0);
        require(amount > 0);
        token._mint(address(this), supply);
        require(amount <= supply);
        uint256 prebal = token.balanceOf(address(this));

        bytes memory payload = abi.encodeWithSignature("transfer(address,uint256)", address(0), amount);
        (bool success, bytes memory returnData) = address(token).call(payload);
        require(success);

        // if it doesn't revert on the transfer call, test will fail because prebal != postbal
        bool transferReturn = abi.decode(returnData, (bool));
        uint256 postbal = token.balanceOf(address(this));
        assert(prebal == postbal);
        assert(!transferReturn); //gotta figure out what to do here
    }

    /** 
    *  @dev
    *  property ERC20-STDPROP-08 implementation
    *
    *  transfer should fail and revert if account balance is lower than the total amount
    *  trying to be sent.
    */ 
    function prove_transferNotEnoughBalanceReverts(address to, uint256 amount) public {
        require(amount > 1);
        require(amount <= UINT256_MAX);
        token._mint(msg.sender, amount - 1);
        uint256 prebal = token.balanceOf(msg.sender);
        require(prebal >= 0);

        bytes memory payload = abi.encodeWithSignature("transfer(address,uint256)", to, amount);
        (bool success, bytes memory returnData) = address(token).call(payload);
        require(success);

        bool transferReturn = abi.decode(returnData, (bool));
        uint256 postbal = token.balanceOf(msg.sender);
        assert(!transferReturn);
        assert(prebal == postbal);
    }

    /** 
    *  @dev
    *  property ERC20-STDPROP-09 implementation
    *
    *  transfer should prevent overflow on the receiver
    */ 
    function prove_transferOverflowReceiverReverts(address to, uint256 amount) public {
        require(msg.sender != to);
        require(to != address(0));
        require(amount > 0);
        token._mint(msg.sender, amount);
        token._mint(to, amount);
        uint256 oldReceiverBalance = token.balanceOf(to);
        uint256 oldSenderBalance = token.balanceOf(msg.sender);
        require(amount <= oldSenderBalance);
        require(oldReceiverBalance >= 0);
        require(oldReceiverBalance <= UINT256_MAX);
        require(oldSenderBalance <= UINT256_MAX);
        require((oldReceiverBalance + amount) < oldReceiverBalance); //overflow

        bytes memory payload = abi.encodeWithSignature("transfer(address,uint256)", to, amount);
        (bool success, bytes memory returnData) = address(token).call(payload);
        require(success);

        bool transferReturn = abi.decode(returnData, (bool));
        uint256 receiverBalance = token.balanceOf(to);
        uint256 senderBalance = token.balanceOf(msg.sender);
        assert(oldSenderBalance == senderBalance);
        assert(oldReceiverBalance == receiverBalance);
        assert(!transferReturn);
    }

    /** 
    *  @dev
    *  property ERC20-STDPROP-10 implementation
    *  transfer should not return false on failure, instead it should revert
    *
    *  in the implementation below, we supose that the token implementation doesn't allow
    *  transfer with amount higher than the (balanceOf(address(this)) will be equal to supply)
    S*   
    *  NOTE: this might not be the best way to handle this property since we can't be
    *        sure which requirement will cause the call to fail, open to suggestions
    */ 
    function prove_transferNeverReturnsFalse(address to, uint256 amount) public {
        token._mint(msg.sender, amount - 1);
        require(amount > token.balanceOf(msg.sender));

        bytes memory payload = abi.encodeWithSignature("transfer(address,uint256)", to, amount);
        (bool success, bytes memory returnData) = address(token).call(payload);
        require(success);

        bool transferReturn = abi.decode(returnData, (bool));
        assert(transferReturn); //not the best way to do it, but if it returns false it fails
    }


    /**********************************************************************************************/
    /*                                                                                            */
    /*                        TRANSFERFROM FUNCTION PROPERTIES                                    */
    /*                                                                                            */
    /**********************************************************************************************/

    /** 
    *  @dev
    *  property ERC20-STDPROP-11 implementation
    *
    *  transferFrom should update accounting accordingly when succeeding
    *
    *  Non-self transfers transferFrom calls must succeed and return true if
    *  - amount does not exceed the balance of address from
    *  - amount does not exceed allowance of msg.sender for address from
    */ 
    function prove_transferFromSucceedsNormal(address from, address to, uint256 amount) public {
        require(from != address(0));
        require(to != address(0));
        require(from != to);
        require(amount > 0);
        require(amount != type(uint256).max);
        token._mint(from, amount);
        uint256 initialFromBalance = token.balanceOf(from);
        require(initialFromBalance >= amount);

        token.approve(msg.sender, amount);
        uint256 initialAllowance = token.allowance(from, msg.sender);
        require(initialAllowance >= amount);

        uint256 initialToBalance = token.balanceOf(to);
        require(initialToBalance + amount >= initialToBalance);

        bytes memory payload = abi.encodeWithSignature("transferFrom(address,address,uint256)", from, to, amount);
        (bool success, bytes memory returnData) = address(token).call(payload);
        require(success);

        bool transferReturn = abi.decode(returnData, (bool));
        assert(transferReturn);

        assert(token.balanceOf(from) == initialFromBalance - amount);
        assert(token.balanceOf(to) == initialToBalance + amount);
    }

    /** 
    *  @dev
    *  property ERC20-STDPROP-12 implementation
    *
    *  Self transfers should not break accounting
    *
    *  All self transferFrom calls must succeed and return true if:
    *  - amount does not exceed the balance of address from
    *  - amount does not exceed the allowance of msg.sender for address from
    */ 
    function prove_transferFromToSelf(address from, address to, uint256 amount) public {
        require(from != address(0));
        require(from == to);
        require(amount > 0);
        require(amount != type(uint256).max);

        token._mint(from, amount);
        uint256 initialFromBalance = token.balanceOf(from);
        require(initialFromBalance > 0);

        uint256 initialToBalance = token.balanceOf(to);

        token.approve(msg.sender, amount);
        uint256 fromAllowance = token.allowance(from, msg.sender);
        require(fromAllowance >= amount);

        bool success = token.transferFrom(from, to, amount);
        require(success);

        uint256 newFromBalance = token.balanceOf(from);
        uint256 newToBalance = token.balanceOf(to);

        assert(newFromBalance == initialFromBalance);
        assert(newToBalance == initialToBalance);
    }

    /** 
    *  @dev
    *  property ERC20-STDPROP-13 implementation
    *
    *  Non-self transferFrom calls transfers the correct amount
    *
    *  All non-self transferFrom calls that succeed and return true do the following:
    *  - reduces exactly 'amount' from the balance of address from
    *  - adds exactly 'amount' to the balance of address to
    */ 
    function prove_transferFromCorrectAmount(address from, address to, uint256 amount) public {
        require(from != to);
        require(amount >= 0);
        token._mint(from, amount);

        uint256 initialFromBalance = token.balanceOf(from);
        require(initialFromBalance >= 0);
        require(initialFromBalance != type(uint256).max);

        uint256 initialToBalance = token.balanceOf(to);
        require(initialToBalance >= 0);
        require(initialToBalance + amount > initialToBalance);

        token.approve(msg.sender, amount);
        uint256 initialFromAllowance = token.allowance(from, msg.sender);
        require(initialFromAllowance > 0); 

        bytes memory payload = abi.encodeWithSignature("transferFrom(address,address,uint256)", from, to, amount);
        (bool success, bytes memory returnData) = address(token).call(payload);
        require(success);

        bool transferReturn = abi.decode(returnData, (bool));
        assert(transferReturn);
        assert(token.balanceOf(from) == initialFromBalance - amount);
        assert(token.balanceOf(to) == initialToBalance + amount); 
    }

    /** 
    *  @dev
    *  property ERC20-STDPROP-14 implementation
    *
    *  self transferFrom calls transfers the correct amount
    *
    *  All self transferFrom calls that succeed and return true do not change the balance
    *  of the 'from' address which is the same at the 'to' address
    */ 
    function prove_transferFromToSelfCorrectAmount(address from, address to, uint256 amount) public {
        require(from == to);
        require(amount >= 0);
        require(amount != type(uint256).max);

        token._mint(from, amount);
        uint256 fromInitialBalance = token.balanceOf(from);
        require(fromInitialBalance >= 0);
        require(fromInitialBalance < type(uint256).max);
        require(fromInitialBalance + amount >= fromInitialBalance);

        token.approve(msg.sender, amount);
        require(token.allowance(from, msg.sender) > 0);
        require(token.allowance(from, msg.sender) >= amount);

        bytes memory payload = abi.encodeWithSignature("transferFrom(address,address,uint256)", from, to, amount);
        (bool success, bytes memory returnData) = address(token).call(payload);
        require(success);

        bool transferReturn = abi.decode(returnData, (bool));
        assert(transferReturn);
        assert(token.balanceOf(from) == fromInitialBalance);
        assert(token.balanceOf(to) == token.balanceOf(from));
    }

    /** 
    *  @dev
    *  property ERC20-STDPROP-15 implementation
    *
    *  transferFrom calls doesn't change state unexpectedly.
    *
    *  All non-reverting calls of transferFrom(from, to, amount) that succeeds
    *  should only modify the following:
    *  - balance of address 'to'
    *  - balance of address 'from'
    *  - allowance from 'msg.sender' for the address 'from'
    */ 
    function prove_transferFromChangeState(address to, uint256 amount) public {
        address unrelatedAddress = address(0x1);
        require(to != msg.sender);
        require(to != address(this));
        require(to != address(0));
        require(to != unrelatedAddress);
        require(msg.sender != unrelatedAddress);
        require(msg.sender != address(0));
        require(amount > 0);
        require(amount != UINT256_MAX);

        token._mint(msg.sender, amount);
        token.approve(msg.sender, amount);
        
        uint256 initialSenderBalance = token.balanceOf(msg.sender);
        uint256 initialToBalance = token.balanceOf(to);
        uint256 initialUnrelatedBalance = token.balanceOf(unrelatedAddress);
        uint256 initialSupply = token.totalSupply();
        uint256 initialAllowance = token.allowance(msg.sender, address(this));
        
        require(initialSenderBalance > 0 && initialAllowance >= initialSenderBalance);

        bool success = token.transferFrom(msg.sender, to, amount);
        require(success, "TransferFrom failed");

        // Assert expected state changes
        assert(token.balanceOf(msg.sender) == initialSenderBalance - amount);
        assert(token.balanceOf(to) == initialToBalance + amount);
        assert(token.allowance(msg.sender, address(this)) == initialAllowance - amount);

        // Assert no unexpected state changes
        assert(token.balanceOf(unrelatedAddress) == initialUnrelatedBalance);
        assert(token.totalSupply() == initialSupply);
    }

    /** 
    *  @dev
    *  property ERC20-STDPROP-16 implementation
    *
    *  zero amount transferFrom calls should not break accounting
    */ 
    function prove_transferFromZeroAmount(address from, address to) public {
        require(from != address(0));
        require(to != address(0));
        require(from != to);

        token._mint(from, 100);
        uint256 initialFromBalance = token.balanceOf(from);
        require(initialFromBalance > 0);

        uint256 initialToBalance = token.balanceOf(to);

        token.approve(msg.sender, 100);
        uint256 fromAllowance = token.allowance(from, msg.sender);
        require(fromAllowance >= 0);

        bool success = token.transferFrom(from, to, 0);
        assert(success);

        assert(token.balanceOf(from) == initialFromBalance);
        assert(token.balanceOf(to) == initialToBalance);
    }

    /** 
    *  @dev
    *  property ERC20-STDPROP-17 implementation
    *
    *  All non-reverting transferFrom calls updates allowance correctly
    */ 
    function prove_transferFromCorrectAllowance(address from, address to, uint256 amount) public {
        require(amount >= 0);
        require(amount != UINT256_MAX);

        token._mint(from, amount);
        uint256 fromBalance = token.balanceOf(from);
        require(fromBalance >= 0);
        require(fromBalance < UINT256_MAX);
        uint256 toBalance = token.balanceOf(to);
        require(toBalance >= 0);
        require(toBalance < UINT256_MAX);

        token.approve(msg.sender, amount);
        uint256 allowance = token.allowance(from, msg.sender);
        require(allowance >= amount);
        require(allowance < UINT256_MAX);

        bytes memory payload = abi.encodeWithSignature("transferFrom(address,address,uint256)", from, to, amount);
        (bool success, bytes memory returnData) = address(token).call(payload);
        require(success);

        bool transferReturn = abi.decode(returnData, (bool));
        assert(transferReturn);
        assert(token.allowance(from, msg.sender) == allowance - amount);
    }

    /** 
    *  @dev
    *  property ERC20-STDPROP-18 implementation
    *
    *  All transferFrom calls to zero address should revert
    */ 
    function prove_transferFromToZeroAddressReverts(uint256 amount) public {
        require(amount > 1);
        token._mint(msg.sender, amount);
        token.approve(msg.sender, amount);
        uint256 initialSenderBalance = token.balanceOf(msg.sender);
        uint256 initialSenderAllowance = token.allowance(msg.sender, address(this));
        
        require(initialSenderBalance > 0 && initialSenderAllowance >= amount);
        uint256 maxValue = initialSenderBalance >= initialSenderAllowance
                        ? initialSenderAllowance
                        : initialSenderBalance;

        bytes memory payload = abi.encodeWithSignature("transferFrom(address,address,uint256)", msg.sender, address(0), maxValue);
        (bool success, bytes memory returnData) = address(token).call(payload);
        require(success);

        bool transferReturn = abi.decode(returnData, (bool));
        assert(!transferReturn);  
        assert(token.balanceOf(msg.sender) == initialSenderBalance);
    }

    /** 
    *  @dev
    *  property ERC20-STDPROP-19 implementation
    *
    *  All transferFrom calls where balance is higher than the available should revert
    */ 
    function prove_transferFromNotEnoughBalanceReverts(address to, uint256 amount) public {
        require(amount > 0);
        require(to != msg.sender);
        require(to != address(this));
        require(to != address(0));

        token._mint(msg.sender, amount);
        token.approve(msg.sender, amount + 1);

        uint256 senderBalance = token.balanceOf(msg.sender);
        uint256 senderAllowance = token.allowance(msg.sender, address(this));
        uint256 toBalance = token.balanceOf(to);

        require(senderBalance > 0 && senderAllowance > senderBalance);

        bytes memory payload = abi.encodeWithSignature("transferFrom(address,address,uint256)", msg.sender, to, senderBalance + 1);
        (bool success, bytes memory returnData) = address(token).call(payload);
        require(success);

        bool transferReturn = abi.decode(returnData, (bool));
        assert(!transferReturn);
        assert(token.balanceOf(msg.sender) == senderBalance);
        assert(token.balanceOf(to) == toBalance);
    }

    /** 
    *  @dev
    *  property ERC20-STDPROP-20 implementation
    *
    *  All transferFrom calls where amount is higher than the allowance available should revert
    */ 
    function prove_transferFromNotEnoughAllowanceReverts(address to, uint256 amount) public {
        require(amount > 0);
        require(amount != UINT256_MAX);
        require(to != msg.sender);
        require(to != address(this));
        require(to != address(0));

        token._mint(msg.sender, amount);
        token.approve(msg.sender, amount - 1);

        uint256 senderBalance = token.balanceOf(msg.sender);
        uint256 senderAllowance = token.allowance(msg.sender, address(this));
        uint256 toBalance = token.balanceOf(to);

        require(senderBalance > 0 && amount > senderAllowance);

        bytes memory payload = abi.encodeWithSignature("transferFrom(address,address,uint256)", msg.sender, to, amount);
        (bool success, bytes memory returnData) = address(token).call(payload);
        require(success);

        bool transferReturn = abi.decode(returnData, (bool));
        assert(!transferReturn);
        assert(token.balanceOf(msg.sender) == senderBalance);
        assert(token.balanceOf(to) == toBalance);
        assert(token.allowance(msg.sender, address(this)) == senderAllowance);
    }

    /** 
    *  @dev
    *  property ERC20-STDPROP-21 implementation
    *
    *  transfer should prevent overflow on the receiver
    */ 
    function prove_transferFromOverflowReceiverReverts(address to, uint256 amount) public {
        require(to != msg.sender);
        require(to != address(0));
        require(to != address(this));
        require(amount > 0);

        token._mint(msg.sender, amount);
        token.approve(msg.sender, amount);
        token._mint(to, amount);
        uint256 initialToBalance = token.balanceOf(to);
        uint256 initialSenderBalance = token.balanceOf(msg.sender);

        require(amount <= initialSenderBalance);
        require(initialToBalance >= 0);
        require(initialToBalance <= UINT256_MAX);
        require(initialSenderBalance <= UINT256_MAX);
        require((initialToBalance + amount) < initialToBalance); //overflow

        bytes memory payload = abi.encodeWithSignature("transferFrom(address,address,uint256)", msg.sender, to, amount);
        (bool success, bytes memory returnData) = address(token).call(payload);
        require(success);

        bool transferReturn = abi.decode(returnData, (bool));
        uint256 toBalance = token.balanceOf(to);
        uint256 senderBalance = token.balanceOf(msg.sender);
        assert(initialSenderBalance == senderBalance);
        assert(initialToBalance == toBalance);
        assert(!transferReturn);
    }

    /** 
    *  @dev
    *  property ERC20-STDPROP-22 implementation
    *
    *  transferFrom should not return false on failure, instead it should revert
    *
    *  in the implementation below, we suppose that the token implementation doesn't allow
    *  transferFrom with amount higher than the balance of msg.sender
    *
    *  NOTE: this might not be the best way to handle this property since we can't be
    *        sure which requirement will cause the call to fail, open to suggestions
    */ 
    function prove_transferFromNeverReturnsFalse(address to, uint256 amount) public {
        require(amount > 1);
        token._mint(msg.sender, amount);
        token.approve(msg.sender, amount);

        bytes memory payload = abi.encodeWithSignature("transferFrom(address,address,uint256)", msg.sender, to, amount + 1);
        (bool success, bytes memory returnData) = address(token).call(payload);
        require(success);

        bool transferReturn = abi.decode(returnData, (bool));
        assert(transferReturn);
    }
    

    /**********************************************************************************************/
    /*                                                                                            */
    /*                          TOTALSUPPLY FUNCTION PROPERTIES                                   */
    /*                                                                                            */
    /**********************************************************************************************/

    /** 
    *  @dev
    *  property ERC20-STDPROP-23 implementation
    *
    *  totalSupply calls should always succeed
    */
    function prove_totalSupplyAlwaysSucceeds() public {
        bytes memory payload = abi.encodeWithSignature("totalSupply()");
        (bool success, ) = address(token).call(payload);
        assert(success);
    }  

    /** 
    *  @dev
    *  property ERC20-STDPROP-24 implementation
    *
    *  totalSupply calls should not change state of variables
    */
    function prove_totalSupplyDoesNotChangeState(uint256 amount) public {
        token._mint(msg.sender, amount);
        token.approve(msg.sender, amount);

        uint256 initialTotalSupply = token.totalSupply();
        uint256 initialBalance = token.balanceOf(msg.sender);
        uint256 initialAllowance = token.allowance(msg.sender, address(this));

        token.totalSupply();

        assertTrue(token.totalSupply() == initialTotalSupply, "Total supply should not change");
        assertTrue(token.balanceOf(msg.sender) == initialBalance, "Balances should not change");
        assertTrue(token.allowance(msg.sender, address(this)) == initialAllowance, "Allowances should not change");
    }


    /**********************************************************************************************/
    /*                                                                                            */
    /*                            BALANCEOF FUNCTION PROPERTIES                                   */
    /*                                                                                            */
    /**********************************************************************************************/

    /** 
    *  @dev
    *  property ERC20-STDPROP-25 implementation
    *
    *  balanceOf calls should always succeeds
    */
    function prove_balanceOfAlwaysSucceeds(address account) public {
        bytes memory payload = abi.encodeWithSignature("balanceOf(address)", account);
        (bool success, ) = address(token).call(payload);
        assert(success);
    }  

    /** 
    *  @dev
    *  property ERC20-STDPROP-26 implementation
    *
    *  totalSupply calls should not change state of variables
    */
    function prove_balanceOfDoesNotChangeState(address account) public view {
        uint256 initialBalanceAccount = token.balanceOf(account);
        uint256 initialTotalSupply = token.totalSupply();
        uint256 initialBalance = token.balanceOf(msg.sender);
        uint256 initialAllowance = token.allowance(msg.sender, address(this));

        token.balanceOf(account);

        assert(token.balanceOf(account) == initialBalanceAccount);
        assert(token.totalSupply() == initialTotalSupply);
        assert(token.balanceOf(msg.sender) == initialBalance);
        assert(token.allowance(msg.sender, address(this)) == initialAllowance);
    }

    /** 
    *  @dev
    *  property ERC20-STDPROP-27 implementation
    *
    *  total balalnce of a user should not be higher than total supply
    */
    function prove_balanceOfUserNotHigherThanSupply(address user) public view {
        uint256 supply = token.totalSupply();
        uint256 userBalance = token.balanceOf(user);
        assert(userBalance <= supply);
    }

    /** 
    *  @dev
    *  property ERC20-STDPROP-28 implementation
    *
    *  total balance of zero address should be zero
    */
    function prove_balanceOfZeroAddress() public view {
        assert(token.balanceOf(address(0)) == 0);
    }


    /**********************************************************************************************/
    /*                                                                                            */
    /*                            ALLOWANCE FUNCTION PROPERTIES                                   */
    /*                                                                                            */
    /**********************************************************************************************/

    /** 
    *  @dev
    *  property ERC20-STDPROP-29 implementation
    *
    *  allowance calls should always succeeds
    */
    function prove_allowanceAlwaysSucceeds(address account) public {
        bytes memory payload = abi.encodeWithSignature("allowance(address,address)", msg.sender, account);
        (bool success, ) = address(token).call(payload);
        assert(success);
    }  

    /** 
    *  @dev
    *  property ERC20-STDPROP-30 implementation
    *
    *  totalSupply calls should not change state of variables
    */
    function prove_allowanceDoesNotChangeState(address account) public view {
        uint256 initialBalanceAccount = token.balanceOf(account);
        uint256 initialTotalSupply = token.totalSupply();
        uint256 initialBalance = token.balanceOf(msg.sender);
        uint256 initialAllowance = token.allowance(msg.sender, account);

        token.allowance(msg.sender, account);

        assert(token.balanceOf(account) == initialBalanceAccount);
        assert(token.totalSupply() == initialTotalSupply);
        assert(token.balanceOf(msg.sender) == initialBalance);
        assert(token.allowance(msg.sender, account) == initialAllowance);
    }


    /**********************************************************************************************/
    /*                                                                                            */
    /*                              APPROVE FUNCTION PROPERTIES                                   */
    /*                                                                                            */
    /**********************************************************************************************/

    /** 
    *  @dev
    *  property ERC20-STDPROP-31 implementation
    *
    *  approve calls should succeed if
    *  - the address in the spender parameter for approve(spender, amount) is not the zero address
    */
    function prove_approve(address account, uint256 amount) public {
        require(account != address(0));
        
        bytes memory payload = abi.encodeWithSignature("approve(address,uint256)", account, amount);
        (bool success, bytes memory returnData) = address(token).call(payload);
        assert(success);

        bool approveReturn = abi.decode(returnData, (bool));
        assert(approveReturn);
    }

    /** 
    *  @dev
    *  property ERC20-STDPROP-32 implementation
    *
    *  non-reverting approve calls should update allowance correctly
    */
    function prove_approveCorrectAmount(address account, uint256 amount) public {
        bytes memory payload = abi.encodeWithSignature("approve(address,uint256)", account, amount);
        (bool success, bytes memory returnData) = address(token).call(payload);
        require(success);

        bool approveReturn = abi.decode(returnData, (bool));
        assert(approveReturn); 
        assert(token.allowance(address(this), account) == amount);   
    }

    /** 
    *  @dev
    *  property ERC20-STDPROP-33 implementation
    *
    *  any number of non-reverting approve calls should update allowance correctly
    */
    function prove_approveCorrectAmountTwice(address account, uint256 amount) public {
        bytes memory payload = abi.encodeWithSignature("approve(address,uint256)", account, amount);
        (bool success, bytes memory returnData) = address(token).call(payload);
        require(success);

        bool approveReturn = abi.decode(returnData, (bool));
        assert(approveReturn); 
        assert(token.allowance(address(this), account) == amount);  

        payload = abi.encodeWithSignature("approve(address,uint256)", account, amount / 2);
        (success, returnData) = address(token).call(payload);
        require(success);

        approveReturn = abi.decode(returnData, (bool));
        assert(approveReturn); 
        assert(token.allowance(address(this), account) == amount / 2);  
    }

    /** 
    *  @dev
    *  property ERC20-STDPROP-34 implementation
    *
    *  any non-reverting approve call should 
    */
    function prove_approveDoesNotChangeState(address account, uint256 amount) public {
        address account2 = address(0x10000);
        address account3 = address(0x20000);
        require(account != account2);
        require(account != account3);
        require(account != msg.sender);
        require(account2 != account3);
        require(account2 != msg.sender);
        require(account3 != msg.sender);

        uint256 supply = token.totalSupply();
        uint256 account2Balance = token.balanceOf(account2);
        uint256 account3Balance = token.balanceOf(account3);
        uint256 allowances = token.allowance(account2, account3);

        bytes memory payload = abi.encodeWithSignature("approve(address,uint256)", account, amount);
        (bool success, bytes memory returnData) = address(token).call(payload);
        require(success);

        bool approveReturn = abi.decode(returnData, (bool)); 
        assert(approveReturn);

        assert(token.totalSupply() == supply);
        assert(token.balanceOf(account2) == account2Balance);
        assert(token.balanceOf(account3) == account3Balance);
        assert(token.allowance(account2, account3) == allowances);
    }

    /** 
    *  @dev
    *  property ERC20-STDPROP-35 implementation
    *
    *  any call to approve where spender is the zero address should revert
    */
    function proveFail_approveRevertZeroAddress(uint256 amount) public {
        bytes memory payload = abi.encodeWithSignature("approve(address,uint256)", address(0), amount);
        (bool success, bytes memory returnData) = address(token).call(payload);
        assert(success);

        bool approveReturn = abi.decode(returnData, (bool));
        assert(approveReturn);
    }

    /** 
    *  @dev
    *  property ERC20-STDPROP-36 implementation
    *
    *  approve should never return false on a fail call
    */
    function prove_approveNeverReturnFalse(address account, uint256 amount) public {
        bytes memory payload = abi.encodeWithSignature("approve(address,uint256)", account, amount);
        (bool success, bytes memory returnData) = address(token).call(payload);
        
        bool approveReturn = abi.decode(returnData, (bool));
        
        if(success) {
            assert(approveReturn);
        } else {
            assert(approveReturn);
        }
    }
}