// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "./INFT_FACTORY.sol";

contract Pool is Ownable, IERC721Receiver, IERC165 {
  using Counters for Counters.Counter;
  using Address for address;
  uint256 public constant interest = 1;
  uint256 public constant stakingDays = 30;
  uint256 public minInvesting;
  uint256 public marginInvestment;
  Counters.Counter public _numberOfInvestment;
  Counters.Counter public _numberOfInvestors;
  IERC20 currency;
  INFT_FACTORY nft;

  struct Investor {
    uint256 totalInvested;
    mapping(uint256 => uint256) _investments;
    uint256[] _indexOfDate;
  }

  mapping (address => Investor) private _investors;
  mapping (address => bool) private _isExist;

  event Deposit(address indexed investor, uint256 indexed date, uint256 indexed amount);
  event Funding(uint256 indexed tokenId, address indexed ownerOfNFT, uint256 amountFounding);
  event ChangedDebtLiquidator(address indexed newMp, uint256 indexed time);

  constructor(
    address addressCurrency,
    address addressNFT, 
    uint256 MinInvesting, uint256 MarginInvestment) {
      minInvesting = MinInvesting;
      currency = IERC20(addressCurrency);
      nft = INFT_FACTORY(addressNFT);
      marginInvestment = MarginInvestment;
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(INFT_FACTORY).interfaceId 
        || interfaceId == type(IERC20).interfaceId 
        || interfaceId == type(IERC721Receiver).interfaceId; 
  }

  function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
  }
   
  function investmentOf(address investor) external view returns(uint256 totalInvested) {
      totalInvested = _investors[investor].totalInvested;
  }

  function _liquidity() public view returns(uint256 liquidity) {
    liquidity = currency.balanceOf(address(this));
  }

  /*
  function _stakingDays(uint256 newStakingDays) external onlyOwner(_msgSender()) returns(bool) {
    stakingDays = newStakingDays;
    return true;
  }
  */

  function _minInvesting(uint256 newMinInvesting) external onlyOwner() returns(uint256) {
    return minInvesting = newMinInvesting;
  }

  function _marginInvestment(uint256 newMarginInvestmment) external onlyOwner() returns(uint256){
    return marginInvestment = newMarginInvestmment;
  }

  function remainingTimeToWithdraw(address investor, uint256 indexOfdate) public view returns(uint256) {
    return (block.timestamp - _investors[investor]._indexOfDate[indexOfdate] ) / 1 minutes;
  } 

  function _swapDebtLiquidator(address dl) external onlyOwner() {
    require(dl.isContract(), "Pool: The address inserted is not a contract address");
    require(IERC165(dl).supportsInterface(this._swapDebtLiquidator.selector), "Pool: The contract is not compatible");
    nft.setApprovalForAll(dl, true);
    emit ChangedDebtLiquidator(dl, block.timestamp);
  }

  function deposit(uint256 _amount) external {
    require(_amount != 0, "POOL: The amount can't be 0");
    require(_amount >= minInvesting, "POOL: Min investing exceeds the amount.");
    if (! _isExist[_msgSender()]) {_numberOfInvestors.increment();}
    //use approve function from web3 to allow the transaction
    currency.transferFrom(_msgSender(), address(this), _amount);
    _investors[_msgSender()].totalInvested += _amount;  
    _investors[_msgSender()]._investments[block.timestamp] = _amount;
    _investors[_msgSender()]._indexOfDate.push(block.timestamp);
    _isExist[_msgSender()] = true;
    emit Deposit(_msgSender(),block.timestamp, _amount);
  }

  function withdraw(uint256 _valueWithdrawal, uint256 indexOfdate) external {
    require(_isExist[_msgSender()], "POOL: Your are not an investor registered.");
    uint256 daysPassed = remainingTimeToWithdraw(_msgSender(), indexOfdate);
    uint256 count = daysPassed/stakingDays;
    require(count >= 1);
    uint256 dateOf = _investors[_msgSender()]._indexOfDate[indexOfdate];
    uint256 totalAmountToWithdraw =_investors[_msgSender()]._investments[dateOf] += _profit(count * interest, _investors[_msgSender()]._investments[dateOf]);
    require(_valueWithdrawal <= totalAmountToWithdraw, "You don't have that amount of money");
    currency.transfer(_msgSender(), _valueWithdrawal);
    _investors[_msgSender()]._investments[dateOf] -= _valueWithdrawal;
    _investors[_msgSender()]._indexOfDate[indexOfdate] = block.timestamp;
    emit Deposit(_msgSender(), block.timestamp, _valueWithdrawal);
  }  

  function funding(uint256 _tokenId, uint256 _amount) external onlyOwner() {
    require(_liquidity() - _amount > marginInvestment, "POOL: The amount lees than the marging of investing.");
    (, , , , uint256 balanceAdvance, ) = nft.getData(_tokenId);
    require(_amount == balanceAdvance, "POOL: The amount not match with token's price of sell");
    address ownerOfNFT = nft.ownerOf(_tokenId);
    currency.transfer(ownerOfNFT, _amount);
    nft.safeTransferFrom(ownerOfNFT, address(this), _tokenId);
    _numberOfInvestment.increment();
    emit Funding(_tokenId, ownerOfNFT, _amount);
  }

  function _profit(uint256 _interestInPorcentage, uint256 _amount) private pure returns(uint256) {
     uint256 value = (_interestInPorcentage * _amount) / (100);
     return value;
  }

}

