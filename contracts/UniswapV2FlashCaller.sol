// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./lib/IERC20.sol";
import "./lib/UniswapV2Library08.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "hardhat/console.sol";

// For now, expects arb opportunity only to occur on token0
contract UniswapV2FlashCaller {
    constructor(
        address routerAddress,
        address callee,
        address token0,
        address token1,
        uint256 amount0,
        uint256 amount1
    ) {
        IUniswapV2Router02 router = IUniswapV2Router02(routerAddress);

        IERC20 tokenB = IERC20(token1);
        uint256 initialBalance = tokenB.balanceOf(callee);

        address pair = UniswapV2Library08.pairFor(router.factory(), token0, token1);

        bytes memory callback_data = abi.encode(
            token0, // need to encode the direction
            token1
        );
        IUniswapV2Pair(pair).swap(amount0, amount1, callee, callback_data);

        // Check tolerance
        bool result = tokenB.balanceOf(callee) > initialBalance;

        assembly {
            // return result (1 byte)
            mstore(0x0, result)
            return(0x1f, 0x1)
        }
    }
}
