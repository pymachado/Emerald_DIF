// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract USDF is ERC20 {
	constructor() ERC20("USDF FaucetCoin", "USDF") {

	}

	function mint(address receipt, uint256 amount) public {
		require(amount <= 5000 * 10 ** decimals(), "RFS: The amount exceeds the value allowing");
		_mint(receipt, amount);
	} 

}

