// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

contract Events {
    event BestQoute(uint256[] indexed qoutes, address indexed poolAddress);

    event Swap(
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 indexed amountOut
    );
}
