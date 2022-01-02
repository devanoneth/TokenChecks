// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./lib/IERC20.sol";
import "./lib/UniswapV2Library08.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

// For now, expects arb opportunity to exist across token0
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

        // As mentioned, we only expect profit in token1
        // but this should be generalised to work in either direction
        IERC20 tokenB = IERC20(token1);
        uint256 initialBalance = tokenB.balanceOf(callee);

        address pair = UniswapV2Library08.pairFor(router.factory(), token0, token1);

        // We need some data to be passed so that our "callee" gets called
        // You should probably be passing some information here for your "callee" to use
        bytes memory data = abi.encode("0x");
        IUniswapV2Pair(pair).swap(amount0, amount1, callee, data);

        // Check we have made some $$$
        bool result = tokenB.balanceOf(callee) > initialBalance;

        assembly {
            // return result (1 byte)
            mstore(0x0, result)
            return(0x1f, 0x1)
        }
    }
}
