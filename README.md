# Emerald_DIF

# Pending Smart Contracts

name: VAULTNFT
description: this contract save all NFT funded.

# POOL USDDT/RUSD Smart Contract

# Declared functions  

function deposit(address _recipient, uint _amount) external returns(bool)

function fundingNFT(uint tokenId) public onlyOwner returns (bool)

function transfer(address recipient, uint256 amount) public override returns (bool)

function stakeOf(address investor) public onlyOwner returns(bool)

function mintRewards() private returns(bool)

function _calculateStakingRange(uint _endDate, uint _startDate, uint ref) pure private returns (uint stakePeriod)

# Pending functions
 note: Pending to develop Withdraw Algorithm with list of withdraw system.
    1- requestWithdraw();
    2- transferFunds();

