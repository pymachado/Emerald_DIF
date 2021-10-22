// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./INFT_FACTORY.sol";


interface IPool {
   function _changedDebtLiquidator(address dl) external returns (bool);
   function interest() external view returns(uint256);
}

contract DebtLidquidator is ERC165{
  IERC20 currency;
  INFT_FACTORY nft;
  uint256 public constant interestReserva = 1;
  address public constant burnAddress = 0x0000000000000000000000000000000000000001;
  address public escrowReserva;
  address public pool;

  mapping (address => uint256[]) public liquidatedDebts;
  event LiquidatedDebt(address indexed buyer, uint256 tokenId);

  constructor(address _currency, address _nft, address _pool,address _escrowReserva) {
    currency = IERC20(_currency);
    nft = INFT_FACTORY(_nft);
    pool = _pool;
    escrowReserva = _escrowReserva;
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC20).interfaceId
            || interfaceId == type(INFT_FACTORY).interfaceId 
            || interfaceId == type(IPool).interfaceId || super.supportsInterface(interfaceId);
  }

  function pay(uint256 _tokenId, uint256 _value) public virtual {
    (, , ,uint256 valueOfNFT, uint256 balanceAdvance, address seller) = nft.getData(_tokenId);
    require(valueOfNFT == _value, "Marketplace: The value that you try to pay not match with the value of NFT");
    //use approve function from web3 to allow the transaction
    uint256 toPool = balanceAdvance + _profit(IPool(pool).interest(), balanceAdvance);
    uint256 toReserva = _profit(interestReserva, _value - toPool);
    uint256 toSeller = _value - toPool - toReserva;
    currency.transferFrom(msg.sender, pool, toPool);
    currency.transferFrom(msg.sender, escrowReserva, toReserva);
    currency.transferFrom(msg.sender, seller, toSeller);
    nft.transferFrom(pool, burnAddress, _tokenId);
    liquidatedDebts[msg.sender].push(_tokenId);
    emit LiquidatedDebt(msg.sender, _tokenId);
  }

  function _profit(uint256 _interestInPorcentage, uint256 _amount) private pure returns(uint256) {
     uint256 value = (_interestInPorcentage * _amount) / (100);
     return value;
  }
  
}

