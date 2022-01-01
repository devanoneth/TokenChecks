// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./lib/IERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Callee.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "hardhat/console.sol";

contract UniswapV2FlashCallee is IUniswapV2Callee {
    // Because the contract will not have any storage slots set, you cannot use variables here

    // address private immutable SUSHI_FACTORY = 0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac;
    // address private immutable SUSHI_ROUTER = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;

    function uniswapV2Call(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external {
        address token0 = IUniswapV2Pair(msg.sender).token0();
        address token1 = IUniswapV2Pair(msg.sender).token1();
        // console.log(IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f).getPair(token0, token1));
        assert(msg.sender == IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f).getPair(token0, token1)); // ensure that msg.sender is a V2 pair
        // In reality you should also check the `sender` param, skipping for now...

        console.log(amount0);
        console.log(amount1);

        IERC20 tokenA = IERC20(token0);
        console.log(tokenA.balanceOf(address(this)));
        
        IUniswapV2Router02 sushiRouter = IUniswapV2Router02(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);

        address[] memory path = new address[](2);
        path[0] = token0;
        path[1] = token1;

        tokenA.approve(address(sushiRouter), tokenA.balanceOf(address(this)));
        sushiRouter.swapExactTokensForTokens(amount0, 0, path, address(this), block.timestamp);


        IERC20 tokenB = IERC20(token1);
        uint256 returnAmount = tokenB.balanceOf(address(this));
        console.log(returnAmount);

        TransferHelper.safeTransfer(token1, msg.sender, returnAmount - 1);
    }
}
