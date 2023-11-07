// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

// Import dependencies and contracts
import "forge-std/Test.sol";
import "forge-std/console.sol";
import {ISwap} from "../../../src/curve/ISwap.sol";
import {IProvider} from "../../../src/curve/IProvider.sol";
import {UniswapV3} from "../../../src/uniswap/UniswapV3.sol";
import {IUniversalRouter} from "../../../src/uniswap/IUniversalRouter.sol";
import {IPermitV2} from "../../../src/uniswap/IPermitV2.sol";

import {TokenQouter} from "../../../src/TokenQouter.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import {BaseUniswap} from "../../base/BaseUniswap.t.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../../src/utils/Structs.sol";
import "../../../src/utils/Enums.sol";

contract UniswapQouterTest is BaseUniswap {
    // Declare state variables
    TokenQouter public tokenQouterETHTOUSDT;
    InitParams public qouterParams;
    address public admin;
    address public alice;
    address public jane;
    ERC20 public usdc;
    ERC20 public weth;
    ERC20 public usdt;

    // Function to set up the test environment
    function setUp() public override {
        RPC_MAINNET_ETH = vm.envString("RPC_ENDPOINT_ETH_MAINNET");
        // Set the Ethereum mainnet fork
        ETH_CHAIN_ID_MAINNET = vm.createSelectFork(
            RPC_MAINNET_ETH,
            BLOCK_NUMBER_ETH
        );
        vm.selectFork(ETH_CHAIN_ID_MAINNET);

        // Initialize ERC20 tokens and user accounts
        usdc = ERC20(USDC_ETH);
        weth = ERC20(WETH9_ETH);
        usdt = ERC20(USDT_ETH);

        admin = _createUserAndFund("admin");
        alice = _createUserAndFund("alice");
        jane = _createUserAndFund("jane");
        vm.label(admin, "admin");
        vm.label(jane, "jane");
        vm.label(alice, "alice");
        vm.label(WETH9_WHALE_ETH, "WETH9_WHALE_ETH");
        vm.label(WETH9_ETH, "WETH9_ETH");
        vm.label(USDT_WHALE_ETH, "USDT_WHALE_ETH");
        vm.label(USDT_ETH, "USDT_ETH");
        _dealToken(admin, WETH9_WHALE_ETH, weth, defaultWETHTokenBalance);
        _dealToken(alice, WETH9_WHALE_ETH, weth, defaultWETHTokenBalance);
        _dealToken(jane, WETH9_WHALE_ETH, weth, defaultWETHTokenBalance);

        // Create and initialize TokenQouter contract
        vm.startPrank(admin);
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
            exchangeProvider: IProvider(CURVE_ADDRESS_PROVIDER_ETH),
            universalRouter: IUniversalRouter(UNIVERSAL_ROUTER_ETH),
            permitV2: IPermitV2(PERMIT_V2_ETH)
        });
        tokenQouterETHTOUSDT = new TokenQouter();
        tokenQouterETHTOUSDT.initialize(qouterParams);
        vm.stopPrank();
    }

    // Function to test getting the optimal quote for a token swap
    function test_getQouteTokenInToTokenOut_Optimal() public {
        vm.selectFork(ETH_CHAIN_ID_MAINNET);
        vm.startPrank(admin);

        // Get the user's balance of USDT before the swap
        uint256 balanceBefore = usdt.balanceOf(admin) / 10 ** usdt.decimals();
        console.log("balanceBefore:%o", balanceBefore);
        // Perform a token swap based on the optimal quote
        tokenQouterETHTOUSDT.swapExactETHToTokenOut{value: 1 ether}()

        // Get the user's balance of USDT after the swap
        uint256 balanceAfter = usdt.balanceOf(admin) / 10 ** usdt.decimals();
        console.log("balanceAfter:%o", balanceAfter);

        // Ensure the user's balance increased after the swap
        assert(balanceAfter > balanceBefore);
        vm.stopPrank();
    }

    // Function to test getting quotes for token swaps
    function test_getQoutes() public {
        vm.selectFork(ETH_CHAIN_ID_MAINNET);
        vm.startPrank(admin);
        uint256[] memory qoutes;
        address optimalPool;

        // Get quotes for a token swap
        (qoutes, optimalPool) = tokenQouterETHTOUSDT.getQouteTokenInToTokenOut(
            1 ether,
            3000
        );
        uint256 idealQoute = _findMax(qoutes);
        console.log("qoutes UNISWAP: %o", qoutes[0] / 10 ** usdt.decimals());
        console.log("qoutes CURVE: %o", qoutes[1] / 10 ** usdt.decimals());
        console.log("qoutes SUSHI: %o", qoutes[2] / 10 ** usdt.decimals());
        console.log("Ideal qoute:%o", idealQoute / 10 ** usdt.decimals());

        // Ensure quotes were obtained and ideal quote is greater than 0
        assert(qoutes.length > 0 && idealQoute > 0);

        vm.stopPrank();
    }
}
