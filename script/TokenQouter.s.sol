// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

// Import necessary contracts and interfaces.
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import {IQuoter} from "@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IWETH9} from "../src/tokens/IWETH9.sol";
import {TokenQouter} from "../src/TokenQouter.sol";
import {Errors} from "../src/utils/Errors.sol";
import "../src/utils/Enums.sol";
import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/utils/Structs.sol";

contract TokenQouterScript is Script {
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
    TokenQouter public tokenQouterETHTOUSDT;
    InitParams public qouterParams;
    ERC20 public usdc;
    ERC20 public weth;
    ERC20 public usdt;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Initialize ERC20 tokens and user accounts
        usdc = ERC20(USDC_ETH);
        weth = ERC20(WETH9_ETH);
        usdt = ERC20(USDT_ETH);
        qouterParams = InitParams({
            tokenIn: WETH9_ETH,
            tokenOut: USDT_ETH,
            qouter: UNISWAP_QOUTER_ETH,
            poolFee: 3000,
            tokenInPool: CURVE_SWAP_WETH_POOL_ETH,
            tokenOutPool: CURVE_SWAP_WETH_POOL_ETH,
            uniswap: ISwapRouter(SWAP_ROUTER_ETH),
            uniswapQuoter: IQuoter(UNISWAP_QOUTER_ETH),
            curveSwap: ISwap(
                IProvider(CURVE_ADDRESS_PROVIDER_ETH).get_address(2)
            ),
            sushiSwapRouter: IUniswapV2Router01(SUSHI_SWAP_ETH),
            exchangeProvider: IProvider(CURVE_ADDRESS_PROVIDER_ETH)
        });
        tokenQouterETHTOUSDT = new TokenQouter();
        tokenQouterETHTOUSDT.initialize(qouterParams);
        console.log("tokenQouter: %o", address(tokenQouterETHTOUSDT));
        console.log("WETH9_ETH:%o", WETH9_ETH);
        console.log("USDT_ETH:%o", USDT_ETH);
        vm.stopBroadcast();
    }
}
