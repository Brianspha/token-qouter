// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol";
import {ISwap} from "../curve/ISwap.sol";
import {IProvider} from "../curve/IProvider.sol";
import  {IUniversalRouter} from "../uniswap/IUniversalRouter.sol";
import {IUniswapV2Router01} from "../sushi/IUniswapV2Router01.sol";
import  {IPermitV2} from "../uniswap/IPermitV2.sol";


// Define a struct to hold initialization parameters.
struct InitParams {
    address tokenIn;            // Address of the input token.
    address tokenOut;           // Address of the output token.
    address qouter;             // Address of the quoter.
    address tokenInPool;        // Address of the input token's pool.
    address tokenOutPool;       // Address of the output token's pool.
    uint24 poolFee;             // Pool fee.
    ISwapRouter uniswap;        // Uniswap router.
    IQuoter uniswapQuoter;     // Uniswap quoter.
    ISwap curveSwap;            // Curve swap.
    IUniswapV2Router01 sushiSwapRouter;   // SushiSwap router.
    IProvider exchangeProvider; // Exchange provider.
    IUniversalRouter universalRouter; // Universal router on uniswap
    IPermitV2 permitV2; // Permit V2 on uniswap
}
