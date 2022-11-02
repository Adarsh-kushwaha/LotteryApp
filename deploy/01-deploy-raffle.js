const { network, ethers } = require('hardhat');
const { developmentChains, networkConfig } = require('../hardhat-helper.config');
const { verify } = require('../utils/verify');

module.exports = async function ({ getNamedAccounts, deployments }) {
    const { deploy, log } = deployments;
    const { deployer } = await getNamedAccounts();
    let vrfCoordinatorsAdd, subscriptionId;
    const chainId = network.config.chainId;
    const VRF_SUB_FUND_AMOUNT = ethers.utils.parseEther("1");


    if (developmentChains.includes(network.name)) {
        const vrfCoordinatorMock = await ethers.getContract("VRFCoordinatorV2Mock");
        vrfCoordinatorsAdd = vrfCoordinatorMock.address;
        const transactionResponse = await vrfCoordinatorMock.createSubscription();
        const transactionReceipt = await transactionResponse.wait(1);
        subscriptionId = transactionReceipt.events[0].args.subId;

        //fund the subscription
        await vrfCoordinatorMock.fundSubscription(subscriptionId, VRF_SUB_FUND_AMOUNT);

    } else {
        vrfCoordinatorsAdd = networkConfig[chainId]["vrfCoordinatorV2"];
        subscriptionId = networkConfig[chainId]["subscriptionId"];
    }

    const entranceFee = networkConfig[chainId]["entranceFee"];
    const gasLane = networkConfig[chainId]["gasLane"];
    const callbackGasLimit = networkConfig[chainId]["callbackGasLimit"];
    const interval = networkConfig[chainId]["interval"];

    const arg = [vrfCoordinatorsAdd, entranceFee, gasLane, subscriptionId, callbackGasLimit, interval];

    const raffle = await deploy("Raffle", {
        from: deployer,
        args: arg,
        log: true,
        waitConfirmations: 1,
    })

    if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
        log("verifying....");
        await verify(raffle.address, arg);
    }

    log("________________________________");

}