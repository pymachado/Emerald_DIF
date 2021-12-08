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
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/SignedSafeMath.sol";
import "./ABDKMath64x64.sol";


contract NFT_FACTORY is ERC721, Ownable, ERC721Enumerable, IERC721Receiver {
    uint public dailyInterestRUSD;
    address constant burnAddress = 0x000000000000000000000000000000000000dEaD;
    



/// @dev NFT's properties and validation system for each NFT minted. 

    struct DATA_INVOICE {
        string dataCustumer;
        uint256 valueOfNFT;
        uint256 balanceAdvance;
        uint256 dateOverDue;
        int128 interestRate;
        int128 interestRateOverDue;
        address seller;
    }

    
    DATA_INVOICE[] private _dataInvoices;
    
    mapping (bytes32 => uint256) private _hashTokenId;
    mapping (bytes32 => bool) private _hashExist;

    event RATIOCHANGED(int128 indexed newRatio);

    constructor() ERC721("Decentralized Invoice Factoring", "DIF") { }

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
    
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

/// @dev Mint a new NFT to recipient

    function createInvoice(DATA_INVOICE memory _invoice) external onlyOwner returns (bool) {            
            bytes32 invoiceHash = keccak256(abi.encodePacked(_invoice.dataCustumer,
            _invoice.valueOfNFT, _invoice.balanceAdvance, _invoice.dateOverDue,
            _invoice.interestRate, _invoice.interestRateOverDue, _invoice.seller )); 
            require(! _hashExist[invoiceHash], "NFT_Factory: This hash exist already");
            _hashExist[invoiceHash] = true;
            uint256 newItemId = _assemble(_invoice);
            _mint(_invoice.seller, newItemId);
            _interestToMint(_invoice.interestRate, _invoice.valueOfNFT);
            return true;
        }
///@dev Burn one NFT when is paid and reduce of Fund's dailyInterest 
    function destroyNFT(uint tokenId) external onlyOwner returns(bool) {
        int128 mir = _dataInvoices[tokenId].interestRate;
        uint amount = _dataInvoices[tokenId].valueOfNFT;
        uint dateOverDue = _dataInvoices[tokenId].dateOverDue;
        if (_now() > dateOverDue) {
            _interestToBurnOverDue(tokenId);
        }
        else {
            _interestToBurn(mir, amount);
        }
        transferFrom(address(this), burnAddress, tokenId);
        return true;
    }

/// @dev Insert tokenId @param and the function @return all data attached at this token

    function getData(uint256 tokenId) public view returns (string memory dataCustumer, uint valueOfNFT, uint balanceAdvance, uint dateOverDue, int128 interestRate, int128 interestRateOverDue, address seller) {
        dataCustumer = _dataInvoices[tokenId].dataCustumer;
        valueOfNFT = _dataInvoices[tokenId].valueOfNFT;
        balanceAdvance = _dataInvoices[tokenId].balanceAdvance;
        dateOverDue = _dataInvoices[tokenId].dateOverDue;
        interestRate = _dataInvoices[tokenId].interestRate;
        interestRateOverDue = _dataInvoices[tokenId].interestRateOverDue;
        seller = _dataInvoices[tokenId].seller;
    }


/// @dev Private function to assemble one NFT and @return a single id for each token minted.

    function _assemble( DATA_INVOICE memory _invoice) private returns(uint256) {
        _dataInvoices.push(_invoice);
        uint256 id = _dataInvoices.length - 1;
        return id;
        }

    function interestToMintOverDue(uint tokenId) public onlyOwner returns(uint) {
        ( , , , uint dateOverDue, int128 _mir, int128 _odmir,) = getData(tokenId);
        if (dateOverDue > _now() && ownerOf(tokenId) != burnAddress) {
            uint dir = ABDKMath64x64.mulu(_dir(_mir), 1*10**18);
            uint oddir = ABDKMath64x64.mulu(_dir(_odmir), 1*10**18);
            uint df = SafeMath.sub(oddir, dir);
            dailyInterestRUSD = SafeMath.add(dailyInterestRUSD, df);
        }
        return dailyInterestRUSD;
    }

    function _interestToBurnOverDue(uint tokenId) private returns(uint) {
        ( , , , , , int128 _odmir,) = getData(tokenId);
        uint oddir = ABDKMath64x64.mulu(_dir(_odmir), 1*10**18);
        dailyInterestRUSD = SafeMath.sub(dailyInterestRUSD, oddir);
        return dailyInterestRUSD;
    } 
 
    function _interestToMint(int128 _mir, uint _amount) private returns (uint){
        uint newInterestToMint = ABDKMath64x64.mulu(_dir(_mir), _amount);
        return dailyInterestRUSD = SafeMath.add(dailyInterestRUSD, newInterestToMint) ;
    }

    function _interestToBurn(int128 _mir, uint _amount) private returns (uint) {
        uint newInterestToBurn = ABDKMath64x64.mulu(_dir(_mir), _amount);
        return dailyInterestRUSD = SafeMath.sub(dailyInterestRUSD, newInterestToBurn);
    }

    function _dir(int128 mir) pure private returns (int128) {
      return ABDKMath64x64.sub(ABDKMath64x64.exp_2(ABDKMath64x64.mul(ABDKMath64x64.inv(ABDKMath64x64.fromUInt(365)), ABDKMath64x64.log_2(_air(mir)))), ABDKMath64x64.fromUInt(1));
    }

    function _air(int128 mir) pure private returns (int128) {
        return ABDKMath64x64.pow(ABDKMath64x64.add(ABDKMath64x64.fromUInt(1), mir), 12);
    }

    function _now() private view returns(uint) {
        return block.timestamp;
    }
    
 
}