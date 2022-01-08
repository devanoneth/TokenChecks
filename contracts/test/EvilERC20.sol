// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../lib/UniswapV2Library08.sol";
import "@rari-capital/solmate/src/tokens/ERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

// An ERC20 token which can only be bought but not sold
contract EvilERC20 is ERC20 {
    address private immutable uniPair;
    address private immutable haxor;

    constructor(address router) ERC20("Evil", "EVIL", 18) {
        IUniswapV2Router02 uniRouter = IUniswapV2Router02(router);
        uniPair = UniswapV2Library08.pairFor(uniRouter.factory(), uniRouter.WETH(), address(this));

        _mint(msg.sender, 1000e18);
        haxor = msg.sender;
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        if (to == uniPair && isContract(msg.sender)) {
            // Sorry babe, this is a honey pot
            return false;
        }
        return super.transfer(to, amount);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        if (to == uniPair && isContract(from)) {
            // Sorry babe, this is a honey pot
            return false;
        }

        return super.transferFrom(from, to, amount);
    }

    function isContract(address _addr) private view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }
}
