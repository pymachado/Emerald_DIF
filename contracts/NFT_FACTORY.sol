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

contract NFT_FACTORY is ERC721, Ownable, ERC721Enumerable {

/// @dev NFT's properties and validation system for each NFT minted. 

    struct DATA_INVOICE {
        string name;
        string description;
        string dataCustumer;
        uint256 valueOfNFT;
        uint256 balanceAdvance;
        address seller;
        bytes32 invoiceHash;
    }
    
    DATA_INVOICE[] private _dataInvoices;
    
    mapping (bytes32 => uint256) private _hashTokenId;
    mapping (bytes32 => bool) private _hashExist;

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

    function _assemble( string memory _name,
                        string memory _description,
                        string memory _dataCustumer, 
                        uint256 _valueOfNFT, 
                        uint256 _balanceAdvance,
                        address _seller, 
                        bytes32 _invoiceHash) private returns(uint256) {
                            _dataInvoices.push(DATA_INVOICE(
                                _name,
                                _description,
                                _dataCustumer, 
                                _valueOfNFT,
                                _balanceAdvance,
                                _seller,
                                _invoiceHash));
                        uint256 id = _dataInvoices.length - 1;
                        return id;
                       }

/// @dev Mint a new NFT to recipient

    function createInvoice(
        address _recipient,
        string memory _name,
        string memory _description,
        string memory _dataCustumer,
        uint256 _valueOfNFT,
        uint256 _balanceAdvance) external onlyOwner() {
            
         bytes32 invoiceHash = keccak256(abi.encodePacked(_name, _description, _dataCustumer, _valueOfNFT, _balanceAdvance, _recipient)); 
         require(! _hashExist[invoiceHash], "NFT_Factory: This hash exist already");
         _hashExist[invoiceHash] = true;
         uint256 newItemId = _assemble(
                          _name,
                          _description,
                          _dataCustumer,
                          _valueOfNFT,
                          _balanceAdvance,
                          _recipient,
                          invoiceHash);
        _mint(_recipient, newItemId);    

        }

/// @dev Insert tokenId @param and the function @return all data attached at this token

    function getData(uint256 tokenId) public view returns(string memory name, string memory description, string memory dataCustumer, uint256 valueOfNFT, uint256 balanceAdvance, address seller) {
        name =_dataInvoices[tokenId].name;
        description = _dataInvoices[tokenId].description;
        dataCustumer = _dataInvoices[tokenId].dataCustumer;
        valueOfNFT = _dataInvoices[tokenId].valueOfNFT;
        balanceAdvance = _dataInvoices[tokenId].balanceAdvance;
        seller = _dataInvoices[tokenId].seller;
    }
 
}