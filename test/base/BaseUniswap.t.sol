// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";

/**
 * @title BaseUniswap
 * @dev Abstract contract for interacting with Uniswap and other protocols.
 */
abstract contract BaseUniswap is Test {
    // Addresses of various tokens and contracts
    address public constant USDT_WHALE_ETH =
        0xF977814e90dA44bFA03b6295A0616a897441aceC;
    address public constant WETH9_WHALE_ETH =
        0xF04a5cC80B1E94C69B48f5ee68a08CD2F09A7c3E;
    address public constant USDC_WHALE_ETH =
        0xcEe284F754E854890e311e3280b767F80797180d;
    address public constant WETH9_ETH =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant USDC_ETH =
        0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant USDT_ETH =
        0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address internal constant SWAP_ROUTER_ETH =
        0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address private constant UNISWAP_FACTORY_ETH =
        0x1F98431c8aD98523631AE4a59f267346ea31F984;
    address public constant UNISWAP_QOUTER_ETH =
        0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6;
    address public constant CURVE_SWAP_ETH =
        0x99a58482BD75cbab83b27EC03CA68fF489b5788f;
    address public constant CURVE_SWAP_WETH_POOL_ETH =
        0xD51a44d3FaE010294C616388b506AcdA1bfAAE46;
    address public constant CURVE_SWAP_STABLE_POOL_ETH =
        0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;
    address public constant SUSHI_SWAP_ETH =
        0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
    address public constant CURVE_ADDRESS_PROVIDER_ETH =
        0x0000000022D53366457F9d5E68Ec105046FC4383;

    // Ethereum mainnet RPC endpoint
    string public RPC_MAINNET_ETH;
    uint256 public ETH_CHAIN_ID_MAINNET;
    uint256 defaultUSDCTokenBalance = 100 * 10 ** 6;
    uint256 defaultUSDCTokenSwap = 10 * 10 ** 6;
    uint256 defaultWETHTokenBalance = 100 ether;
    uint256 defaultUSDTTokenSwap = 10 * 10 ** 6;

    function setUp() public virtual {}

    /**
     * @dev Create a user account and fund it with initial balance.
     * @param name The name for the user account.
     * @return The address of the created and funded user.
     */
    function _createUserAndFund(
        string memory name
    ) internal returns (address payable) {
        address payable user = payable(makeAddr(name));
        vm.deal({account: user, newBalance: 1000 ether});
        return user;
    }

    /**
     * @dev Transfer tokens from admin to a user.
     * @param user The address of the user to receive tokens.
     * @param admin The address of the admin with the tokens.
     * @param token The ERC20 token to transfer.
     * @param amount The amount of tokens to transfer.
     */
    function _dealToken(
        address user,
        address admin,
        ERC20 token,
        uint256 amount
    ) internal {
        console.log("tokenSymbol:%o", token.symbol());
        console.log("adminBalance:%o", token.balanceOf(admin));
        assert(token.balanceOf(admin) >= amount);
        vm.startPrank(admin);
        token.approve(user, amount);
        assertEq(token.allowance(admin, user), amount);
        token.transfer(user, amount);
        assertEq(token.balanceOf(user), amount);
        vm.stopPrank();
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
}
