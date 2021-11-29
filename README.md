# Emerald_DIF


# POOL USDT/RUSD Smart Contract
# Description
 
 This contract save all deposits of USDT from investors and clients. It is the controller to mint new rewards in RUSD at its address and forwarder it to investors in relation with their stakings. Take part to fund the new funding request that entry and send at tenant his balance advance. 

# Declared functions  

function deposit(address _recipient, uint _amount) external returns(bool)

function fundingNFT(uint tokenId) public onlyOwner returns (bool)

function transfer(address recipient, uint256 amount) public override returns (bool)

function stakeOf(address investor) public onlyOwner returns(bool)

function mintRewards() public onlyOwner returns(bool)

function _computeStakePeriod(uint _endDate, uint _startDate, uint ref) pure private returns (uint stakePeriod)

# Pending functions
 note: Pending to develop Withdraw Algorithm with list of withdraw system.
    1- requestWithdraw() by investor
    2- transferFunds() by Reserva
    3- payNFT() by client

# NFT_FACTORY Smart Contract
# Description

This contract has two jobs, one is as a FACTORY; mint all new NFT from new funding request and attach for each NFT its tenant. It's important to register the person that will be done his debt payment once the NFT will be paid by its client. 
The second job for this contract is as a Vault; the contract store all NFT that has been funding and when it is paid, contract burn the current token sending it to burn address.  

# Declared functions

function createInvoice(
        address _recipient,
        string memory _dataCustumer,
        uint _valueOfNFT,
        uint _balanceAdvance,
        uint _daysDue,
        int128 _interestRate,
        int128 _interestRateOverDue) external onlyOwner returns (bool)

function destroyNFT(uint tokenId) external onlyOwner returns(bool)

function getData(uint256 tokenId) public view returns (string memory dataCustumer, uint valueOfNFT, uint balanceAdvance, uint daysDue, int128 interestRate, int128 interestRateOverDue, address seller) 

function _assemble( string memory _dataCustumer, 
                        uint _valueOfNFT, 
                        uint _balanceAdvance,
                        uint _daysDue,
                        int128 _interestRate,
                        int128 _interestRateOverDue,
                        address _seller, 
                        bytes32 _invoiceHash) private returns(uint256)

function _interestToMint(int128 _mir, uint _amount) private returns (uint)

function _interestToBurn(int128 _mir, uint _amount) private returns (uint)

function _dir(int128 mir) pure private returns (int128) 

function _air(int128 mir) pure private returns (int128)