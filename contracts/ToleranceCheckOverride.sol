// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./lib/IERC20.sol";
import "./lib/UniswapV2Library08.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

// Adapted from https://github.com/0xV19/TokenProvidence/blob/master/contracts/TokenProvidence.sol
// Buy and sell token. Keep track of ETH before and after.
// Can catch the following:
// 1. Honeypots
// 2. Internal Fee Scams
// 3. Buy diversions
contract ToleranceCheckOverride {
    function checkToken(
        address routerAddress,
        address tokenAddress,
        uint256 tolerance
    ) external returns (bool) {
        IUniswapV2Router02 router = IUniswapV2Router02(routerAddress);

        //Get tokenAmount estimate (can be skipped to save gas in a lot of cases)
        address[] memory pathBuy = new address[](2);
        uint256[] memory amounts;
        pathBuy[0] = router.WETH();
        pathBuy[1] = tokenAddress;
        IERC20 token = IERC20(tokenAddress);

        uint256 initialEth = address(this).balance;

        amounts = UniswapV2Library08.getAmountsOut(router.factory(), initialEth, pathBuy);
        uint256 buyTokenAmount = amounts[amounts.length - 1];

        //Buy tokens
        uint256 scrapTokenBalance = token.balanceOf(address(this));
        router.swapETHForExactTokens{value: initialEth}(buyTokenAmount, pathBuy, address(this), block.timestamp);
        uint256 tokenAmountOut = token.balanceOf(address(this)) - scrapTokenBalance;

        //Sell token
        require(tokenAmountOut > 0, "Can't sell this.");
        address[] memory pathSell = new address[](2);
        pathSell[0] = tokenAddress;
        pathSell[1] = router.WETH();

        uint256 ethBefore = address(this).balance;
        token.approve(routerAddress, tokenAmountOut);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmountOut,
            0,
            pathSell,
            address(this),
            block.timestamp
        );
        uint256 ethAfter = address(this).balance;
        uint256 ethOut = ethAfter - ethBefore;

        //Check tolerance
        bool result = initialEth - ethOut <= tolerance;

        assembly {
            // return result (1 byte)
            mstore(0x0, result)
            return(0x1f, 0x1)
        }
    }

    fallback() external payable {}
}
