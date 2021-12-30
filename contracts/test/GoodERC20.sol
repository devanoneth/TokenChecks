// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@rari-capital/solmate/src/tokens/ERC20.sol";

// An innocent ERC20 token
contract GoodERC20 is ERC20 {
    constructor() ERC20("Good", "GOOD", 18) {
        _mint(msg.sender, 1000e18);
    }
}
