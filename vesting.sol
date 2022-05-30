// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Counters.sol";



    contract Launch is  Ownable {
    using Counters for Counters.Counter;
    Counters.Counter public vestingID;
    mapping(uint256 => VestingDetails) public idToVesting;
    mapping(uint256 => uint256) public saleToVesting;
    mapping(address => bool) public allowedToCall;

    

    
    struct VestingDetails{

        address token;
        uint256 tokensDeposited;
        uint256 tokensWithdrawn;
        uint256 firstWithrawTime;
        uint256 firstClaimable;
        uint256 lastWithdrawnTime;
        uint256 releasePerEpoch;
        uint256 epoch;
        address owner;
        uint256 lockID;
        uint256 vestingID;
    }

    constructor() {}


    function vestToken(VestingDetails memory details) public returns(uint256 id){
        require(allowedToCall[msg.sender],"AccessDenied");
        id = vestingID.current();
        idToVesting[id] = details;
        vestingID.increment();
        return(id);
    }

    function unvestToken(uint256 id) public returns(uint256 amountUnvested){
        require(allowedToCall[msg.sender],"AccessDenied");
        require(block.timestamp > idToVesting[id].firstWithrawTime,"WindowClosed");
        uint256 amount;
        
        if(idToVesting[id].tokensWithdrawn ==0 && block.timestamp < idToVesting[id].firstWithrawTime + idToVesting[id].epoch){

          amount = idToVesting[id].firstClaimable;
          
        }
        else if(idToVesting[id].tokensWithdrawn ==0 && block.timestamp > idToVesting[id].firstWithrawTime + idToVesting[id].epoch){
        uint256 totalEpoch = (block.timestamp - idToVesting[id].firstWithrawTime)%(idToVesting[id].epoch);
        amount = idToVesting[id].firstClaimable + totalEpoch*idToVesting[id].releasePerEpoch;
        }
        else {
        uint256 totalEpoch = (block.timestamp - idToVesting[id].firstWithrawTime)%(idToVesting[id].epoch);
        amount = totalEpoch*idToVesting[id].releasePerEpoch;  
        }

        IERC20(idToVesting[id].token).transfer(idToVesting[id].owner, amount); 
        idToVesting[id].tokensWithdrawn = idToVesting[id].tokensWithdrawn + amount; 
        return(amount);
    }



}
