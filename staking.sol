// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title Staking Contract
 * @author Kei Nakano - Nave Finance
 * @notice scalable reward distribution algorithm
 **/
interface IStaking{


    function getAllHolder() external 
    returns(address[] memory users, uint256[] memory amount, uint256[] memory 
    lastStaked, uint256 totalSupply);
    function addReward(address user, address[] memory tokens, uint256[] memory amountEligible) external;
    function updateRewardsUser(address token, uint256 amount) external;
    
}

contract Staking is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    IERC20 public stakingToken;

    uint256 public constant DIVISION = 10000; // to prevent float calculation

    address public treasury;
    uint256 public fees;

    uint256 public lastRewardRate; // S = 0;
    uint256 public totalStakedAmount; // T = 0;
    mapping(address => uint256) public stakedBalance; // stake = {};
    mapping(address => uint256) public lastTimeStaked; 
    mapping(address => address[]) public userRewardTokens;
    mapping(address => uint256[]) public userRewardAmount;
    event Stake(address indexed user, uint256 amount);
    event Unstake(address indexed user, uint256 amount);
    event ClaimReward(address indexed user, uint256 reward);
    event Distribute(address indexed user, uint256 reward);

    constructor(
        address _stakingToken
    ) {
        stakingToken = IERC20(_stakingToken);
        
      }


    function stake1(uint256 _amount) external nonReentrant {
        require(_amount > 100,  "Cannot stake 0");
        stakingToken.safeTransferFrom(msg.sender, treasury, fees);
        stakingToken.safeTransferFrom(msg.sender, address(this), _amount-fees);
        stakedBalance[msg.sender] += _amount-fees; // stake[address] = amount;
        lastTimeStaked[msg.sender] = block.timestamp; 
        totalStakedAmount += _amount-fees; // T = T + amount;
        emit Stake(msg.sender, _amount-fees);
    }

    function addReward(address user, address[] memory tokens, uint256[] memory amountEligible) public{
        for(uint256 i=0; i< tokens.length; i++){
           userRewardTokens[user].push(tokens[i]);
           userRewardAmount[user].push(amountEligible[i]);
        }
    }

    // function unstake1(uint256 _amount) external nonReentrant {
    //     require(_amount > 0, "Cannot withdraw 0");
    //     uint256 deposited = stakedBalance[msg.sender]; // deposited = stake[address];
    //     require(_amount <= deposited, "Withdraw amount is invalid");
    //     if(lastTimeStaked[msg.sender] + 2592000 > block.timestamp){
    //      uint256 fee = 
    //      stakingToken.safeTransfer(msg.sender, _amount-fee);
    //     }
    //     totalStakedAmount -= _amount; // T = T - deposited;
    //     stakedBalance[msg.sender] -= _amount; // stake[address] = 0;
    //     emit Unstake(msg.sender, _amount);
    // }

    function unstakeAll() external nonReentrant {
        uint256 deposited = stakedBalance[msg.sender]; // deposited = stake[address];
        stakingToken.safeTransfer(msg.sender, deposited);
        totalStakedAmount -= deposited; // T = T - deposited;
        stakedBalance[msg.sender] = 0; // stake[address] = 0;
        emit Unstake(msg.sender, deposited);
    }



    uint256 public lastClaimTime;
    uint256 public epoch = 1000;
    mapping(uint256 => uint256) public succesFullPresales;
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
               
               distributePool3(rewardsData[lastClaimTime]);
               lastClaimTime = block.timestamp;
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
            lastClaimTime = block.timestamp;
            distributePool2(itemsPool1);
            distributePool3(itemsPool2);

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
            lastClaimTime = block.timestamp;
            distributePool1(itemsPool1);
            distributePool2(itemsPool2);
            distributePool3(itemsPool3);
            
        }

    

    }

    function distributePool1(Reward[] memory newData) private {
        (address[] memory users, uint256[] memory _amount, 
        uint256[] memory lastStaked, uint256 totalStaked) = 
        IStaking(stakingContract).getAllHolder();
        for(uint256 j = 0; j < users.length ; j++){
            if(lastStaked[j]+epoch < block.timestamp)
            {

            for(uint256 i =0; i< newData.length;i++){
            
            IStaking(stakingContract).updateRewardsUser
            (newData[i].token, (newData[i].amount*_amount[j])/(totalStaked));
         }
            }
               
            }
        


    }

    function distributePool2(Reward[] memory newData) private {

       (address[] memory users, uint256[] memory _amount, 
        uint256[] memory lastStaked, uint256 totalStaked) = 
        IStaking(stakingContract).getAllHolder();
        for(uint256 j = 0; j < users.length ; j++){
            if(lastStaked[j]+epoch < block.timestamp)
            {

            for(uint256 i =0; i< newData.length;i++){
            
            IStaking(stakingContract).updateRewardsUser
            (newData[i].token, (newData[i].amount*_amount[j])/(totalStaked));
         }
            }
               
            }
        
    }

    function distributePool3(Reward[] memory newData) private {

        (address[] memory users, uint256[] memory _amount, 
        uint256[] memory lastStaked, uint256 totalStaked) = 
        IStaking(stakingContract).getAllHolder();
        for(uint256 j = 0; j < users.length ; j++){
            if(lastStaked[j]+epoch < block.timestamp)
            {

            for(uint256 i =0; i< newData.length;i++){
            
            IStaking(stakingContract).updateRewardsUser
            (newData[i].token, (newData[i].amount*_amount[j])/(totalStaked));
         }
            }
               
            }
        
    }
    
}
