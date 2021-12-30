// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./UniswapV2Library08.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

// Adapted from https://github.com/0xV19/TokenProvidence/blob/master/contracts/TokenProvidence.sol
// Buy token by estimating how many tokens you will get.
// After buying, compare it with the tokens you have. Can help in catching:
// 1. Internal Fee Scams
// 2. Low profit margins in sandwitch bots
// 3. Potential rugs (high internal fee is often a rug)
contract InternalFee {
    constructor(
        address routerAddress,
        address tokenAddress
    ) payable {
        IUniswapV2Router02 router = IUniswapV2Router02(routerAddress);

        address[] memory path = new address[](2);
        uint256[] memory amounts;
        path[0] = router.WETH();
        path[1] = tokenAddress;
        IERC20 token = IERC20(tokenAddress);

        amounts = UniswapV2Library08.getAmountsOut(
            router.factory(),
            msg.value,
            path
        );
        uint256 buyTokenAmount = amounts[amounts.length - 1];

        //Buy tokens
        uint256 scrapTokenBalance = token.balanceOf(address(this));
        router.swapETHForExactTokens{value: msg.value}(
            buyTokenAmount,
            path,
            address(this),
            block.timestamp
        );
        uint256 tokenAmountOut = token.balanceOf(address(this)) -
            scrapTokenBalance;

        //Verify no internal fees tokens (might be needed for sandwich bots)
        bool result = buyTokenAmount <= tokenAmountOut;

        assembly {
            // return result (1 byte)
            mstore(0x0, result)
            return(0x1f, 0x1)
        }
    }
}
