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

/// @title TokenQouter
/// @author brianspha
/// @notice Contract that allows users to swap tokens
/// @dev DO NOT USE IN PRODUCTION
contract TokenQouter is
    PausableUpgradeable,
    OwnableUpgradeable,
    Errors,
    Events
{
    // Store initialization parameters in a public variable.
    InitParams public qouterParams;
    // Precision factor
    uint256 private constant PRECISION = 1 ether;

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
     * @dev Swap Ether using a split trade methodalogy
     * @dev The Method gets qoutes from the 3 Dexes and splits the trade based on the best qoute
     * @dev The split is based on the percentage of the best qoute
     */
    function swapExactETHToTokenOut() public payable whenNotPaused returns () {
        if (msg.value == 0) {
            revert InvalidAmount();
        }
        uint256 amountOut;
        uint256 amountIn = msg.value;
        IWETH9(qouterParams.tokenIn).deposit{value: amountIn}();
        uint256[] memory qoutes;
        address optimalPool;

        (qoutes, optimalPool) = getQouteTokenInToTokenOut(
            amountIn,
            qouterParams.poolFee
        );

        uint256[] memory split = calculatePercentageSplit(qoutes);
        uint256 idealQoute = _findMax(qoutes);
        uint256 sushiAmountIn = getAmount(amountIn, split[0], amountIn);
        uint256 curveAmountIn = getAmount(amountIn, split[1], amountIn);
        uint256 uniswapAmountIn = getAmount(amountIn, split[2], amountIn);
        {//@dev avoid stack too deep error :XD
            TransferHelper.safeApprove(
                qouterParams.tokenIn,
                address(qouterParams.uniswap),
                uniswapAmountIn
            );
            //@dev swap selected is UniswapV3
            ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
                .ExactInputSingleParams({
                    tokenIn: qouterParams.tokenIn,
                    tokenOut: qouterParams.tokenOut,
                    fee: qouterParams.poolFee,
                    recipient: _msgSender(),
                    deadline: block.timestamp + 1 minutes,
                    amountIn: uniswapAmountIn,
                    amountOutMinimum: 1, //@dev this is not ideal buuut for testing purpose we set this to 1
                    sqrtPriceLimitX96: 0
                });
            // The call to `exactInputSingle` executes the swap.
            uint256 amountOutUniswap = qouterParams.uniswap.exactInputSingle(
                params
            );
            TransferHelper.safeApprove(
                qouterParams.tokenIn,
                address(qouterParams.curveSwap),
                curveAmountIn
            );
            //@dev curve finance selected
            uint256 amountOutCurve = qouterParams.curveSwap.exchange(
                optimalPool,
                qouterParams.tokenIn,
                qouterParams.tokenOut,
                curveAmountIn,
                1,
                _msgSender()
            );
            TransferHelper.safeApprove(
                qouterParams.tokenIn,
                address(qouterParams.sushiSwapRouter),
                sushiAmountIn
            );
            address[] memory path = new address[](2);
            path[0] = qouterParams.tokenIn;
            path[1] = qouterParams.tokenOut;
            //@dev sushi swap selected
            uint[] memory amounts = qouterParams
                .sushiSwapRouter
                .swapExactTokensForTokens(
                    sushiAmountIn,
                    1,
                    path,
                    _msgSender(),
                    block.timestamp + 1 minutes
                );
            uint256 amountOutSushi = amounts[0];
            amountOut = (amountOutCurve + amountOutUniswap + amountOutSushi);
            emit Swap(qouterParams.tokenIn, qouterParams.tokenOut, amountOut);
        }
        if (amountOut < idealQoute) {
            revert InvalidAmounts();
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
    ) public returns (uint256[] memory, address) {
        uint160 sqrtPriceLimitX96 = 0;
        uint256 quoteUNISWAP = qouterParams.uniswapQuoter.quoteExactInputSingle(
            qouterParams.tokenIn,
            qouterParams.tokenOut,
            poolFee,
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
        address[] memory path = address[](2);
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

    /**
     * @dev Find the maximum value in an array of numbers.
     * @param numbers The array of numbers to find the maximum from.
     * @return The maximum value in the array.
     */
    function _findMax(uint[] memory numbers) internal pure returns (uint) {
        require(numbers.length > 0, "Array must not be empty");
        uint max = numbers[0];
        uint i = 1;
        uint length = numbers.length;
        for (; i < length; ) {
            if (numbers[i] > max) {
                max = numbers[i];
            }
            unchecked {
                i++;
            }
        }

        return max;
    }

    function calculatePercentageSplit(
        uint256[] memory numbers
    ) public pure returns (uint256[] memory) {
        uint256 total = 0;
        uint256[] memory percentages = new uint256[](numbers.length);

        for (uint256 i = 0; i < numbers.length; i++) {
            total += numbers[i];
        }

        for (uint256 i = 0; i < numbers.length; i++) {
            percentages[i] = (numbers[i] * PRECISION) / total;
        }

        return percentages;
    }

    function getAmount(
        uint256 amount,
        uint256 percent,
        uint256 total
    ) public pure returns (uint256) {
        return (amount * percent * PRECISION) / (total * PRECISION);
    }
}
