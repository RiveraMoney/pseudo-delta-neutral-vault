pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "@openzeppelin/token/ERC20/IERC20.sol";
import "../../src/strategies/irs/PdnRivera.sol";
import "../../src/vaults/RiveraAutoCompoundingVaultV2Public.sol";
import "../../src/strategies/common/AbstractStrategy.sol";
import "../../src/strategies/irs/interfaces/IRivera.sol";
import "../../src/strategies/common/interfaces/IStrategy.sol";
import "../../src/strategies/irs/interfaces/ILendingPool.sol";
import "../../src/libs/LiquiMaths.sol";

contract StrategyTest is Test {
    address vault = 0x8a1b62c438B7b1d73A7a323C6b685fEc021610aC;
    address vaultV = 0x821F88928C950F638a94b74cD44A1b676D51a310;
    address strat = 0xf5eB7A02d1B8Dc14D5419Ee9F3f4DeE342960e08;
    address stratV = 0xb642f6F85fc68876700FB2699963611632AD8644 ;
    address riveraVault = 0x5f247B216E46fD86A09dfAB377d9DBe62E9dECDA;
    address riveraWethMnt = 0xDc63179CC57783493DD8a4Ffd7367DF489Ae93BF;
    address lendingPool = 0xCFa5aE7c2CE8Fadc6426C1ff872cA45378Fb7cF3;
    address masterC = 0xC90C10c7e3B2F14870cC870A046Bd099CCDDEe12;
    address multifee = 0x5C75A733656c3E42E44AFFf1aCa1913611F49230;
    address tokenVesting = 0xA7f784Dc0EC287342B0B84e63961eFfA541f7E6f;
    address chiefI = 0x79e2fd1c484EB9EE45001A98Ce31F28918F27C41;

    address token = 0x09Bc4E0D864854c6aFB6eB9A9cdF58aC190D0dF9;
    address wEth = 0xdEAddEaDdeadDEadDEADDEAddEADDEAddead1111;
    address wMnt = 0x78c1b0C915c4FAA5FffA6CAbf0219DA63d7f4cb8;
    address debtToken = 0x5DF9a4BE4F9D717b2bFEce9eC350DcF4cbCb91d8;
    address aToken = 0xF36AFb467D1f05541d998BBBcd5F7167D67bd8fC;

    address manager = 0x69605b7A74D967a3DA33A20c1b94031BC6cAF27c;
    address normalU = 0xf12Ac6acb0B8542B1c717E520A5B4C085222e4b9;
    address ethWhale = 0xf89d7b9c864f589bbF53a82105107622B35EaA40;
    address user = 0xFaBcc4b22fFEa25D01AC23c5d225D7B27CB1B6B8;

    uint256 one = 1e6;
    uint256 oneEth = 1e18;

    function setUp() public {
        vm.startPrank(ethWhale);

        IERC20(token).transfer(user, 1000000 * one);
        IERC20(token).transfer(normalU, 10000 * one);
        vm.stopPrank();

        vm.prank(ethWhale);
        IERC20(wEth).transfer(user, 100 * oneEth);
    }

    function test_Transfer() public {
        vm.startPrank(user);

        uint256 bal = IERC20(token).balanceOf(user);
        // console.log("balance USDC", bal);
        uint256 ethB = IERC20(wEth).balanceOf(user);
        // console.log("Weth Balance", ethB);
        assertEq(bal, 1000000 * 1e6);
        assertEq(ethB, 100 * 1e18);

        vm.stopPrank();
    }

    function test_DepositTokenNotPaused() public {
        vm.startPrank(user);

      
        uint256 dpDai = 10e6;
        IERC20(token).approve(vault, dpDai);
        RiveraAutoCompoundingVaultV2Public(vault).deposit(dpDai, user);

        uint256 totalA = RiveraAutoCompoundingVaultV2Public(vault)
            .totalAssets();

        uint256 balVal = RiveraAutoCompoundingVaultV2Public(vault).balanceOf(
            user
        );

        uint256 shaToAsset = RiveraAutoCompoundingVaultV2Public(vault)
            .convertToAssets(balVal);

        console.log("Balance of Strategy", totalA);
        console.log("Balance of user in Vault", balVal);
        console.log("user share to assets", shaToAsset);
        console.log("Total debt",IStrategy(strat).totalDebt());
        console.log("Total deposit",IStrategy(strat).balanceDeposit());
        console.log("Total in rivera",IStrategy(strat).balanceRivera());
        console.log("Total balance",IStrategy(strat).balanceOf());

        // assertEq(totalA, shaToAsset);
        // assertLe(totalA, dpDai);
        vm.stopPrank();
    }
    function test_HarvestByUser() public {
        vm.startPrank(user);

        uint256 mybal = IERC20(token).balanceOf(user);
        uint256 dpDai = 10e6;
        IERC20(token).approve(vault, dpDai);
        RiveraAutoCompoundingVaultV2Public(vault).deposit(dpDai, user);
        vm.warp(block.timestamp + 7 * 24 * 60 * 60);
        vm.stopPrank();

        console.log("total Assets before", IStrategy(strat).balanceOf());

        vm.startPrank(user);
        vm.warp(block.timestamp + 7 * 24 * 60 * 60);
        IStrategy(strat).harvest();
        vm.stopPrank();
        console.log("total Assets after", IStrategy(strat).balanceOf());
    }

    // function test_DepositTokenMulti(uint256 _amount) public {
    //     vm.assume(_amount >= one && _amount < 1000 * one);

    //     vm.startPrank(user);

    //     IERC20(token).approve(vault, _amount);
    //     RiveraAutoCompoundingVaultV2Public(vault).deposit(_amount, user);

    //     uint256 balVal = RiveraAutoCompoundingVaultV2Public(vault).balanceOf(
    //         user
    //     );
    //     uint256 inU = RiveraAutoCompoundingVaultV2Public(vault).convertToAssets(
    //         balVal
    //     );

    //     assertEq(inU, RiveraAutoCompoundingVaultV2Public(vault).totalAssets());
    // }

    // function test_DepositWrongToken() public {
    //     vm.startPrank(user);

    //     uint256 mybal = IERC20(wEth).balanceOf(user);
    //     uint256 dpDai = one * 10;
    //     IERC20(wEth).approve(vault, dpDai);
    //     vm.expectRevert();
    //     RiveraAutoCompoundingVaultV2Public(vault).deposit(dpDai, user);
    //     vm.stopPrank();
    // }

    // function test_DepositTokenPaused() public {
    //     vm.startPrank(manager);

    //     IStrategy(strat).pause();

    //     vm.stopPrank();

    //     vm.startPrank(user);

    //     uint256 mybal = IERC20(token).balanceOf(user);
    //     uint256 dpDai = mybal / 10;
    //     IERC20(token).approve(vault, dpDai);
    //     vm.expectRevert();
    //     RiveraAutoCompoundingVaultV2Public(vault).deposit(dpDai, user);

    //     vm.stopPrank();
    // }

    function test_WithdrawToken() public {
        vm.startPrank(user);
        uint256 mybal = IERC20(token).balanceOf(user);
        uint256 dpDai = 10e6;
        IERC20(token).approve(vault, dpDai);
        RiveraAutoCompoundingVaultV2Public(vault).deposit(dpDai, user);

        uint256 totalA = RiveraAutoCompoundingVaultV2Public(vault)
            .totalAssets();

        console.log("vault balance after deposit", totalA);

        uint256 balVal = RiveraAutoCompoundingVaultV2Public(vault).balanceOf(
            user
        );

        uint256 bU = RiveraAutoCompoundingVaultV2Public(vault).convertToAssets(
            balVal
        );
        console.log("Balance of user after depo", bU);

        RiveraAutoCompoundingVaultV2Public(vault).withdraw(bU, user, user);

        console.log(
            "balance of user after withdraw",
            RiveraAutoCompoundingVaultV2Public(vault).balanceOf(user)
        );
        console.log(
            "vault balance after withdraw",
            RiveraAutoCompoundingVaultV2Public(vault).totalAssets()
        );
        console.log("total loan", IStrategy(strat).totalDebt());
        console.log("total deposit", IStrategy(strat).balanceDeposit());
        console.log("total in rivera", IStrategy(strat).balanceRivera());
        console.log(
            "fee withdraw",
            IERC20(wEth).balanceOf(0xdA2C794f2d2D8aaC0f5C1da3BD3B2C7914D9C4d7)
        );
        // assertEq(RiveraAutoCompoundingVaultV2Public(vault).balanceOf(user), 0);
        // assertEq(RiveraAutoCompoundingVaultV2Public(vault).totalAssets(), 0);
        vm.stopPrank();
    }

    // function test_WithdrawTokenMulti(uint256 _amount) public {
    //     vm.assume(_amount >= one && _amount < 1000 * one);

    //     vm.startPrank(user);
    //     IERC20(token).approve(vault, _amount);
    //     RiveraAutoCompoundingVaultV2Public(vault).deposit(_amount, user);

    //     uint256 totalA = RiveraAutoCompoundingVaultV2Public(vault)
    //         .totalAssets();

    //     uint256 balVal = RiveraAutoCompoundingVaultV2Public(vault).balanceOf(
    //         user
    //     );
    //     uint256 bU = RiveraAutoCompoundingVaultV2Public(vault).convertToAssets(
    //         balVal
    //     );

    //     RiveraAutoCompoundingVaultV2Public(vault).withdraw(bU, user, user);
    //     // assertEq(RiveraAutoCompoundingVaultV2Public(vault).balanceOf(user), 0);
    //     // assertEq(RiveraAutoCompoundingVaultV2Public(vault).totalAssets(), 0);
    //     vm.stopPrank();
    // }

    // function test_PanicWithManager() public {
    //     vm.startPrank(user);
    //     uint256 mybal = IERC20(token).balanceOf(user);
    //     uint256 dpDai = one * 10;
    //     IERC20(token).approve(vault, dpDai);
    //     RiveraAutoCompoundingVaultV2Public(vault).deposit(dpDai, user);
    //     vm.stopPrank();

    //     vm.startPrank(manager);
    //     IStrategy(strat).panic();
    //     vm.stopPrank();
    //     assertEq(IStrategy(strat).paused(), true);

    //     uint256 balRi = IRivera(riveraVault).balanceOf(strat);
    //     uint256 dbt = IERC20(debtToken).balanceOf(strat);
    //     uint256 depoo = IERC20(aToken).balanceOf(strat);
    //     console.log("balri", balRi);
    //     console.log("dbt", dbt);
    //     console.log("depoo", depoo);

    //     assertEq(balRi, 0);
    //     assertEq(dbt, 0);
    //     assertEq(depoo, 0);
    // }

    // function test_PauseAndUnpause() public {
    //     vm.startPrank(user);
    //     uint256 mybal = IERC20(token).balanceOf(user);
    //     uint256 dpDai = mybal / 10;
    //     IERC20(token).approve(vault, dpDai);
    //     RiveraAutoCompoundingVaultV2Public(vault).deposit(dpDai, user);
    //     vm.stopPrank();

    //     vm.startPrank(manager);
    //     IStrategy(strat).panic();
    //     vm.stopPrank();
    //     assertEq(IStrategy(strat).paused(), true);

    //     vm.startPrank(manager);
    //     IStrategy(strat).unpause();
    //     vm.stopPrank();
    //     assertEq(IStrategy(strat).paused(), false);
    // }

    // function test_retierStratDirectly() public {
    //     vm.startPrank(user);

    //     uint256 mybal = IERC20(token).balanceOf(user);
    //     uint256 dpDai = mybal / 10;
    //     IERC20(token).approve(vault, dpDai);
    //     RiveraAutoCompoundingVaultV2Public(vault).deposit(dpDai, user);
    //     vm.stopPrank();

    //     vm.startPrank(vault);
    //     IStrategy(strat).retireStrat();
    //     uint256 bNow = IERC20(token).balanceOf(strat);

    //     assertEq(bNow, 0);
    //     vm.stopPrank();
    // }

    // function test_reBalanceWithoutManager() public {
    //     vm.startPrank(user);

    //     uint256 mybal = IERC20(token).balanceOf(user);
    //     uint256 dpDai = mybal / 10;
    //     IERC20(token).approve(vault, dpDai);
    //     RiveraAutoCompoundingVaultV2Public(vault).deposit(dpDai, user);

    //     vm.expectRevert();
    //     vm.warp(block.timestamp + 7 * 24 * 60 * 60);
    //     IStrategy(strat).reBalance();
    //     vm.stopPrank();
    // }

    // function test_reBalanceWithManager() public {
    //     vm.startPrank(user);

    //     uint256 mybal = IERC20(token).balanceOf(user);
    //     uint256 dpDai = mybal / 10;
    //     IERC20(token).approve(vault, dpDai);
    //     RiveraAutoCompoundingVaultV2Public(vault).deposit(dpDai, user);

    //     vm.stopPrank();

    //     vm.startPrank(manager);
    //     vm.warp(block.timestamp + 7 * 24 * 60 * 60);
    //     IStrategy(strat).reBalance();
    //     vm.stopPrank();
    // }
}

//forge test --fork-url http://34.235.148.86:8545/ --match-path test/strategies/StrategyTest.t.sol -vvv
