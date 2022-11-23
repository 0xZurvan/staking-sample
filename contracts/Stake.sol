// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Context.sol";

interface Token {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (uint256);    
}

contract Stake is Pausable, Ownable, ReentrancyGuard {

    event Staked(address indexed from, uint256 amount);
    event Claimed(address indexed from, uint256 amount);
    
    Token token;

    // 30 Days (30 * 24 * 60 * 60)
    uint256 public planDuration = 2592000;

    // 180 Days (180 * 24 * 60 * 60)
    uint256 _planExpired = 15552000;

    uint8 public interestRate = 32;
    uint256 public planExpired;
    uint8 public totalStakers;

    struct StakeInfo {        
        uint256 startTS;
        uint256 endTS;        
        uint256 amount; 
        uint256 claimed;       
    }

    mapping(address => StakeInfo) public stakeInfos;
    mapping(address => bool) public addressStaked;

    constructor(Token _tokenAddress) {
        token = _tokenAddress;        
        planExpired = block.timestamp + _planExpired;
    }
    
    function transferToken(uint256 _amount) external onlyOwner {
        require(token.transfer(address(this), _amount), "Token transfer failed!");  
    }

    function claimReward() external returns (bool) {
        require(addressStaked[_msgSender()] == true, "You are not participating");
        require(stakeInfos[_msgSender()].endTS < block.timestamp, "Stake Time is not over yet");
        require(stakeInfos[_msgSender()].claimed == 0, "Already claimed");

        uint256 stakeAmount = stakeInfos[_msgSender()].amount;
        uint256 totalReward = stakeAmount + (stakeAmount * interestRate / 100);
        stakeInfos[_msgSender()].claimed = totalReward;

        token.transfer(_msgSender(), totalReward);

        emit Claimed(_msgSender(), totalReward);

        return true;

    }

    function getPlanExpiry() external view returns (uint256) {
        require(addressStaked[_msgSender()] == true, "You are not participating");

        return stakeInfos[_msgSender()].endTS;

    }

    function stakeToken(uint256 _amount) external payable whenNotPaused {
        require(_amount > 0, "Error, stake amount should be > 0");
        require(block.timestamp < planExpired, "Error, plan expired");
        require(addressStaked[_msgSender()] == false, "You already participated");
        require(token.balanceOf(_msgSender()) >= _amount, "Insufficient Balance");

        token.transferFrom(_msgSender(), address(this), _amount);
        totalStakers++;
        addressStaked[_msgSender()] = true;

        stakeInfos[_msgSender()] = StakeInfo({
            startTS: block.timestamp,
            endTS: block.timestamp + planDuration,
            amount: _amount,
            claimed: 0
        });

        emit Staked(_msgSender(), _amount);

    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}