const { Price, PriceFeed, EvmPriceServiceConnection } = require("@pythnetwork/pyth-evm-js");

const { ethers, Wallet, providers } = require("ethers");

const connection = new EvmPriceServiceConnection(
    "https://xc-mainnet.pyth.network",
    { timeout: 10000 }
);

// const connection = new EvmPriceServiceConnection(
//     "https://hermes.pyth.network.",
//     { timeout: 10000 }
// );   

const priceIds = [
    "0xeaa020c61cc479712813461ce153894a96a6c00b21ed0cfc2798d1f9a9e9c94a"];

const priceIdsO = [
    "0x4e3037c822d852d79af3ac80e35eb420ee3b870dca49f9344a38ef4773fb0585"];

async function run() {

    try {
        const priceUpdateData = await connection.getPriceFeedsUpdateData(priceIds);

        console.log(priceUpdateData);
    } catch (e) {
        console.log(e);
    }

}

run();