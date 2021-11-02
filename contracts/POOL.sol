// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/** @title POOL
    @author Pedro Yuris Machado Leiva
    @notice EMERALD'S POOL for funding invoices 
    @custom:company Reserva Food System
    @custom:addressMumbai 0x551Ac0554d606688CabaC753Cc62EA32f3309551
*/

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract POOL is Ownable {
  uint256 public minimumRangeOfStake;
  uint256 public liquidity;
  uint256 public minInvesting;
  uint256 public yield;

  IERC20 erc20;

  struct Investment {
    address owner;
    uint256 amount;
    uint256 startDate;
  }

  /**
    @dev ledger of investments. Each index represent one of them 
    and the length is the total investment's number. 
   */  
  Investment[] private _investments;

  /** 
    @dev slip's ledger in case of size pool is less than the investment request to withdraw. 
    Index represent the priority range for pay once size pool is filled. 
    index VS indexInv
    */
  uint256[] private _ledgerOfDebt;

  /**
    @dev that ledger define if investment from index have been liquidated
   */
  mapping (uint256 => bool) private _isLiquidated;

  mapping (uint256 => address) private _indexApproved;

  mapping (address => mapping (uint256 => uint256)) private _investmentOfOownerByIndex;
  mapping (address => uint256) private _balanceOf;

  event DEPOSITED (address indexed investor, uint256 amount, uint256 indexed index);
  event ADDEDYIELD (uint256 indexed amount, uint256 indexed date);
  event NEWUSERADDEDATLEDGEROFDEBT (address indexed investor, uint256 indexed index);
  event WITHDRAWAL (address indexed investor, uint256 indexed index);

  constructor(address ERC20, uint256 _minInvesting) {
    erc20 = IERC20(ERC20);
    minInvesting = _minInvesting;
    minimumRangeOfStake = 3 minutes;
  } 


  function poolSize() view public returns(uint256) {
    return liquidity + yield;
  }

  function balanceOf(address investor) view external returns(uint256) {
    return _balanceOf[investor];
  }

  function investmentOfOwnerByIndex(address investor, uint256 index) view external returns(uint256) {
    require(index <= _balanceOf[investor]);
    return _investmentOfOownerByIndex[investor][index];
  }

  function isLiquidated(uint256 index) view public returns(bool) {
    return _isLiquidated[index];
  }

  function isInLedgerOfDebt(uint256 index) view external returns(bool) {
    bool value = false;
    for (uint256 i = _ledgerOfDebt.length; i >= 0; i-- ) {
      if (_ledgerOfDebt[i] == index)
      value = true;
    }
    return value;
  }

  function set_MinimumRangeOfStake(uint256 _minimumRangeOfStake) external onlyOwner {
    minimumRangeOfStake = _minimumRangeOfStake * 1 minutes;
  }


  function deposit(uint256 amount) external {
    //endDate should be in UNIX time system
    uint256 startDate = block.timestamp;
    require(amount >= minInvesting, "Pool: The amount should be major than minimum of investing");
    _investments.push(Investment(_msgSender(), amount, startDate));
    liquidity += amount;
    _balanceOf[_msgSender()] += 1;
    _investmentOfOownerByIndex[_msgSender()][_balanceOf[_msgSender()]] = _investments.length - 1;
    erc20.transferFrom(_msgSender(), address(this), amount);
    emit DEPOSITED(_msgSender(), amount, _investments.length - 1);
  }


  function returnDebt() onlyOwner external {
    for (uint256 i = _ledgerOfDebt.length; i >= 0; i--) {
      if ( _ledgerOfDebt[i] != 0) {
        address owner = _investments[_ledgerOfDebt[i]].owner;
        uint256 amount = _investments[_ledgerOfDebt[i]].amount;
        uint256 valueToTransfer = amount + _rewardOf(_ledgerOfDebt[i]);
        if ( valueToTransfer >= poolSize()) {
          erc20.transfer(owner, valueToTransfer);
          _isLiquidated[_ledgerOfDebt[i]] = true;
          liquidity -= amount;
          yield -= _rewardOf(_ledgerOfDebt[i]);
          delete _ledgerOfDebt[i];
        }
      }
    }
  }

  function withdraw(uint256 index) external {
    address owner = _investments[index].owner;
    require(_msgSender() == owner || _msgSender() == _indexApproved[index]);
    _withdraw(index);
  }


  function approve (address operator, uint256 index) external {
    address owner = _investments[index].owner;
    require(owner != address(0));
    require(operator != address(0));
    require(owner == _msgSender(), "Pool: You are not the owner of investment");
    _indexApproved[index] = operator;
  }


  function addYield(uint256 amount) internal {
    yield += amount;
    emit ADDEDYIELD(amount, block.timestamp);
  }

  function _withdraw(uint256 index) private {
    address owner = _investments[index].owner;
    uint256 amount = _investments[index].amount;
    uint256 start = _investments[index].startDate;
    uint256 valueToTransfer = amount + _rewardOf(index);
    require(block.timestamp - start >= minimumRangeOfStake, "Pool: You still in staking period.");
    require(! _isLiquidated[index], "Pool: That investment have been withdrawal already.");
    if (poolSize() < valueToTransfer) {
      _ledgerOfDebt.push(index);
      emit NEWUSERADDEDATLEDGEROFDEBT(owner, index);
    }
    else {
      erc20.transfer(owner, valueToTransfer);
      _isLiquidated[index] = true;
      liquidity -= amount;
      yield -= _rewardOf(index);
      emit WITHDRAWAL(owner, index);
    }

  }

  // Calculate pro-rate for each investor's stake in liquidity
  function _rewardOf(uint256 index) view private returns(uint256) {
    uint256 reward = (_stakeOf(index) / 100) * yield;
    return reward;
  }
 
  // Calcule investor's stake % generate from his investment
  function _stakeOf(uint256 index) view private returns(uint256) {
    uint256 amount = _investments[index].amount;
    uint256 stake = (amount / liquidity) * 100;
    return stake; 
  }

}
