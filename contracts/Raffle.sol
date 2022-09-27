//raffle
//enter the contest by paying some amount
//Pick a random winner from participating member
//chainlink oracle -> randomness, Automated execution -> Chainlink keepers

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/*imports*/
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
//import '@chainlink/contracts/src/v0.8/ConfirmedOwner.sol';

error Raffle_NotEnoughEthEntered();

contract Raffle is VRFConsumerBaseV2 {
    /* State Variable */
    uint256 private immutable i_entranceFee;
    //use for storing players address
    address payable[] private s_players;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    byte32 private immutable i_gaslane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callBackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORD = 1;


    /* Events */
    event raffleEnter(address indexed s_players);
    event requestRaffleWinner(uint256 indexed requestId);

    constructor(address vrfCoordinatorV2, uint256 entranceFee, byte32 gaslane, uint64 subscriptionId, uint32 callBackGasLimit)
        VRFConsumerBaseV2(vrfCoordinatorV2)
    {
        i_entranceFee = entranceFee;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gaslane = gaslane;
        i_subscriptionId = subscriptionId;
        i_callBackGasLimit = callBackGasLimit;

    }

    //enter raffle
    function enterRaffle() public payable {
        if (msg.value < i_entranceFee) {
            revert Raffle_NotEnoughEthEntered();
        }

        s_players.push(payable(msg.sender));
        //emit the event when we update the player array or mapping
        emit raffleEnter(msg.sender);
    }

    //get entery fees
    function getEnteryFee() public view returns (uint256) {
        return i_entranceFee;
    }

    //pick the random participant
    function requestRandomWinner() external {
        //request the random number
        //perform this action in two transaction so no external factor can manipulate the result
        i_vrfCoordinator.requestRandomWords(
            i_gaslane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS.
            i_callBackGasLimit,
            NUM_WORD
        )

        emit requestRaffleWinner(requestId);
    }

    //fullfill random word
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {}
}
