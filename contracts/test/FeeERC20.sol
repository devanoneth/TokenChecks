// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../lib/UniswapV2Library08.sol";
import "@rari-capital/solmate/src/tokens/ERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

// An ERC20 token which has a high (20%) fee
contract FeeERC20 is ERC20 {
    address private immutable uniPair;
    address private immutable haxor;

    constructor(address router) ERC20("Fee", "FEE", 18) {
        IUniswapV2Router02 uniRouter = IUniswapV2Router02(router);
        uniPair = UniswapV2Library08.pairFor(uniRouter.factory(), uniRouter.WETH(), address(this));

        _mint(msg.sender, 1000e18);
        haxor = msg.sender;
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        if (msg.sender == uniPair && to != haxor) {
            uint256 fee = (amount * 20) / 100;
            super.transfer(haxor, fee);
            amount -= fee;
        }

        return super.transfer(to, amount);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        if (from == uniPair && to != haxor) {
            uint256 fee = (amount * 20) / 100;
            super.transferFrom(from, haxor, fee);
            amount -= fee;
        }

        return super.transferFrom(from, to, amount);
    }
}
