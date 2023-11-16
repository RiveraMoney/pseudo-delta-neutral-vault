pragma solidity ^0.8.0;

library LiquiMaths {
    function calculateLend(
        uint256 tvl, // 80/100
        uint256 _amount,
        uint256 deci
    ) public pure returns (uint256) {
        uint256 de = 1 * 1000 + ((8 * tvl * 1000) / 1000);
        uint a = (1 * 10 ** deci * 1000) / de;

        return (_amount * a) / 10 ** deci;
    }

    function calculateBorrow(
        uint256 tvl,
        uint256 _amount,
        uint256 deci
    ) public pure returns (uint256) {
        uint256 de = 1 * 1000 + ((8 * tvl * 1000) / 1000);
        uint a = (1 * 10 ** deci * 1000) / de;
        uint256 b = (8 * tvl * 100) / 100;

        return (a * b * _amount) / (1000 * 10 ** deci);
    }
}
