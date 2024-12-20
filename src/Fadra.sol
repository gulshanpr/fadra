// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract XToken is ERC20 {
    uint256 public immutable maxSupply; // Maximum supply of the token

    constructor(string memory _name, string memory _symbol, uint256 _maxSupply) ERC20(_name, _symbol) {
        maxSupply = _maxSupply * 10 ** decimals(); // Set the max supply in the constructor
    }

    // Public mint function that allows anyone to mint tokens
    function mint(uint256 amount) public {
        uint256 amountWithDecimals = amount * 10 ** decimals();
        // Ensure the total supply does not exceed the max supply
        require(totalSupply() + amountWithDecimals <= maxSupply, "Minting exceeds max supply");
        
        // Mint the tokens to the caller
        _mint(msg.sender, amountWithDecimals);
    }

    // Override the _transfer function to include custom logic
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        // Example Custom Logic: Charge a 1% transfer fee
        uint256 fee = (amount * 1) / 100; // 1% fee
        uint256 amountAfterFee = amount - fee;

        // Fee is sent to a specific fee recipient (e.g., the deployer or a treasury address)
        address feeRecipient = 0x000000000000000000000000000000000000dEaD; // Burn address as example

        // Perform the transfers
        super._transfer(from, feeRecipient, fee); // Transfer the fee
        super._transfer(from, to, amountAfterFee); // Transfer the remaining amount
    }

    /**
     *
     function alphai(){}
     function betai(){}

     di = token held by this user or token he trading
     dmax = we keep track of everyone token tranfer and all, and on every transaction just increment the dmax counter
     totalActivity = it can be calculated by every transaction that execute transfer function
     TargetRewardPool and target activity will be constant
     to get to know about reward pool status (its a problem)


      
     */

    // function Hholding(){
    //     min of (Ti/Tmax, 1)
    //     Ti = last transaction date - current date
    //     Tmax = 365
    // }

    // function Sactivity(){
    // Sactivity = User Transaction / avg Transaction
        // from array we'll get no of transaction made my user = n
        // for avg transaction we'll have varibles that keep track for every transaction and on succesful is incremented transaction count, then will we have avg transaction = total transaction / n, we will get n by length of mapping that we will get by keeping track of every new user, if this user exists then use the mapping otherwise increase the n and add it to mapping
    // }

}
