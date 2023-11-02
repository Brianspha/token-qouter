// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

/**
 * @title IProvider
 * @dev Interface for a provider contract that provides addresses based on an ID.
 */
interface IProvider {
    /**
     * @dev Get the address associated with a specific ID.
     * @param _id The ID for which to retrieve the address.
     * @return The address associated with the given ID.
     */
    function get_address(uint256 _id) external view returns (address);
}
