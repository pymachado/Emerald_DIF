// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface INFT_FACTORY is IERC721 {
  function getData(uint256 tokenId) external view returns(string memory,
                                                          string memory,
                                                          string memory,
                                                          uint256,
                                                          uint256,
                                                          address);
}
