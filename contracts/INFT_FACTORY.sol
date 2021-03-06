// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface INFT_FACTORY is IERC721 {
  function getData(uint256 tokenId) external view returns(string memory,
                                                          uint,
                                                          uint,
                                                          uint,
                                                          int128,
                                                          int128,
                                                          address);

  function dailyInterestRUSD() external view returns(uint);

  function burnAddress() external view returns(address);

}
