// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IStaking{


    function getAllHolder() external 
    returns(address[] memory users, uint256[] memory amount, uint256[] memory 
    lastStaked, uint256 totalSupply, uint256 lastTimeStaked);
    function addReward(address user, address[] memory tokens, uint256[] memory amountEligible) external;
    
}


contract MotherPool is Ownable, ReentrancyGuard {

    uint256 public lastClaimTime;
    uint256 public epoch = 1000;
    mapping(uint256 => uint256) public succesFullPresales;
    mapping(uint256 => mapping(uint256 => Reward[]) ) public poolToReward;
    mapping(uint256 => Reward[]) public rewardsData;
    address public stakingContract;

    struct Reward{
       address token ;
       uint256 amount;
    }

    function receiveTokens(address token, uint256 amount) public{
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        succesFullPresales[lastClaimTime] += 1;
        Reward memory newData = Reward({
          token :token,
          amount : amount
        });
        rewardsData[lastClaimTime].push(newData);
    }

    function finalizeReward() external {
        require(block.timestamp> lastClaimTime +epoch,"Time still left");
        require(succesFullPresales[lastClaimTime]>0,"No successfull presale");
        if(succesFullPresales[lastClaimTime] < 2){
               poolToReward[lastClaimTime][2] = rewardsData[lastClaimTime];
        }
        else if(succesFullPresales[lastClaimTime] > 2 && succesFullPresales[lastClaimTime] <= 10){
            uint256 count = rewardsData[lastClaimTime].length;
            Reward[] memory itemsPool= rewardsData[lastClaimTime];
            Reward[] memory itemsPool1 = new Reward[](count);
            Reward[] memory itemsPool2 = new Reward[](count);
            for(uint256 i=0; i< count ; i++){
            Reward memory newData = Reward({
             token :itemsPool[i].token,
             amount : itemsPool[i].amount/2
            });
            itemsPool1[i] = newData;
            itemsPool2[i] = newData;
            }

        }
        else if(succesFullPresales[lastClaimTime]>10){

            uint256 count = rewardsData[lastClaimTime].length;
            Reward[] memory itemsPool= rewardsData[lastClaimTime];
            Reward[] memory itemsPool1 = new Reward[](count);
            Reward[] memory itemsPool2 = new Reward[](count);
            Reward[] memory itemsPool3 = new Reward[](count);
            for(uint256 i=0; i< count ; i++){
            Reward memory newData = Reward({
             token :itemsPool[i].token,
             amount : itemsPool[i].amount*10/100
            });
            itemsPool1[i] = newData;
            }

            for(uint256 i=0; i< count ; i++){
            Reward memory newData = Reward({
             token :itemsPool[i].token,
             amount : itemsPool[i].amount*30/100
            });
            itemsPool2[i] = newData;
            }

            for(uint256 i=0; i< count ; i++){
            Reward memory newData = Reward({
             token :itemsPool[i].token,
             amount : itemsPool[i].amount*60/100
            });
            itemsPool3[i] = newData;
            }

            
        }

    }

    function distributePool1(Reward[] memory newData) private {
        (address[] memory users, uint256[] memory _amount, 
        uint256[] memory lastStaked, uint256 totalStaked, uint256 lastDistributed) = 
        IStaking(stakingContract).getAllHolder();
        for(uint256 j = 0; j < users.length ; j++){
            address[] memory tokens;
            uint256[] memory amount;

            for(uint256 i =0; i< newData.length;i++){
            tokens[i] = newData[i].token;
            amount[i] = newData[i].amount;

         }
               
            }
        


    }

    function distributePool2(Reward memory newData) private {
        
    }

    function distributePool3(Reward memory newData) private {
        
    }


}
