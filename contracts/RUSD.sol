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

  address immutable nftFactoryAddress;
  address immutable vaultNFTAddress;
  address immutable usdtAddress; 
  
  INFT_FACTORY NFT;
  IERC20 USDT;

  uint minimumInvesting;

  struct CUSTUMER {
    uint intitialDate;
    uint endDate;
    bool locked;
    bool isWithdrawal;
  }

  mapping (address => CUSTUMER) custumers;

  event NEWDEPOSIT (address indexed recipient, uint amount);

  constructor (uint _minimumInvesting, address _nftFactoryAddress, address _usdtAddress, address _vaultNFTAddress) ERC20("RESERVA USD", "RUSD"){
    require(_nftFactoryAddress.isContract() && _nftFactoryAddress != address(0), "POOL: Error");
    require(_usdtAddress.isContract() && _usdtAddress != address(0), "POOL: Error");
    require(_vaultNFTAddress.isContract() && _vaultNFTAddress != address(0), "POOL: Error");
    nftFactoryAddress = _nftFactoryAddress;
    usdtAddress = _usdtAddress;
    vaultNFTAddress = _vaultNFTAddress;
    minimumInvesting =  _minimumInvesting;
  }
  /// @dev Before someone call this function, the investor had to approve the current SC
  /// to manage his USDT amount. Important trigger approve function before this
  /// current function will be called.
  function deposit (address _recipient, uint _amount) external returns (bool) {
    USDT = IERC20(usdtAddress);
    require(! _recipient.isContract() && _recipient != address(0), "POOL: Error");
    require(_amount == minimumInvesting, "Pool: The minimum of investing exceed the amount");
    USDT.transferFrom(_recipient, address(this), _amount);
    _mint(_recipient, _amount);
    custumers[_recipient].intitialDate = block.timestamp;
    custumers[_recipient].endDate = 0;
    custumers[_recipient].locked = true;
    emit NEWDEPOSIT(_recipient, _amount);
    return true;
  }

  function fundingNFT(uint tokenId) public onlyOwner returns (bool) {
    NFT = INFT_FACTORY(nftFactoryAddress);
    USDT = IERC20(usdtAddress);
    ( , ,uint balanceAdvance, , ,) = NFT.getData(tokenId);
    NFT.safeTransferFrom(NFT.ownerOf(tokenId), vaultNFTAddress, tokenId);
    USDT.transfer(NFT.ownerOf(tokenId), balanceAdvance);
    return true;
  }

  function transfer(address recipient, uint256 amount) public override returns (bool) {
    require(! custumers[recipient].locked, "POOL: Your transfer is locked");
    super.transfer(recipient, amount);
    return true;
  }


  /// @dev return true if is transfered succesfully investor's benefits
  function stakeOf(address investor) public onlyOwner returns(bool) {
    uint balanceInvestor = balanceOf(investor);
    int128 ratioOf = ABDKMath64x64.div(ABDKMath64x64.fromUInt(balanceInvestor), ABDKMath64x64.fromUInt(totalSupply()));
    uint valueToSend = ABDKMath64x64.mulu(ratioOf, balanceOf(nftFactoryAddress));
    transferFrom(nftFactoryAddress, investor, valueToSend);
    return true;
  }

  /// @dev return true if mint process is executed successfully
  function mintRewards() private returns(bool) {
    uint amount = INFT_FACTORY(nftFactoryAddress).dailyInterestRUSD();
    _mint(nftFactoryAddress, amount);
    return true;
  }

  function _calculateStakingRange(uint _endDate, uint _startDate, uint ref) pure private returns (uint stakePeriod) {
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
        return stakePeriod;
    }

  
}
