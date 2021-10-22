import json
from logging import error, log
from web3 import Web3
from web3._utils.events import DataArgumentFilter
from web3.logs import DISCARD

#https://polygon-mumbai.infura.io/v3/de736e9690cc464cbd7000a8ec2f6fe2
#https://rpc-mumbai.matic.today

class BLOCKCHAIN_SELECTOR:
    
    def __init__(self): 
        self.providers = {
            'develop': "http://127.0.0.1:9545/",
            'ganache': "http://127.0.0.1:7545/",
            'mumbai': "https://rpc-mumbai.matic.today",
            'matic': "https://polygon-mainnet.infura.io/v3/de736e9690cc464cbd7000a8ec2f6fe2"
        }

        self.networkScan = {
            'mainnet': "https://polygonscan.com/",
            'mumbai': "https://mumbai.polygonscan.com/", 
            'develop': "http://127.0.0.1:9545/"
        }

        self.data = {
            'number_confirmations': "",
            'link_polygonscan': "",
            'tx_receipt': "",
            'tx_argsEvent': "" 
        }
    
    def _setProvider(self, provider):
        return self.providers[provider]

    def _setNetwork(self, network):
        return self.networkScan[network]

    def _plotHash(self, tx_hash, baseLink):
        if (tx_hash !=0):
            return baseLink + 'tx/' + tx_hash


class NFT_FACTORY(BLOCKCHAIN_SELECTOR):
    # nft_factory_path = 'build/contracts/NFT_Factory.json'   
    # build/contracts/NFT_FACTORY.json 
    def __init__(self, _smartContract_path, _addressSmartContract, provider, network): 
        super().__init__()
        self.w3 = Web3(Web3.HTTPProvider(self._setProvider(provider)))
        self.network = self._setNetwork(network)
        self.nft_factory_path = _smartContract_path
        self.addressSmartContract = _addressSmartContract
        with open(self.nft_factory_path) as file:
            self.nft_json = json.load(file)
            self.nft_abi = self.nft_json['abi']

        
        self.nftContract = self.w3.eth.contract(address=self.addressSmartContract, abi=self.nft_abi)

    # Function that return a total supply of NFT minted 
    def get_TotalSupply(self):
        return self.nftContract.functions.totalSupply().call()

    # Function that return a list with a each tokenId onwership of caller of function
    def get_TotalTokenOfOwnerByIndex(self, owner):
        totalOfToken = []
        length = self.nftContract.functions.balanceOf(owner).call()
        for i in range(1, length+1):
            totalOfToken.append(self.nftContract.functions.tokenOfOwnerByIndex(owner, i).call())
        return totalOfToken

    # Function through index to return the token id. 
    def get_TokenByIndex(self, index):
        return self.nftContract.functions.tokenByIndex(index).call()
    
    # Function that return all NFT's data
    def get_Data(self, tokenid):
        return self.nftContract.functions.getData(tokenid).call()

    # Function that return a total NFT burned. All token from 0x00...1 address
    def get_TotalNFTBurned(self):
        totalBurned = self.nftContract.functions.balanceOf('0x0000000000000000000000000000000000000001').call()
        return totalBurned;
    
    # Function that return NFT's owner
    def get_OwnerOf(self, tokenId):
        return self.nftContract.functions.ownerOf(tokenId).call()

    # Function that return the Admin address of system    
    def get_Admin(self):
        return self.nftContract.functions.owner().call()

    # Function to change the admin address
    def set_TransferOwnership(self, adminAddress):
        gasLimit = self.nftContract.functions.transferOwnership().estimateGas()
        tx_hash = self.nftContract.functions.transferOwnership().transact({'from': adminAddress, 'gas': gasLimit})
        currentBlock = self.w3.eth.get_block_number
        tx_receipt = self.w3.eth.wait_for_transaction_receipt(tx_hash)
        tx_event = self.nftContract.events.OwnershipTransferred().processReceipt(tx_receipt, erros=DISCARD)
        minedBlock = tx_receipt['blockNumber']
        confirmations = abs(minedBlock - currentBlock)
        self.data['number_confirmations'] = confirmations
        self.data['link_polygonscan'] = super()._plotHash(tx_hash, self.networkScan)
        self.data['tx_receipt'] = tx_receipt
        self.data['tx_event'] = tx_event[0]['args']
        return self.data

    # Function to mint a new NFT; its just called from the admin address
    def set_CreateInvoiceLocal(self, adminAddres, name, description, dataCustumer, valueOfNFT, balanceAdvance, seller):
        gasLimit = self.nftContract.functions.createInvoice(name,
                                                            description,
                                                            dataCustumer,
                                                            valueOfNFT,
                                                            balanceAdvance,seller).estimateGas()
        tx_hash = self.nftContract.functions.createInvoice(name,
                                                           description,
                                                           dataCustumer,
                                                           valueOfNFT,
                                                           balanceAdvance,
                                                           seller).transact({'from': adminAddres, 'gas': gasLimit})
        currentBlock = self.w3.eth.get_block_number
        tx_receipt = self.w3.eth.wait_for_transaction_receipt(tx_hash)
        minedBlock = tx_receipt['blockNumber']
        confirmations = abs(minedBlock - currentBlock)
        self.data['number_confirmations'] = confirmations
        self.data['link_polygonscan'] = super()._plotHash(tx_hash, self.networkScan)
        self.data['tx_receipt'] = tx_receipt
        return self.data



    def set_CreateInvoicePublic(self, adminAddress, adminPrivateKey, seller, name, description, dataCustumer, valueOfNFT, balanceAdvance):
        gasLimit = self.nftContract.functions.createInvoice(seller,
                                                            name,
                                                            description,
                                                            dataCustumer,
                                                            valueOfNFT,
                                                            balanceAdvance,
                                                            ).estimateGas()
        nonce = self.w3.eth.get_transaction_count(adminAddress)
        raw_tx = self.nftContract.functions.createInvoice(seller,
                                                          name,
                                                          description,
                                                          dataCustumer,
                                                          valueOfNFT,
                                                          balanceAdvance,
                                                        ).buildTransaction(
                                                               {
                                                                   'chainId': self.w3.eth.chain_id,
                                                                   'gas': gasLimit,
                                                                   'nonce': nonce
                                                               }
                                                           )
        signed_tx =  self.w3.eth.account.sign_transaction(raw_tx, private_key=adminPrivateKey)
        tx_hash = self.w3.eth.send_raw_transaction(signed_tx.rawTransaction)  
        #currentBlock = self.w3.eth.get_block_number
        #tx_receipt = self.w3.eth.wait_for_transaction_receipt(tx_hash)
        #minedBlock = tx_receipt['blockNumber']
        #confirmations = abs(minedBlock - currentBlock)
        #self.data['number_confirmations'] = confirmations
        #self.data['link_polygonscan'] = super()._plotHash(tx_hash, self.networkScan)
        #self.data['tx_receipt'] = tx_receipt
        return tx_hash

    # Function to approve POOL to manage a tokenId
    def set_Approve(self, fromAddress, toAddress, tokenId):
        gasLimit = self.nftContract.functions.approve(toAddress, tokenId).estimateGas()
        tx_hash = self.nftContract.functions.approve(toAddress, tokenId).transact({'from': fromAddress, 'gas': gasLimit})
        currentBlock = self.w3.eth.get_block_number
        tx_receipt = self.w3.eth.wait_for_transaction_receipt(tx_hash)
        tx_event = self.nftContract.events.Approval().processReceipt(tx_receipt, erros=DISCARD)
        minedBlock = tx_receipt['blockNumber']
        confirmations = abs(minedBlock - currentBlock)
        self.data['number_confirmations'] = confirmations
        self.data['link_polygonscan'] = super()._plotHash(tx_hash, self.networkScan)
        self.data['tx_receipt'] = tx_receipt
        self.data['tx_event'] = tx_event[0]['args']
        return self.data

    # Function to listen the event Mint; must to be always pinned 
    def listenEventMint(self):
        mint_filter = self.nftContract.events.Transfer.createFilter(fromBlock='latest', argument_filters={'from':'0x0000000000000000000000000000000000000000'})
        return mint_filter.get_new_entries()
    

