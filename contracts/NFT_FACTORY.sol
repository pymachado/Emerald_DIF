// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/** @title NFT_FACTORY
    @author Pedro Yuris Machado Leiva
    @notice Smart Contract to mint NFTs that represent a real factoring invoices 
    @custom:company Reserva Food System
    @custom:addressMumbai 0x5673a930Da6dB358E86B532d9d1B3941c5F64Aa3
*/

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./ABDKMath64x64.sol";


contract NFT_FACTORY is ERC721, Ownable, ERC721Enumerable {
    uint public dailyInterestRUSD;



/// @dev NFT's properties and validation system for each NFT minted. 

    struct DATA_INVOICE {
        string dataCustumer;
        uint256 valueOfNFT;
        uint256 balanceAdvance;
        int128 interestRate;
        int128 interestRateOverDue;
        address seller;
        bytes32 invoiceHash;
    }
    
    DATA_INVOICE[] private _dataInvoices;
    
    mapping (bytes32 => uint256) private _hashTokenId;
    mapping (bytes32 => bool) private _hashExist;

    event RATIOCHANGED(int128 indexed newRatio);

    constructor() ERC721("Decentralized Invoice Factoring", "DIF") {}

/// @dev The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }


    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

/// @dev Private function to assemble one NFT and @return a single id for each token minted.

    function _assemble( string memory _dataCustumer, 
                        uint256 _valueOfNFT, 
                        uint256 _balanceAdvance,
                        int128 _interestRate,
                        int128 _interestRateOverDue,
                        address _seller, 
                        bytes32 _invoiceHash) private returns(uint256) {
                            _dataInvoices.push(DATA_INVOICE(
                                _dataCustumer, 
                                _valueOfNFT,
                                _balanceAdvance,
                                _interestRate,
                                _interestRateOverDue,
                                _seller,
                                _invoiceHash));
                        uint256 id = _dataInvoices.length - 1;
                        return id;
                       }

/// @dev Mint a new NFT to recipient

    function createInvoice(
        address _recipient,
        string memory _dataCustumer,
        uint256 _valueOfNFT,
        uint256 _balanceAdvance,
        int128 _interestRate,
        int128 _interestRateOverDue) external onlyOwner {
            
         bytes32 invoiceHash = keccak256(abi.encodePacked(_dataCustumer, _valueOfNFT, _balanceAdvance, _interestRate, _interestRateOverDue ,_recipient)); 
         require(! _hashExist[invoiceHash], "NFT_Factory: This hash exist already");
         _hashExist[invoiceHash] = true;
         uint256 newItemId = _assemble(
                          _dataCustumer,
                          _valueOfNFT,
                          _balanceAdvance,
                          _interestRate,
                          _interestRateOverDue,
                          _recipient,
                          invoiceHash);
        _mint(_recipient, newItemId);
        interestToMint(_interestRate, _valueOfNFT);
        
        }
///@dev Burn one NFT when is paid and reduce of Fund's dailyInterest 
    function destroyNFT(uint tokenId) external onlyOwner {
        int128 mir = _dataInvoices[tokenId].interestRate;
        uint amount = _dataInvoices[tokenId].valueOfNFT;
        interestToBurn(mir, amount);(_dataInvoices[tokenId].interestRate);
        _burn(tokenId);
    }

/// @dev Insert tokenId @param and the function @return all data attached at this token

    function getData(uint256 tokenId) public view returns(string memory dataCustumer, uint256 valueOfNFT, uint256 balanceAdvance, int128 interestRate, int128 interestRateOverDue, address seller) {
        dataCustumer = _dataInvoices[tokenId].dataCustumer;
        valueOfNFT = _dataInvoices[tokenId].valueOfNFT;
        balanceAdvance = _dataInvoices[tokenId].balanceAdvance;
        interestRate = _dataInvoices[tokenId].interestRate;
        interestRateOverDue = _dataInvoices[tokenId].interestRateOverDue;
        seller = _dataInvoices[tokenId].seller;
    }

    // invoice interest rate = 1%,  interestRatioOfNFT = 0.01
    // 
 
    function interestToMint(int128 _mir, uint _amount) private returns(uint){
        uint newInterestToMint = ABDKMath64x64.mulu(dir(_mir), _amount);
        return dailyInterestRUSD = SafeMath.add(dailyInterestRUSD, newInterestToMint) ;
    }

    function interestToBurn(int128 _mir, uint _amount) private returns(uint) {
        uint newInterestToBurn = ABDKMath64x64.mulu(dir(_mir), _amount);
        return dailyInterestRUSD = SafeMath.sub(dailyInterestRUSD, newInterestToBurn);
    }

    function dir(int128 mir) pure private returns(int128) {
      return ABDKMath64x64.sub(ABDKMath64x64.exp_2(ABDKMath64x64.mul(ABDKMath64x64.inv(ABDKMath64x64.fromUInt(365)), ABDKMath64x64.log_2(air(mir)))), ABDKMath64x64.fromUInt(1));
    }

    function air(int128 mir) pure private returns(int128) {
        return ABDKMath64x64.pow(ABDKMath64x64.add(ABDKMath64x64.fromUInt(1), mir), 12);
    }
    
 
}