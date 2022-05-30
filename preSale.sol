// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Counters.sol";
import "./vesting.sol";


interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    // function setFeeTo(address) external;
    // function setFeeToSetter(address) external;
}



interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}



interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}



interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}




    contract PreSale is  Ownable {
    using Counters for Counters.Counter;
    Counters.Counter public presaleID;
    Counters.Counter public fairLaunchID;
    address public deadAddress;
    mapping(uint256 => PreSaleDetails) public idToPreSale;
    mapping(uint256 => bool) public whiteListCondition;
    mapping(address => bool) public allowedToCall;
    mapping(address => mapping(uint256 => bool)) public isWhitelisted;
    mapping(address => mapping(uint256 => uint256)) public amountContributed;
    mapping(address => mapping(uint256 => uint256)) public amountEligible;
    mapping(address => mapping(uint256 => uint256)) public amountClaimed;
    uint256 public stakingFeePercentage;
    address public masterContract;
    uint256 public totalEthRaised;
    uint256 public penalty = 5  ;
    address public vestingContract;

    

    struct PreSaleDetails{

       uint256 tokensPerETH;
       uint256 softCap;
       uint256 hardCap;
       address tokenAddress;
       uint256 minBuy;
       uint256 maxBuy;
       bool toBeBurnt;
       address router;
       uint256 percentageTobeAddedToRouter;
       uint256 startTime;
       uint256 EndTime;
       uint256 owner;
       uint256 amountRaised;
       bool canClaim;
    }

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



    constructor(address _contract) {
        masterContract = _contract;
        allowedToCall[masterContract] = true;
    }

   function addPreSale(PreSaleDetails memory details) public returns(uint256 saleId){
     require(allowedToCall[msg.sender],"AccessDenied");
     uint256 saleID = presaleID.current();
     idToPreSale[saleID] = details;
     presaleID.increment();
     return(saleID);
   }

   function buyToken(address contributer, uint256 id, uint256 amountInEth) public{
     if(whiteListCondition[id]){
         require(isWhitelisted[contributer][id],"Access Denied");
     }
     require(allowedToCall[msg.sender],"AccessDenied");
     require(idToPreSale[id].amountRaised + amountInEth <= idToPreSale[id].hardCap,"Hard Cap reached");
     require(block.timestamp < idToPreSale[id].EndTime && block.timestamp > idToPreSale[id].startTime,"Window Closed");
     require(idToPreSale[id].minBuy<= amountInEth && idToPreSale[id].maxBuy>= amountInEth,"Enter a valid amount");
     totalEthRaised = totalEthRaised + amountInEth;
     idToPreSale[id].amountRaised = idToPreSale[id].amountRaised + amountInEth;
     amountContributed[contributer][id] = amountContributed[contributer][id] + amountInEth;
     amountEligible[contributer][id] = amountEligible[contributer][id] + amountInEth*idToPreSale[id].tokensPerETH;
   }

   function claimToken(address contributer, uint256 id) public{
    require(allowedToCall[msg.sender],"AccessDenied");
    require(idToPreSale[id].canClaim,"Can't Claim at the Moment");
    IERC20(idToPreSale[id].tokenAddress).transfer(contributer, amountEligible[contributer][id]);
    amountEligible[contributer][id] =0;
   }

   function withdrawContribution(address contributer, uint256 id) public returns(uint256 amountToBeReturned){
   require(allowedToCall[msg.sender],"AccessDenied");
     uint256 contributedAmount = amountContributed[contributer][id] ;
     totalEthRaised = totalEthRaised - contributedAmount;
     idToPreSale[id].amountRaised = idToPreSale[id].amountRaised - contributedAmount;
     amountContributed[contributer][id] = 0;
     amountEligible[contributer][id] = 0;  
     return((contributedAmount*penalty)/100);
    }

    function vestContribution(address contributer, uint256 id, VestingDetails memory details) public{
    //   Vesting(vestingContract).vestToken(details);
    }

    
    }
