// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

// Import necessary contracts and interfaces.
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import {IQuoter} from "@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IWETH9} from "./tokens/IWETH9.sol";
import "./utils/Structs.sol";
import {Errors} from "./utils/Errors.sol";
import "./utils/Enums.sol";
import {Events} from "./utils/Events.sol";

// Define the TokenQouter contract.
contract TokenQouter is
    PausableUpgradeable,
    OwnableUpgradeable,
    Errors,
    Events
{
    // Store initialization parameters in a public variable.
    InitParams public qouterParams;

    /**
     * @dev Initialize the contract with the given parameters.
     * @param params The initialization parameters.
     */
    function initialize(InitParams memory params) public virtual initializer {
        qouterParams = params;
        __Ownable_init();
        __Pausable_init();
    }

    /**
     * @dev Swap Ether for a specified token using a selected protocol.
     * @param swapConfig The selected protocol (UNISWAPV3, CURVE, or another).
     * @return amountOut
     */
    function swapExactETHToTokenOut(
        PROTOCOL swapConfig
    ) external payable whenNotPaused returns (uint256 amountOut) {
        if (msg.value == 0) {
            revert InvalidAmount();
        }
        uint256 amountIn = msg.value;
        IWETH9(qouterParams.tokenIn).deposit{value: amountIn}();

        if (swapConfig == PROTOCOL.UNISWAPV3) {
            TransferHelper.safeApprove(
                qouterParams.tokenIn,
                address(qouterParams.uniswap),
                amountIn
            );
            //@dev swap selected is UniswapV3
            ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
                .ExactInputSingleParams({
                    tokenIn: qouterParams.tokenIn,
                    tokenOut: qouterParams.tokenOut,
                    fee: qouterParams.poolFee,
                    recipient: _msgSender(),
                    deadline: block.timestamp + 1 minutes,
                    amountIn: amountIn,
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
                });
            // The call to `exactInputSingle` executes the swap.
            amountOut = qouterParams.uniswap.exactInputSingle(params);
        } else if (swapConfig == PROTOCOL.CURVE) {
            TransferHelper.safeApprove(
                qouterParams.tokenIn,
                address(qouterParams.curveSwap),
                amountIn
            );
            //@dev curve finance selected
            amountOut = qouterParams.curveSwap.exchange(
                qouterParams.tokenOutPool,
                qouterParams.tokenIn,
                qouterParams.tokenOut,
                amountIn,
                1,
                _msgSender()
            );
        } else {
            TransferHelper.safeApprove(
                qouterParams.tokenIn,
                address(qouterParams.sushiSwapRouter),
                amountIn
            );
            address[] memory path = new address[](2);
            path[0] = qouterParams.tokenIn;
            path[1] = qouterParams.tokenOut;
            //@dev sushi swap selected
            uint[] memory amounts = qouterParams
                .sushiSwapRouter
                .swapExactTokensForTokens(
                    amountIn,
                    1,
                    path,
                    _msgSender(),
                    block.timestamp + 1 minutes
                );
            if (amounts.length == 0) {
                revert InvalidAmounts();
            }
            amountOut = amounts[0];
        }
        if (amountOut <= 0) {
            revert InvalidAmountOut();
        }
    }

    /**
     * @dev Get quotes for token swaps between tokenIn and tokenOut with different pool fees.
     * @param amount The input amount for which quotes are needed.
     * @param poolFee The pool fee to consider.
     * @return An array of quotes from different protocols and the pool address.
     */
    function getQouteTokenInToTokenOut(
        uint256 amount,
        uint24 poolFee
    ) external returns (uint256[] memory, address) {
        address tokenIn = qouterParams.tokenOut;
        address tokenOut = qouterParams.tokenIn;
        uint24 fee = poolFee;
        uint160 sqrtPriceLimitX96 = 0;

        uint256 quoteUNISWAP = qouterParams.uniswapQuoter.quoteExactInputSingle(
            tokenIn,
            tokenOut,
            fee,
            amount,
            sqrtPriceLimitX96
        );
        address poolAddress;
        uint256 quoteCurve;
        (poolAddress, quoteCurve) = qouterParams.curveSwap.get_best_rate(
            qouterParams.tokenIn,
            qouterParams.tokenOut,
            amount
        );
        address[] memory path = new address[](2);
        path[0] = qouterParams.tokenIn;
        path[1] = qouterParams.tokenOut;
        uint256[] memory amounts = qouterParams.sushiSwapRouter.getAmountsOut(
            amount,
            path
        );
        uint256 quoteSushi = amounts[1];
        uint256[] memory qoutes = new uint256[](3);
        qoutes[0] = quoteSushi;
        qoutes[1] = quoteCurve;
        qoutes[2] = quoteUNISWAP;
        emit BestQoute(qoutes, poolAddress);
        return (qoutes, poolAddress);
    }

    /**
     * @dev Pause the contract to prevent swaps.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpause the contract to allow swaps.
     */
    function unpause() external onlyOwner {
        _unpause();
    }
}
