// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract PropertiesAsserts {
    event AssertFail(string);

    function assertWithMsg(bool b, string memory reason) internal {
        if (!b) {
            emit AssertFail(reason);
            assert(false);
        }
    }
}