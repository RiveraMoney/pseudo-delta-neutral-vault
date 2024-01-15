const { Price, PriceFeed, EvmPriceServiceConnection } = require("@pythnetwork/pyth-evm-js");

const { ethers, Wallet, providers } = require("ethers");


const connection = new EvmPriceServiceConnection(
    "https://hermes.pyth.network.",
    { timeout: 10000 }
);

//address of all the assets of ReaxOne
const priceIds = [
    "0xeaa020c61cc479712813461ce153894a96a6c00b21ed0cfc2798d1f9a9e9c94a",
    "0x2b89b9dc8fdf9f34709a5b106b472f0f39bb6ca9ce04b0fd7f2e971688e2e53b",
    "0xff61491a931112ddf1bd8147cd1b641375f79f5825126d665480874634fd0ace",
    "0x4e3037c822d852d79af3ac80e35eb420ee3b870dca49f9344a38ef4773fb0585",
    "0xc9d8b075a5c69303365ae23633d4e085199bf5c520a3b90fed1322a0342ffc33"];


async function run() {

    try {
        const priceUpdateData = await connection.getPriceFeedsUpdateData(priceIds);

        console.log(priceUpdateData);
    } catch (e) {
        console.log(e);
    }

}
run();