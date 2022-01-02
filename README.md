# Token Checks for MEV

On-chain checks for common types of smart contract scams. Useful for anyone exploring MEV. See the original [TokenProvidence](https://github.com/0xV19/TokenProvidence) repo for more details on these types of checks. Check them out in `/contracts`.

This repo is a hardhat-ified and constructor optimized version of [OxV19's](https://twitter.com/0xV19) providence checks. Thanks to [DrGorilla](https://twitter.com/DrGorilla_md) for the constructor input to avoid deploying the contracts at all. 

I added some basic tests to show how they can be used. Check them out in `test/` to see how to use these contracts efficently.

I also added on an example of [geth's state override set](https://geth.ethereum.org/docs/rpc/ns-eth#3-object---state-override-set) inspiried by [libevm's tweet](https://twitter.com/libevm/status/1476791869585588224). These are the `flashSwap.ts` files in `test` and `scripts`. These need to be heavily modified to be useful in a production setting, but they serve as an example for now.

## Setup
 - `cp .env.example .env`
 - Fill out the `.env` file
 - `npm install`

## Tests

 - `npm run test`

## Usage

### Checking Tokens

 - `npm run token <token address>`
 - e.g. `npm run token 0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48` for USDC
 - e.g. `npm run token 0x843976d0705c821ae02ab72ab505a496765c8f93` for some honeypot

### Flash Swap
There is also a [Uniswap Flash Swap](https://docs.uniswap.org/protocol/V2/guides/smart-contract-integration/using-flash-swaps) example between UniswapV2 and Sushiswap on their ETH<>DAI pairs. Running `npm run flash` will test the opportunity without deploying any contracts.

Note, this example is unlikely to find an arb as that's a heavily watched pair. Also, the example is:
 - Not gas optimized.
 - Only works one way and tries to get a profit of 1e-18 DAI.
 - Probably not the most secure.

Think of it as a proof of concept to help you learn about flash swaps and usage of `eth_call`.

## Inspired by:

- https://github.com/0xV19/TokenProvidence
- https://github.com/drgorillamd/UniV2-burn
- Epic PR here https://github.com/Uniswap/v2-periphery/pull/17/files


### WARNING
Not responsible for any errors which may occur. Use at your own risk.
