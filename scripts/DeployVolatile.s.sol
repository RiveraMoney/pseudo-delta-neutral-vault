// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../src/strategies/common/AbstractStrategy.sol";
import "../src/vaults/RiveraAutoCompoundingVaultV2Public.sol";
import "../src/strategies/irs/PdnRivera.sol";
import "../src/strategies/common/interfaces/IStrategy.sol";

import "./Weth.sol";

contract deployVolatile is Script {
    address public usdc = 0x09Bc4E0D864854c6aFB6eB9A9cdF58aC190D0dF9; // Usdc mantle Mainnet
    address public wEth = 0xdEAddEaDdeadDEadDEADDEAddEADDEAddead1111; //wEth mantle
    address public midToken = 0x201EBa5CC46D216Ce6DC03F6a759e8E766e956aE; //usdt mantle
    address public wMnt = 0x78c1b0C915c4FAA5FffA6CAbf0219DA63d7f4cb8; // wMnt mantle
    address public debtToken = 0x5DF9a4BE4F9D717b2bFEce9eC350DcF4cbCb91d8; //Variable debt wEth lendle mantle
    address public aToken = 0xF36AFb467D1f05541d998BBBcd5F7167D67bd8fC; //aUsdc
    address public lendle = 0x25356aeca4210eF7553140edb9b8026089E49396; //lendle  mantle mainnet
    bytes32 public pId =
        0xff61491a931112ddf1bd8147cd1b641375f79f5825126d665480874634fd0ace; //weth id
    bytes32 public pIB =
        0x4e3037c822d852d79af3ac80e35eb420ee3b870dca49f9344a38ef4773fb0585; //wmnt id

    bytes32 public pIusdc =
        0xeaa020c61cc479712813461ce153894a96a6c00b21ed0cfc2798d1f9a9e9c94a; // usdc

    address public lendingPool = 0xCFa5aE7c2CE8Fadc6426C1ff872cA45378Fb7cF3; // mantle  main net
    address public riveraVault = 0x5f247B216E46fD86A09dfAB377d9DBe62E9dECDA; //rivera agni mantle
    address public riveraWethMnt = 0xDc63179CC57783493DD8a4Ffd7367DF489Ae93BF;
    address public router = 0x319B69888b0d11cEC22caA5034e25FfFBDc88421; // agnifinance v3
    address public pyth = 0xA2aa501b19aff244D90cc15a4Cf739D2725B5729; // on mantle
    address public multiFeeD = 0x5C75A733656c3E42E44AFFf1aCa1913611F49230; //Lendle Contract to collect fees
    address public masterCh = 0x79e2fd1c484EB9EE45001A98Ce31F28918F27C41;
    address public routerH = 0xDd0840118bF9CCCc6d67b2944ddDfbdb995955FD; // fusionx v2

    address public partner = 0xFaBcc4b22fFEa25D01AC23c5d225D7B27CB1B6B8; // my address
    address public protocol = 0xf12Ac6acb0B8542B1c717E520A5B4C085222e4b9;
    uint256 public protocolFee = 0;
    uint256 public partnerFee = 0;
    uint256 public fundManagerFee = 0;
    uint256 public feeDecimals = 100;
    uint256 public withdrawFee = 1;
    uint256 public withdrawFeeDecimals = 100;

    uint24 public poolFee = 500;

    uint256 public ltv = 80;
    uint256 stratUpdateDelay = 172800;
    uint256 vaultTvlCap = 10000e18;

    function setUp() public {}

    function run() public {
        address gaus = 0xFaBcc4b22fFEa25D01AC23c5d225D7B27CB1B6B8;
        uint privateKey = 0xfc2f8cc0abd2d9d05229c8942e8a529d1ba9265eb1b4c720c03f7d074615afbb;
        address acc = vm.addr(privateKey);
        console.log("Account", acc);

        vm.startBroadcast(privateKey);

        RiveraAutoCompoundingVaultV2Public vault = new RiveraAutoCompoundingVaultV2Public(
                usdc,
                "PdnRivera-USDC-WETH-Vault",
                "PdnRivera-USDC-WETH-Vault",
                stratUpdateDelay,
                vaultTvlCap
            );

        CommonAddresses memory _commonAddresses = CommonAddresses(
            address(vault),
            router
        );

        PdnParams memory _pdnParams = PdnParams(
            usdc,
            wEth,
            lendingPool,
            riveraVault,
            pyth,
            pIusdc,
            pId,
            ltv
        );

        PdnFeesParams memory _pdnFeesParams = PdnFeesParams(
            protocol,
            partner,
            protocolFee,
            partnerFee,
            fundManagerFee,
            feeDecimals,
            withdrawFee,
            withdrawFeeDecimals
        );

        PdnHarvestParams memory _pdnHarvestParams = PdnHarvestParams(
            lendle,
            wMnt,
            masterCh,
            multiFeeD,
            routerH
        );

        PdnRivera parentStrategy = new PdnRivera(
            _commonAddresses,
            _pdnParams,
            _pdnFeesParams,
            _pdnHarvestParams,
            poolFee,
            8
        );

        Weth(wMnt).deposit{value: 100 * 1e18}();
        uint256 bal = Weth(wMnt).balanceOf(acc);
        console.log(bal);
        vault.init(IStrategy(address(parentStrategy)));
        console.log("ParentVault");
        console2.logAddress(address(vault));
        console.log("ParentStrategy");
        console2.logAddress(address(parentStrategy));
        vm.stopBroadcast();
    }
}

//forge script scripts/DeployVolatile.s.sol:deployVolatile --rpc-url http://127.0.0.1:8545/ --broadcast -vvv --legacy --slow

// anvil --fork-url https://rpc.mantle.xyz --mnemonic "disorder pretty oblige witness close face food stumble name material couch planet"

/*  ParentVault
  0x8a1b62c438B7b1d73A7a323C6b685fEc021610aC
  ParentStrategy
  0xf5eB7A02d1B8Dc14D5419Ee9F3f4DeE342960e08 */

// forge script scripts/DeployStrategy.s.sol:deployRivera --rpc-url http://13.232.85.53:8545/ --broadcast -vvv --legacy --slow
