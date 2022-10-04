//raffle
//enter the contest by paying some amount
//Pick a random winner from participating member
//chainlink oracle -> randomness, Automated execution -> Chainlink keepers

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/*imports*/
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
//import '@chainlink/contracts/src/v0.8/ConfirmedOwner.sol';

//error
error Raffle_NotEnoughEthEntered();
error Rafffle_TransactionFailed();
error Raffle_NotOpen();

abstract contract Raffle is VRFConsumerBaseV2, AutomationCompatibleInterface {
    /* Type decleration */
    enum RaffleState {
        OPEN,
        CALCULATING
    }

    /* State Variable */
    uint256 private immutable i_entranceFee;
    //use for storing players address
    address payable[] private s_players;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gaslane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callBackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    //lottery variables
    address private s_recentWinner;
    RaffleState private s_raffleState;

    /* Events */
    event raffleEnter(address indexed s_players);
    event requestRaffleWinner(uint256 indexed requestId);
    event winnerPicked(address indexed winner);

    constructor(
        address vrfCoordinatorV2,
        uint256 entranceFee,
        bytes32 gaslane,
        uint64 subscriptionId,
        uint32 callBackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_entranceFee = entranceFee;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gaslane = gaslane;
        i_subscriptionId = subscriptionId;
        i_callBackGasLimit = callBackGasLimit;
        s_raffleState = RaffleState.OPEN;
    }

    //enter raffle
    function enterRaffle() public payable {
        if (msg.value < i_entranceFee) {
            revert Raffle_NotEnoughEthEntered();
        }

        if(s_raffleState != RaffleState.OPEN){
            revert Raffle_NotOpen();
        }

        s_players.push(payable(msg.sender));
        //emit the event when we update the player array or mapping
        emit raffleEnter(msg.sender);
    }

    //get entery fees
    function getEnteryFee() public view returns (uint256) {
        return i_entranceFee;
    }

    /**
     * @dev  This is the function that the Chainlink Keeper nodes call
     * they look for `upkeepNeeded` to return True.
     * the following should be true for this to return true:
     * 1. The time interval has passed between raffle runs.
     * 2. The lottery is open.
     * 3. The contract has ETH.
     * 4. Implicity, your subscription is funded with LINK.
     *
     */
    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {
        //14.42.23
        // We don't use the checkData in this example. The checkData is defined when the Upkeep was registered.
    }

    //pick the random participant
    function requestRandomWinner() external {
        //request the random number
        //perform this action in two transaction so no external factor can manipulate the result
        s_raffleState = RaffleState.CALCULATING;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gaslane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callBackGasLimit,
            NUM_WORDS
        );

        emit requestRaffleWinner(requestId);
    }

    //fullfill random word
    function fulfillRandomWords(
        uint256, /*requestId*/
        uint256[] memory randomWords
    ) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable addressOfRecentWinner = s_players[indexOfWinner];
        s_recentWinner = addressOfRecentWinner;
        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        (bool success, ) = addressOfRecentWinner.call{
            value: address(this).balance
        }("");

        if (!success) {
            revert Rafffle_TransactionFailed();
        }
        emit winnerPicked(addressOfRecentWinner);
    }

    function getRecentWinner() public view returns (address) {
        return s_recentWinner;
    }
}
