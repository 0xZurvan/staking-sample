// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20 {

    uint256 public maxSupply = 20000e18;
    uint256 public buyPrice = 1e18;

    constructor() ERC20("Token", "TKN") {
        _mint(msg.sender, 10000e18);
    }

    function buy(uint256 _amount) external payable {
        uint256 bigNumber = buyPrice * _amount;

        require(msg.value >= bigNumber, "Error, not enough ethers");
        require(totalSupply() + bigNumber < maxSupply, "Error, Max has been reached");

        _mint(msg.sender, bigNumber);
        
    }
}