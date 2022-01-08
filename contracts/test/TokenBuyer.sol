// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../lib/IERC20.sol";

import "../lib/UniswapV2Library08.sol";

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract TokenBuyer {
    function buyTokens(
        address routerAddress,
        address tokenAddress,
        uint256 tolerance
    ) public payable {
        IUniswapV2Router02 router = IUniswapV2Router02(routerAddress);

        //Get tokenAmount estimate (can be skipped to save gas in a lot of cases)
        address[] memory pathBuy = new address[](2);
        uint256[] memory amounts;
        pathBuy[0] = router.WETH();
        pathBuy[1] = tokenAddress;
        IERC20 token = IERC20(tokenAddress);

        amounts = UniswapV2Library08.getAmountsOut(router.factory(), msg.value, pathBuy);
        uint256 buyTokenAmount = amounts[amounts.length - 1];

        //Buy tokens
        uint256 scrapTokenBalance = token.balanceOf(address(this));
        router.swapETHForExactTokens{value: msg.value}(buyTokenAmount, pathBuy, address(this), block.timestamp);
        uint256 tokenAmountOut = token.balanceOf(address(this)) - scrapTokenBalance;
        require(tokenAmountOut > 0, "Can't sell this.");
    }

    function sellTokens(
        address routerAddress,
        address tokenAddress
    ) public payable {
        IUniswapV2Router02 router = IUniswapV2Router02(routerAddress);

        address[] memory pathSell = new address[](2);
        pathSell[0] = tokenAddress;
        pathSell[1] = router.WETH();
        IERC20 token = IERC20(tokenAddress);

        token.approve(routerAddress, type(uint256).max);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            token.balanceOf(address(this)),
            0,
            pathSell,
            address(this),
            block.timestamp
        );
    }
}
