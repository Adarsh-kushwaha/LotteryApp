const { network, ethers } = require('hardhat');
const { developmentChains, networkConfig } = require('../hardhat-helper.config');
const { verify } = require('../utils/verify');

module.export = async function ({ getNamedAccounts, deployments }) {
    const { deploy, log } = deployments;
    const { deployer } = getNamedAccounts();
    let vrfCoordinatorsAdd, subscriptionId;
    const chainId = network.config.chainId;
    const VRF_SUB_FUND_AMOUNT = ethers.utils.parseEther("0.01");


    if (developmentChains.includes(network.name)) {
        const vrfCoordinatorMock = await ethers.getContract("Mock");
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

    const args = [vrfCoordinatorsAdd, entranceFee, gasLane, callbackGasLimit, interval];

    const raffle = await deploy("Raffle", {
        from: deployer,
        args: args,
        log: true,
        waitConfirmations: network.config.blockConfirmations || 1
    })

    if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
        log("verifying....");
        await verify(raffle.address, args)
    }

    log("________________________________");

}