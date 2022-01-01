// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./lib/IERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Callee.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";

contract UniswapV2FlashCallee is IUniswapV2Callee {
    // Because the constructor will not be called on this contract, we need to have these addresses baked in
    // There are some ways you could also generalize these addresses. Maybe in the future...
    address private immutable UNI_FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address private immutable SUSHI_FACTORY = 0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac;
    address private immutable SUSHI_ROUTER = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;

    function uniswapV2Call(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external {
        address token0 = IUniswapV2Pair(msg.sender).token0();
        address token1 = IUniswapV2Pair(msg.sender).token1();
        assert(msg.sender == IUniswapV2Factory(UNI_FACTORY).getPair(token0, token1)); // ensure that msg.sender is a V2 pair
        // In reality you should also check the `sender` param, skipping for now...

        IUniswapV2Router02 sushiRouter = IUniswapV2Router02(SUSHI_ROUTER);

        address[] memory path = new address[](2);
        path[0] = token0;
        path[1] = token1;

        sushiRouter.swapExactTokensForTokens(amount1, 0, path, address(this), block.timestamp);

        IERC20 tokenA = IERC20(token0);
        uint256 returnAmount = tokenA.balanceOf(address(this));

        TransferHelper.safeTransfer(token0, msg.sender, returnAmount - 1);
    }
}
