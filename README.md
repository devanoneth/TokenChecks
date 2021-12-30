# Token Checks for MEV

On-chain checks for common types of smart contract scams. Useful for anyone exploring MEV. See the original [TokenProvidence](https://github.com/0xV19/TokenProvidence) repo for more details on these types of checks. Check them out in `/contracts`.

This repo is a hardhat-ified and constructor optimized version of [OxV19's](https://twitter.com/0xV19) providence checks. Thanks to [DrGorilla](https://twitter.com/DrGorilla_md) for the constructor input to avoid deploying the contracts at all.

I also added some basic tests to show how they can be used. Check them out in `test/` to see how to use these contracts efficently.

## Setup
 - `cp .env.example .env`
 - Fill out the `.env` file
 - `npm install`

## Tests

 - `npm run test`

## Usage

 - `npm run token <token address>`
 - e.g. `npm run token 0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48` for USDC
 - e.g. `npm run token 0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48` for some honeypot

## Inspired by:

- https://github.com/0xV19/TokenProvidence
- https://github.com/drgorillamd/UniV2-burn


### WARNING
Not responsible for any errors which may occur. Use at your own risk.
