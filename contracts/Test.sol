//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract TestContract {
    function tryCall() public pure returns (uint256 value) {
        uint256 x = 1;
        return x;
    }
}