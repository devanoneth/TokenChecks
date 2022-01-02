// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./lib/IERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Callee.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";

// You should really read https://docs.uniswap.org/protocol/V2/guides/smart-contract-integration/using-flash-swaps
// in order to understand what's happening here
// Note: this is a really crude example, it literally makes away with 1 unit of a token i.e. 1e-18 DAI in this example
// Making more money is left as an exercise to the reader ;)
// Also, not responsible for all saftey checks. You should probably do more.
contract UniswapV2FlashCallee is IUniswapV2Callee {
    // Because the contract will not have any storage slots set, you need to use constant variables here
    // you could find/replace in the deployed bytecode to make them configurable in your app... out of scope for this example
    address constant uniFactoryAddress = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address constant sushiRouterAddress = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
    // You'll need to set your calling address here to avoid situations like https://twitter.com/libevm/status/1476034043724533764
    // We set this to the deterministic address of UniswapV2FlashCaller in the hardhat network
    address constant owner = 0x3325d25F43be85f8F579FB00648A8CE937d87d09;

    function uniswapV2Call(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external {
        // This is all horribly gas inefficent, but I think it's more readable for people getting started
        address token0 = IUniswapV2Pair(msg.sender).token0();
        address token1 = IUniswapV2Pair(msg.sender).token1();
        require(msg.sender == IUniswapV2Factory(uniFactoryAddress).getPair(token0, token1));

        require(sender == owner);

        IERC20 tokenA = IERC20(token0);

        IUniswapV2Router02 sushiRouter = IUniswapV2Router02(sushiRouterAddress);

        address[] memory path = new address[](2);
        path[0] = token0;
        path[1] = token1;

        // Exploit the arb opportunity which exists across Sushi <> Uni now
        tokenA.approve(address(sushiRouter), tokenA.balanceOf(address(this)));
        sushiRouter.swapExactTokensForTokens(
            amount0,
            0, // We don't care how many tokens we get, but in reality you should
            path,
            address(this),
            block.timestamp
        );

        // Check how much of token1 (DAI in this example) we now have
        IERC20 tokenB = IERC20(token1);
        uint256 returnAmount = tokenB.balanceOf(address(this));

        // Make the pair whole, but keep just 1 unit of a token to make sure that we can get SOME revenue
        // In reality, this is obviously not enough to make profit after fees / bribes
        TransferHelper.safeTransfer(token1, msg.sender, returnAmount - 1);
    }
}
