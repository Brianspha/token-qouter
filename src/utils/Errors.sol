// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/**
 * @title Errors
 * @dev Contract defining custom errors used in the TokenQouter contract.
 */
contract Errors {
    // Define custom error: InvalidAmount
    error InvalidAmount();

    // Define custom error: InvalidAmountOut
    error InvalidAmountOut();

    // Define custom error: InvalidAmounts
    error InvalidAmounts(uint256 qoute,uint256 idealQoute);
}
