// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

/**
@title Stacker Contract
@author scaffold Eth
@notice A contract that allow users stack ether;
 */
contract Staker {
    // External contract that holds stacked funds
    ExampleExternalContract public exampleExternalContract;

    //Balances of user's stacked funds
    mapping(address => uint256) public balances;

    // Staking deadline
    uint256 public deadline = block.timestamp + 72 hours;

    //Contract's Stake Event
    event Stake(address indexed _to, uint256 indexed _amount);

    event Transfer(address indexed _to, uint256 indexed _amount);

    // event Recive(address indexed _to, uint256 indexed _amount);

    // Staking threshold
    uint256 public constant threshold = 1 ether;

    bool openForWithdraw;

    bool isActive;

    /**
     * @notice Modifier that require the external contract to not be completed
     */
    modifier notCompleted() {
        bool completed = exampleExternalContract.completed();
        require(!completed, "staking process completed");
        _;
    }

    /**
     * @notice Contract Constructor
     * @param exampleExternalContractAddress Address of the external contract that will hold stacked funds
     */
    constructor(address exampleExternalContractAddress) public {
        exampleExternalContract = ExampleExternalContract(
            exampleExternalContractAddress
        );
    }

    /**
     * @notice Stake method that update the user's balance
     */
    function stake() public payable {
        require(block.timestamp < deadline, "you missed the deadline");
        balances[msg.sender] += msg.value;
        emit Stake(msg.sender, msg.value);
        if (block.timestamp < deadline && address(this).balance >= threshold) {
            isActive = true;
        }
    }

    function execute() public notCompleted {
        if (address(this).balance >= threshold) {
            require(block.timestamp > deadline, "You still have time");
            exampleExternalContract.complete{value: address(this).balance}();
        } else {
            openForWithdraw = true;
            withdraw();
        }
    }

    /**
     * @notice Allow users to withdraw their balance from the contract only if deadline is reached but the stake is not completed
     */
    function withdraw() public notCompleted {
        // require(balances[msg.sender] )
        require(block.timestamp > deadline, "It's not deadline yet");
        require(isActive == false, "do have no stake");
        require(balances[msg.sender] > 0, "you've not deposited");
        uint256 amount = balances[msg.sender];
        balances[msg.sender] = 0;
        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "failed to send ether");
        emit Transfer(msg.sender, amount);
    }

    /**
     * @notice The seconds remaining until the deadline is reached
     */
    function timeLeft() public view returns (uint256) {
        if (block.timestamp >= deadline) {
            return 0;
        } else {
            return deadline - block.timestamp;
        }
    }

    // Add the `receive()` special function that receives eth and calls stake()
    // function recieve() external payable {
    //     emit Recieve(msg.sender, msg.value);
    //     stake();
    // }
}
