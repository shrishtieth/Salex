// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Counters.sol";
import "./vesting.sol";
import "./liquidity.sol";

    contract PreSale is  Ownable {
    using Counters for Counters.Counter;
    Counters.Counter public presaleID;
    Counters.Counter public fairLaunchID;
    address public deadAddress;
    mapping(uint256 => PreSaleDetails) public idToPreSale;
    mapping(uint256 => bool) public whiteListCondition;
    mapping(uint256 => bool) public canClaim;
    mapping(uint256 => uint256) public amountRaised;
    mapping(address => bool) public allowedToCall;
    mapping(address => mapping(uint256 => bool)) public isWhitelisted;
    mapping(address => mapping(uint256 => uint256)) public presaleToVesting;
    mapping(address => mapping(uint256 => uint256)) public amountContributed;
    mapping(address => mapping(uint256 => uint256)) public amountEligible;
    mapping(address => mapping(uint256 => uint256)) public amountClaimed;
    uint256 public stakingFeePercentage;
    address public masterContract;
    uint256 public totalEthRaised;
    uint256 public penalty = 5  ;
    address public vestingContract;
    address public liquidityContract;

    

    struct PreSaleDetails{

       uint256 tokensPerETH;
       uint256 softCap;
       uint256 hardCap;
       address tokenAddress;
       uint256 minBuy;
       uint256 maxBuy;
       bool toBeBurnt;
       address router;
       uint256 amountTobeAddedToRouter;
       uint256 exchangeRate;
       uint256 startTime;
       uint256 EndTime;
       address owner;

    }

    constructor(address _contract) {
        masterContract = _contract;
        allowedToCall[masterContract] = true;
    }



function addPreSale(PreSaleDetails memory details, uint256 duration) public returns(uint256 saleId){
     IERC20(details.tokenAddress).transferFrom(details.owner, address(this),
      details.amountTobeAddedToRouter + (details.tokensPerETH * details.hardCap));
     uint256 saleID = presaleID.current();
     idToPreSale[saleID] = details;
     Liquidity(liquidityContract).createEntry(saleID ,
     details.router,
     duration, details.owner);
     presaleID.increment();
     return(saleID);
   }

   function buyToken(uint256 id) public payable{
     if(whiteListCondition[id]){
         require(isWhitelisted[msg.sender][id],"Access Denied");
     }
     require(allowedToCall[msg.sender],"AccessDenied");
     require(amountRaised[id] + msg.value <= idToPreSale[id].hardCap,"Hard Cap reached");
     require(block.timestamp < idToPreSale[id].EndTime && block.timestamp > idToPreSale[id].startTime,"Window Closed");
     require(idToPreSale[id].minBuy<= msg.value && idToPreSale[id].maxBuy>= msg.value,"Enter a valid amount");
     totalEthRaised = totalEthRaised + msg.value;
     amountRaised[id] = amountRaised[id] + msg.value;
     amountContributed[msg.sender][id] = amountContributed[msg.sender][id] + msg.value;
     amountEligible[msg.sender][id] = amountEligible[msg.sender][id] + msg.value*idToPreSale[id].tokensPerETH;
   }

   function claimToken(uint256 id) public{
    require(canClaim[id],"Can't Claim at the Moment");
    IERC20(idToPreSale[id].tokenAddress).transfer(msg.sender, amountEligible[msg.sender][id]);
    amountEligible[msg.sender][id] =0;
   }

   function claimRefund(uint256 id) public{
       require(block.timestamp > idToPreSale[id].EndTime + 172800, "Refund window is closed");
       require(canClaim[id]==false,"Cannot claim refund");
       totalEthRaised = totalEthRaised - amountContributed[msg.sender][id];
       amountRaised[id] = amountRaised[id] - amountContributed[msg.sender][id];
       payable(msg.sender).transfer(amountContributed[msg.sender][id]);
       amountContributed[msg.sender][id] = 0;
       amountEligible[msg.sender][id] = 0;


   }

   function withdrawContribution( uint256 id) public{
   require(block.timestamp < idToPreSale[id].EndTime,"Withdrawl window closed" );
   require(amountEligible[msg.sender][id]>0,"User didn't contribute");
     uint256 contributedAmount = amountContributed[msg.sender][id] ;
     totalEthRaised = totalEthRaised - contributedAmount;
     amountRaised[id] = amountRaised[id] - contributedAmount;
     amountContributed[msg.sender][id] = 0;
     amountEligible[msg.sender][id] = 0;  
     uint256 penaltyAmount = ((contributedAmount*penalty)/100);
     payable(msg.sender).transfer(contributedAmount - penaltyAmount);
    }

    function vestContribution(
        uint256 firstWithrawTime,
        uint256 firstClaimable,
        uint256 releasePerEpoch,
        uint256 epoch,
        uint256 lockID) public{
      uint256 tokensDeposited = amountContributed[msg.sender][lockID];
      address token = idToPreSale[lockID].tokenAddress;
      uint256 vestId = Vesting(vestingContract).vestToken(token, tokensDeposited,0, 
      firstWithrawTime, firstClaimable, 0, releasePerEpoch, epoch,msg.sender, lockID);
      presaleToVesting[msg.sender][lockID] = vestId;
      IERC20(token).transfer(vestingContract, tokensDeposited);
      amountEligible[msg.sender][lockID] =0;
    }

    function unvestContribution( uint256 id) public returns(uint256 amount){
       uint256 vest = presaleToVesting[msg.sender][id];
       amount = Vesting(vestingContract).unvestToken(vest);
       return(amount);
    }

    function finalise(uint256 id) public {
        require(idToPreSale[id].owner == msg.sender, "Access Denied");
        require(block.timestamp < idToPreSale[id].EndTime + 172800, "Finalising window is closed");
        require(amountRaised[id] >= idToPreSale[id].softCap,"Soft Cap not reached");
        canClaim[id] = true;
        uint256 amountTobeAdded = idToPreSale[id].amountTobeAddedToRouter;
        uint256 ethAmount = idToPreSale[id].exchangeRate * amountTobeAdded;
        require(ethAmount <= amountRaised[id],"Insufficient Eth");
        (uint256 liquidityAmount, address pair) = addLiquidityToRouter(idToPreSale[id].tokenAddress, idToPreSale[id].router,
        amountTobeAdded, ethAmount );
        uint256 liquidityId = Liquidity(liquidityContract).returnLiquidityId(id);
        if(liquidityId == 0){
         IUniswapV2Pair(pair).transfer(idToPreSale[id].owner, liquidityAmount);
        }
        else{
        Liquidity(liquidityContract).lockLiquidity(liquidityId, pair, liquidityAmount);
        }

        if(amountRaised[id]>ethAmount){
            payable(msg.sender).transfer(amountRaised[id]-ethAmount);
        }

        if(amountRaised[id]< idToPreSale[id].hardCap) {
            if(idToPreSale[id].toBeBurnt){
                IERC20(idToPreSale[id].tokenAddress).transfer
                (deadAddress,(idToPreSale[id].hardCap-amountRaised[id])*idToPreSale[id].tokensPerETH);
            }
            else{
               IERC20(idToPreSale[id].tokenAddress).transfer
                (msg.sender,(idToPreSale[id].hardCap-amountRaised[id])*idToPreSale[id].tokensPerETH); 
            }
        }    
    }
 
    function addLiquidityToRouter(address token, address router, uint256 tokenAmount, uint256 ethAmount) private returns
    (uint256 liquidity, address uniswapV2Pair){
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(router);
        address weth = uniswapV2Router.WETH();
         uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
        .createPair(token, weth);
        IERC20(token).approve(router, tokenAmount);

        // add the liquidity
        (,,liquidity) = uniswapV2Router.addLiquidityETH{value: ethAmount}(
            token,
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp +10000
        );
        return(liquidity, uniswapV2Pair);

    }

    function unlockLiquidity(uint256 id) public{
        require(msg.sender == idToPreSale[id].owner,"Access Denied");
        uint256 liquidityId = Liquidity(liquidityContract).returnLiquidityId(id);
        Liquidity(liquidityContract).unlockLiquidity(liquidityId);
    }
    
    receive() external payable {}
  
     
     
    }
