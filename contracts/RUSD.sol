// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/**
  @author Pedro Machado
  @title POOL USDT/RUSD
  @notice The present Smart Contract <SC> receives USDT as a strong currency 
  and mint the same amount from deposit function of RUSD. From this SC is where the PRTOCOL DIF 
  get money to funding of all INVOICE NFT that were minted by request from one tenant.    
 */

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ABDKMath64x64.sol";
import "./INFT_FACTORY.sol";


contract RUSD is ERC20, Ownable{
  using Address for address;
  
  uint constant referencePeriod = 30; 
  uint minimumInvesting;
  address immutable nftFactoryAddress;
  address immutable usdtAddress; 
  uint32 lenghtListOut;

  INFT_FACTORY NFT;
  IERC20 USDT;

  struct CUSTUMER {
    uint intitialDate;
    uint requestDate;
    uint returnDate;
    uint stakePeriod;
    uint pendingWithdraw;
    bool locked;
    bool isWithdrawal;
  }

  mapping (address => CUSTUMER) public custumers;
  // key is investor's numberList and value is requestDate 
  address[100] numberList;
  mapping (uint => uint) private _dateOuts;
  
  mapping (uint => bool) private _existRquest;

  event NEWDEPOSIT (address indexed recipient, uint amount);

  constructor (uint _minimumInvesting, address _nftFactoryAddress, address _usdtAddress) ERC20("RESERVA USD", "RUSD"){
    require(_nftFactoryAddress.isContract() && _nftFactoryAddress != address(0), "POOL: Error 0");
    require(_usdtAddress.isContract() && _usdtAddress != address(0), "POOL: Error 1");
    nftFactoryAddress = _nftFactoryAddress;
    usdtAddress = _usdtAddress;
    minimumInvesting =  _minimumInvesting;
  }
  /// @dev Before someone call this function, the investor had to approve the current SC
  /// to manage his USDT amount. Important trigger approve function before this
  /// current function will be called.
  function deposit (address _investor, uint _amount) external returns (bool) {
    USDT = IERC20(usdtAddress);
    require(! _investor.isContract() && _investor != address(0), "POOL: Error");
    require(_amount >= minimumInvesting, "Pool: The minimum of investing exceed the amount");
    USDT.transferFrom(_investor, address(this), _amount);
    _mint(_investor, _amount);
    custumers[_investor].intitialDate = _now();
    custumers[_investor].locked = true;
    emit NEWDEPOSIT(_investor, _amount);
    return true;
  }

  function fundingNFT(uint tokenId) public onlyOwner returns (bool) {
    NFT = INFT_FACTORY(nftFactoryAddress);
    USDT = IERC20(usdtAddress);
    ( , ,uint balanceAdvance, , , ,) = NFT.getData(tokenId);
    NFT.safeTransferFrom(NFT.ownerOf(tokenId), nftFactoryAddress, tokenId);
    USDT.transfer(NFT.ownerOf(tokenId), balanceAdvance);
    return true;
  }


  function transferFunds(address investor) public onlyOwner returns(bool) {
    USDT = IERC20(usdtAddress);
    require(numberList[0] != address(0), "POOL: List is out");
    require(numberList[0] == investor, "POOL: This investor is not the first in the list");
    require(USDT.balanceOf(address(this)) >= balanceOf(investor), "POOL: There's no funds enough");
    uint range = 0;
    while (numberList[range] != address(0)) {
      range++;
    }

    for (uint i = 0; i <= range; i++) {
      numberList[i] = numberList[i+1];
      range--;
    }
    
    uint balanceRUSD = balanceOf(investor);
    USDT.transfer(investor, balanceRUSD);
    _burn(investor, balanceRUSD);
    return true;
  }

  function requestWithdraw(address investor, uint amount) public returns(bool) {
    
  }


  /// @dev return true if it is transfered succesfully investor's benefits. 
  /// This function is called once by day after mintRewars().
  function stakeOf(address investor) public onlyOwner returns(bool) {
    int128 _ratioOf = ABDKMath64x64.divu(balanceOf(investor), totalSupply()); 
    uint valueToSend = ABDKMath64x64.mulu(_ratioOf, balanceOf(address(this)));
    transfer(investor, valueToSend);
    return true;
  }

  /// @dev return true if it mint process is executed successfully
  /// This function is called once by day, before that stakeOf(address investor)
  function mintRewards() public onlyOwner returns(bool) {
    uint amount = INFT_FACTORY(nftFactoryAddress).dailyInterestRUSD();
    _mint(address(this), amount);
    return true;
  }

  function _now() public view returns(uint) {
      return block.timestamp;
    }

    
  function _computeStakePeriod(uint _endDate, uint _startDate, uint ref) pure private returns (uint stakePeriod, uint remainingTime) {
        require(_endDate != 0 && _startDate != 0 && ref != 0, "Error");
        uint stampTime = SafeMath.div( SafeMath.sub(_endDate, _startDate), 1 days);
        require(stampTime >= ref, "Pool: You have to need complete at least one stake period.");
        uint r = stampTime % ref;
        if (r != 0) {
            stakePeriod = stampTime + (ref - r);
        }
        else {
            stakePeriod = stampTime;
        }   
        return (stakePeriod, ref - r);
    }

    

  
}
