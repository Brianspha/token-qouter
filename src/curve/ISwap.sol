// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/**
 * @title ISwap
 * @dev Interface for interacting with a Curve Finance swap pool.
 */
interface ISwap {
    /**
     * @dev Get the exchange amount when swapping tokens in a pool.
     * @param _pool The address of the pool contract.
     * @param _from The source token address.
     * @param _to The target token address.
     * @param _amount The input amount for the exchange.
     * @return The amount of the target token received.
     */
    function get_exchange_amount(
        address _pool,
        address _from,
        address _to,
        uint256 _amount
    ) external view returns (uint256);

    /**
     * @dev Exchange tokens in a Curve Finance pool.
     * @param _pool The address of the pool contract.
     * @param _from The source token address.
     * @param _to The target token address.
     * @param _amount The input amount for the exchange.
     * @param _expected The expected output amount.
     * @param _receiver The address to receive the swapped tokens.
     * @return The actual amount of the target token received.
     */
    function exchange(
        address _pool,
        address _from,
        address _to,
        uint256 _amount,
        uint256 _expected,
        address _receiver
    ) external payable returns (uint256);

    /**
     * @dev Get the best exchange rate for a token swap.
     * @param _from The source token address.
     * @param _to The target token address.
     * @param _amount The input amount for the exchange.
     * @return The pool address with the best rate and the amount of the target token received.
     */
    function get_best_rate(
        address _from,
        address _to,
        uint256 _amount
    ) external returns(address,uint256);
}
