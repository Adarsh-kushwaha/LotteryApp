const { network, ethers } = require("hardhat");
const { developmentChains } = require("../hardhat-helper.config");

const BASE_FEE = ethers.utils.parseEther("0.25");
const GAS_PRICE_LINK = 1e9;

module.exports = async function ({ getNamedAccounts, deployments }) {
    const { deploy, log } = deployments;
    const { deployer } = getNamedAccounts();
    const chainId = network.config.chainId;

    if (developmentChains.includes(network.name)) {
        log("local network detected deploying mocks!")

        await deploy("Mock", {
            from: deployer,
            log: true,
            args: [BASE_FEE, GAS_PRICE_LINK],
        })

        log("Mocks deployed!");
        log("_______________________________________________________")
    }
}

module.exports.tags = ["all", "mocks"];