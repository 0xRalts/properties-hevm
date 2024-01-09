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
    *  - amt does not exceed the balance of msg.sender (address(this)) 
    *  - transfering amt to 'to' address does not results in a overflow  
    */  
    function prove_transfer(uint256 supply, address to, uint256 amt) public {
        require(to != address(0));
        token._mint(address(this), supply);
        require(amt <= token.balanceOf(address(this)));
        require(token.balanceOf(to) + amt < type(uint256).max); //no overflow on receiver
        
        uint256 prebal = token.balanceOf(to);
        bool success = token.transfer(to, amt);
        uint256 postbal = token.balanceOf(to);

        uint256 expected = to == address(this)
                        ? 0     // no self transfer allowed here
                        : amt;  // otherwise amt has been transfered to to
        assertTrue(expected == postbal - prebal, "Incorrect expected value returned");
        assertTrue(success, "Transfer function failed");
    } 

    /** 
    *  @dev
    *  property ERC20-STDPROP-02 implementation
    *
    *  transfer can succeed in self transfers if the following is met:
    *  - amt does not exceeds the balance of msg.sender (address(this))
    */
    function prove_transferToSelf(uint256 amt) public {
        require(amt > 0);
        token._mint(address(this), amt);
        uint256 prebal = token.balanceOf(address(this));
        require(prebal >= amt);

        bool success = token.transfer(address(this), amt);

        uint256 postbal = token.balanceOf(address(this));
        assertEq(prebal, postbal, "Value of prebal and postbal doesn't match");
        assertTrue(success, "Self transfer failed");
    }

    /** 
    *  @dev
    *  property ERC20-STDPROP-03 implementation
    *
    *  transfer should send the correct amount in Non-self transfers:
    *  - if a transfer call returns true (doesn't revert), it must subtract the value 'amt'
    *  - from the msg.sender and add that same value to the 'to' address
    */ 
    function prove_transferCorrectAmount(address to, uint256 amt) public {
        require(amt > 1);
        require(to != address(this));
        token._mint(address(this), amt);
        uint256 prebalSender = token.balanceOf(address(this));
        uint256 prebalReceiver = token.balanceOf(to);
        require(prebalSender > 0);

        bool success = token.transfer(to, amt);
        uint256 postbalSender = token.balanceOf(address(this));
        uint256 postbalReceiver = token.balanceOf(to);

        assert(postbalSender == prebalSender - amt);
        assert(postbalReceiver == prebalReceiver + amt);
        assert(success);
    }

    /** 
    *  @dev
    *  property ERC20-STDPROP-04 implementation
    *
    *  transfer should send correct amount in self-transfers:
    *  - if a self-transfer call returns true (doesn't revert), it must subtract the value 'amt'
    *  - from the msg.sender and add that same value to the 'to' address
    */ 
    function prove_transferSelfCorrectAmount(uint256 amt) public {
        require(amt > 1);
        require(amt != UINT256_MAX);
        token._mint(address(this), amt);
        uint256 prebalSender = token.balanceOf(address(this));
        require(prebalSender > 0);

        bool success = token.transfer(address(this), amt);
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
    function prove_transferChangeState(address to, uint256 amt) public {
        require(amt > 0);
        require(to != address(0));
        require(to != msg.sender);
        require(msg.sender != address(0));
        token._mint(msg.sender, amt);
        require(token.balanceOf(msg.sender) > 0);

        //Create an address that is not involved in the transfer call
        address addr = address(bytes20(keccak256(abi.encode(block.timestamp))));
        require(addr != address(0));
        require(addr != msg.sender);
        require(addr != to);
        token._mint(addr, amt);

        uint256 initialSupply = token.totalSupply();
        uint256 senderInitialBalance = token.balanceOf(msg.sender);
        uint256 receiverInitialBalance = token.balanceOf(to);

        uint256 addrInitialBalance = token.balanceOf(addr);
        uint256 allowanceForAddr = 100;
        token.approve(addr, allowanceForAddr);
        uint256 addrInitialAllowance = token.allowance(address(this), addr);
        
        bool success = token.transfer(to, amt);
        require(success, "Transfer failed!");

        assert(token.balanceOf(msg.sender) == senderInitialBalance - amt);
        assert(token.balanceOf(to) == receiverInitialBalance + amt);

        assert(token.totalSupply() == initialSupply);
        assert(token.balanceOf(addr) == addrInitialBalance);
        assert(token.allowance(address(this), addr) == addrInitialAllowance);
    }

    // /** 
    // *  @dev
    // *  property ERC20-STDPROP-06 implementation
    // *
    // *  zero amount transfer should not break accounting
    // */ 
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
    *  if for some reason the contract allows transfer to return false we need to make sure
    *  that all the state variables are the same in the beginning and in the end
    *  this test is considered a PASS if it reverts all branches or if the state is maintained
    *  (OpenZeppelin would revert returning us a false FAIL) - thinking about making it a proveFail_
    *  test.
    */ 
    function prove_transferFalseNoStateChange(address to, uint256 amt) public {
        // Initial state capture
        token._mint(msg.sender, amt);
        uint256 amtPlusOne = amt + 1;
        uint256 senderInitialBalance = token.balanceOf(msg.sender);
        uint256 receiverInitialBalance = token.balanceOf(to);
        uint256 initialSupply = token.totalSupply();

        bytes memory payload = abi.encodeWithSignature("transfer(address,uint256)", to, amtPlusOne);
        (bool success, bytes memory returnData) = address(token).call(payload);
        bool transferReturn = abi.decode(returnData, (bool));
        require(success);
        require(!transferReturn);

        assert(token.balanceOf(msg.sender) == senderInitialBalance);
        assert(token.balanceOf(to) == receiverInitialBalance);
        assert(token.totalSupply() == initialSupply);
    }

    /** 
    *  @dev
    *  property ERC20-STDPROP-08 implementation
    *
    *  any transfer call to address 0 should fail and revert.
    */ 
    function prove_transferToZeroAddressReverts(uint256 supply, uint256 amt) public {   
        require(supply > 0);
        require(amt > 0);
        token._mint(address(this), supply);
        require(amt <= supply);
        uint256 prebal = token.balanceOf(address(this));

        bytes memory payload = abi.encodeWithSignature("transfer(address,uint256)", address(0), amt);
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
    *  property ERC20-STDPROP-09 implementation
    *
    *  transfer should fail and revert if account balance is lower than the total amt
    *  trying to be sent.
    */ 
    function prove_transferNotEnoughBalanceReverts(address to, uint256 amt) public {
        require(amt > 1);
        require(amt <= UINT256_MAX);
        token._mint(msg.sender, amt - 1);
        uint256 prebal = token.balanceOf(msg.sender);
        require(prebal >= 0);

        bytes memory payload = abi.encodeWithSignature("transfer(address,uint256)", to, amt);
        (bool success, bytes memory returnData) = address(token).call(payload);
        require(success);

        bool transferReturn = abi.decode(returnData, (bool));
        uint256 postbal = token.balanceOf(msg.sender);
        assert(!transferReturn);
        assert(prebal == postbal);
    }

    /** 
    *  @dev
    *  property ERC20-STDPROP-10 implementation
    *
    *  transfer should prevent overflow on the receiver
    */ 
    function prove_transferOverflowReceiverReverts(address to, uint256 amt) public {
        require(msg.sender != to);
        require(to != address(0));
        require(amt > 0);
        token._mint(msg.sender, amt);
        token._mint(to, amt);
        uint256 oldReceiverBalance = token.balanceOf(to);
        uint256 oldSenderBalance = token.balanceOf(msg.sender);
        require(amt <= oldSenderBalance);
        require(oldReceiverBalance >= 0);
        require(oldReceiverBalance <= UINT256_MAX);
        require(oldSenderBalance <= UINT256_MAX);
        require((oldReceiverBalance + amt) < oldReceiverBalance); //overflow

        bytes memory payload = abi.encodeWithSignature("transfer(address,uint256)", to, amt);
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
    *  property ERC20-STDPROP-11 implementation
    *  transfer should not return false on failure, instead it should revert
    *
    *  in the implementation below, we supose that the token implementation doesn't allow
    *  transfer with amt higher than the (balanceOf(address(this)) will be equal to supply)
    */ 
    function prove_transferNeverReturnsFalse(address to, uint256 amt) public {
        token._mint(msg.sender, amt - 1);
        require(amt > token.balanceOf(msg.sender));

        bytes memory payload = abi.encodeWithSignature("transfer(address,uint256)", to, amt);
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
    *  property ERC20-STDPROP-12 implementation
    *
    *  transferFrom should update accounting accordingly when succeeding
    *
    *  Non-self transfers transferFrom calls must succeed and return true if
    *  - amount does not exceed the balance of address from
    *  - amount does not exceed allowance of msg.sender for address from
    */ 
    function prove_transferFromSucceedsNormal(address from, address dest, uint256 amount) public {
        require(from != address(0));
        require(dest != address(0));
        require(from != dest);
        require(amount > 0);
        require(amount != type(uint256).max);
        token._mint(from, amount);
        uint256 initialFromBalance = token.balanceOf(from);
        require(initialFromBalance >= amount);

        token.approve(msg.sender, amount);
        uint256 initialAllowance = token.allowance(from, msg.sender);
        require(initialAllowance >= amount);

        uint256 initialDestBalance = token.balanceOf(dest);
        require(initialDestBalance + amount >= initialDestBalance);
        
        bytes memory payload = abi.encodeWithSignature("transferFrom(address,address,uint256)", from, dest, amount);
        (bool success, bytes memory returnData) = address(token).call(payload);
        require(success);

        bool transferReturn = abi.decode(returnData, (bool));
        assert(transferReturn);

        assert(token.balanceOf(from) == initialFromBalance - amount);
        assert(token.balanceOf(dest) == initialDestBalance + amount);
        assert(token.allowance(from, msg.sender) == initialAllowance - amount);
    }

    /** 
    *  @dev
    *  property ERC20-STDPROP-13 implementation
    *
    *  Self transfers should not break accounting
    *
    *  All self transferFrom calls must succeed and return true if:
    *  - amount does not exceed the balance of address from
    *  - amount does not exceed the allowance of msg.sender for address from
    */ 
    function prove_transferFromToSelf(address from, address dest, uint256 amount) public {
        require(from != address(0));
        require(from == dest);
        require(amount > 0);
        require(amount != type(uint256).max);

        token._mint(from, amount);
        uint256 initialFromBalance = token.balanceOf(from);
        require(initialFromBalance > 0);

        uint256 initialDestBalance = token.balanceOf(dest);

        token.approve(msg.sender, amount);
        uint256 initialFromAllowance = token.allowance(from, msg.sender);
        require(initialFromAllowance >= amount);

        bool success = token.transferFrom(from, dest, amount);
        require(success);

        uint256 newFromBalance = token.balanceOf(from);
        uint256 newDestBalance = token.balanceOf(dest);
        uint256 newFromAllowance = token.allowance(from, msg.sender);

        assert(newFromBalance == initialFromBalance);
        assert(newDestBalance == initialDestBalance);
        assert(newFromAllowance == initialFromAllowance - amount); // is this right?
    }

    /** 
    *  @dev
    *  property ERC20-STDPROP-12 implementation
    *  transferFrom coming from address 0 should fail and revert.
    */ 
    // function proveFail_transferFromZeroAddress(address from, address to, uint256 amt) public {
    //     require(from == address(0));
    //     require(to != address(0));
    //     bool r = token.transferFrom(from, to, amt);
    //     assertWithMsg(r == false, "transferFrom coming from zero address success");
    //     assert(r != true);
    // }

    // /** 
    // *  @dev
    // *  property ERC20-STDPROP-07 implementation
    // *  transferFrom to address 0 should fail and revert.
    // */ 
    // function proveFail_transferFromToZeroAddress(uint256 amt) public {
    //     token._mint(msg.sender, amt);
    //     uint256 sender_balance = token.balanceOf(msg.sender);
    //     uint256 sender_allowance = token.allowance(msg.sender, address(this));
    //     require(sender_balance > 0 && sender_allowance > 0);
    //     uint256 maxAmt = sender_balance >= sender_allowance
    //                     ? sender_allowance
    //                     : sender_balance;

    //     bool r = token.transferFrom(msg.sender, address(0), amt % (maxAmt + 1));
    //     assertWithMsg(r == false, "transferFrom to address zero sucess");
    //     assert(r != true);
    // }

    // /** 
    // *  @dev
    // *  property ERC20-STDPROP-08 implementation
    // *  transferFrom should revert if not enough balance available
    // */ 
    // function proveFail_transferFromNotEnoughBalance(address usr, uint256 amt) public {
    //     token._mint(msg.sender, amt);
    //     uint256 sender_balance = token.balanceOf(msg.sender);
    //     uint256 usr_balance = token.balanceOf(usr);
    //     uint256 sender_allowance = token.allowance(msg.sender, address(this));
    //     require(sender_balance > 0 && sender_allowance > sender_balance);

    //     bool r = token.transferFrom(msg.sender, usr, sender_balance + 1);
    //     assertWithMsg(r == false, "transferFrom with more than account balance success.");
    //     assertEq(token.balanceOf(msg.sender), sender_balance);
    //     assertEq(token.balanceOf(usr), usr_balance);
    // }
}
