// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Fadra is ERC20 {
    uint256 public immutable maxSupply = 6942000000 * 10 ** 18;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        // include total supply here
    }

    function mint(uint256 amount) public {
        uint256 amountWithDecimals = amount * 10 ** 18;
        require(
            totalSupply() + amountWithDecimals <= maxSupply,
            "Minting exceeds max supply"
        );

        // here goes the logic of deducting fee from minting token (2% + 2% + 0.85%)

        _mint(msg.sender, amountWithDecimals);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        // here goes the logic of deducting fee from transfer token (2% + 2% + 0.85%)

        super._transfer(from, to, amount);
    }
}
