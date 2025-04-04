```


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract XToken is ERC20 {
    uint256 public immutable maxSupply; // Maximum supply of the token

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply
    ) ERC20(_name, _symbol) {
        maxSupply = _maxSupply * 10 ** decimals(); // Set the max supply in the constructor
    }

    // total token supply = 6,942,000,000

    // Public mint function that allows anyone to mint tokens
    function mint(uint256 amount) public {
        uint256 amountWithDecimals = amount * 10 ** decimals();
        // Ensure the total supply does not exceed the max supply
        require(
            totalSupply() + amountWithDecimals <= maxSupply,
            "Minting exceeds max supply"
        );

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

    // for reward pool i will be using this same contract will be work as erc-20 token
    // as well as it can handle reward pool

    // chatgpt is suggesting to keep the target activity and target reward pool dynamic
    // also it is saying to keep the dynamic the baseAlphaMin and max and baseBetaMin and max
    // around 10% for the inital rewar pool is sounds like a good idea

    // while claiming reward i need to put condition to exclude few day atleast, otherwise they will buy token and try to claim reward in next reward itself, so i need to put a condition to exclude few days atleast
}



```

some measurments:

1. Recommended Implementation for first fee logic of transffering token to LP

   Direct Addition to Liquidity Pool:
   If you want simplicity, you can transfer the 2% in your token directly to the liquidity pool. However, this approach can skew the token-to-base-token ratio over time, leading to price instability.

   Split and Add Balanced Liquidity:
   A better approach is to:
   Take the 2% fee.
   Swap half of it for the base token (e.g., ETH/USDC).
   Add both parts (your token and the swapped base token) to the liquidity pool using the DEX's router contract.
   This keeps the pool balanced and maintains price stability.

2.

edge conditons:

1. make sure user mint and transfer througth only smart contract, if they where able to transfer it from uniswap, transaction fee won't incur.


02 Jan 2025

todos

- finish token contract (done)
- make the contract more finish 
- implement the summation logic (done)
- complete reward contract (done)
- fix all the error

- step up timestamp in user activity (done)
- step up transaction count in user activity (done)

- add validation to ensure fee is transferred to respective wallets
- is there any cost of minting token for user



https://docs.google.com/document/d/1tq4CJf4CgV7G1CYy_u5Ti1A2k1igXwIz7O8pwkPYQBU/edit?usp=sharing