#nftClass = NFT_FACTORY('build/contracts/NFT_FACTORY.json','0x0d652741d37d0FC70F17c923DD4de9eAdF02D6B2', 'develop', 'develop')

nftClassMumbai = NFT_FACTORY('build/contracts/NFT_FACTORY.json','0x5673a930Da6dB358E86B532d9d1B3941c5F64Aa3', 'mumbai', 'mumbai')
#account = nftClassMumbai.w3.eth.account.create()
#balance = nftClassMumbai.w3.eth.get_balance('0xD82709678672920A9DcDA17d1B9eE5213E0472e8')
#print(nftClassMumbai.w3.fromWei(balance, 'ether'))
#new owner.address: 0xD82709678672920A9DcDA17d1B9eE5213E0472e8
#new owner.privateKey: 0xdc1b2c6a0baf2450ed438ee96747874b1145ce988e919e42d4b3e02626c19f40
#print(account.address)
#print(nftClassMumbai.w3.toHex(account.privateKey))
#a = BLOCKCHAIN_SELECTOR()
#print(json.JSONEncoder().encode(nftClassMumbai.nft_abi))
#print(a._setProvider('develop'))
#print(nftClassMumbai.get_TotalSupply())
#print(nftClassMumbai.get_TotalNFTBurned())
#print(nftClassMumbai.w3.eth.chain_id)
data = nftClassMumbai.set_CreateInvoicePublic(
    '0xD82709678672920A9DcDA17d1B9eE5213E0472e8',
    '0xdc1b2c6a0baf2450ed438ee96747874b1145ce988e919e42d4b3e02626c19f40',
    '0x79d2B3b4D0115F92d7970F99684E6f787Eb51275',
    'hello world',
    'First NFT invoice minted', 
    'none',
    22,
    1)

print(data)