import json
from logging import error, log
from web3 import Web3
from web3._utils.events import DataArgumentFilter
import web3.logs

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
        for i in range(0, length):
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
    def set_TransferOwnershipNode(self, adminAddress):
        gasLimit = self.nftContract.functions.transferOwnership().estimateGas()
        tx_hash = self.nftContract.functions.transferOwnership().transact({'from': adminAddress, 'gas': gasLimit})
        tx_receipt = self.w3.eth.wait_for_transaction_receipt(tx_hash)
        tx_event = self.nftContract.events.OwnershipTransferred().processReceipt(tx_receipt, errors=web3.logs.DISCARD)
        return tx_event[0]['args']
        
    def set_TransferOwnershipLocal(self, adminAddress, adminPrivateKey, newOwner):
        gasLimit = self.nftContract.functions.transferOwnership().estimateGas({'from': adminAddress})
        nonce = self.w3.eth.get_transaction_count(adminAddress)
        raw_tx = self.nftContract.functions.transferOwnership(newOwner).buildTransaction({
                                                                        'chainId': self.w3.eth.chain_id,
                                                                        'gas': gasLimit,
                                                                        'nonce': nonce}
                                                                        )
        signed_tx =  self.w3.eth.account.sign_transaction(raw_tx, private_key=adminPrivateKey)
        tx_hash = self.w3.eth.send_raw_transaction(signed_tx.rawTransaction)  
        currentBlock = self.w3.eth.get_block_number()
        tx_receipt = self.w3.eth.wait_for_transaction_receipt(tx_hash)
        minedBlock = tx_receipt['blockNumber']
        confirmations = abs(minedBlock - currentBlock)
        tx_event = self.nftContract.events.OwnershipTransferred().processReceipt(tx_receipt, errors=web3.logs.DISCARD)
        self.data['number_confirmations'] = confirmations
        self.data['link_polygonscan'] = super()._plotHash(self.w3.toHex(tx_hash), self.network)
        self.data['tx_argsEvent'] = tx_event[0]['args']
        return self.data
        

    # Function to mint a new NFT; its just called from the admin address
    def set_CreateInvoiceNode(self, adminAddres, name, description, dataCustumer, valueOfNFT, balanceAdvance, seller):
        gasLimit = self.nftContract.functions.createInvoice(name,
                                                            description,
                                                            dataCustumer,
                                                            valueOfNFT,
                                                            balanceAdvance,seller).estimateGas(adminAddres)
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



    def set_CreateInvoiceLocal(self, adminAddress, adminPrivateKey, seller, name, description, dataCustumer, valueOfNFT, balanceAdvance):
        gasLimit = self.nftContract.functions.createInvoice(seller,
                                                            name,
                                                            description,
                                                            dataCustumer,
                                                            valueOfNFT,
                                                            balanceAdvance,
                                                            ).estimateGas({'from': adminAddress})
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
        currentBlock = self.w3.eth.get_block_number()
        tx_receipt = self.w3.eth.wait_for_transaction_receipt(tx_hash)
        minedBlock = tx_receipt['blockNumber']
        confirmations = abs(minedBlock - currentBlock)
        tx_event = self.nftContract.events.Transfer().processReceipt(tx_receipt, errors=web3.logs.DISCARD)
        self.data['number_confirmations'] = confirmations
        self.data['link_polygonscan'] = super()._plotHash(self.w3.toHex(tx_hash), self.network)
        self.data['tx_argsEvent'] = tx_event[0]['args']
        return self.data
        

    # Function to approve POOL to manage a tokenId
    def set_ApproveNode(self, fromAddress, toAddress, tokenId):
        gasLimit = self.nftContract.functions.approve(toAddress, tokenId).estimateGas()
        tx_hash = self.nftContract.functions.approve(toAddress, tokenId).transact({'from': fromAddress, 'gas': gasLimit})
        tx_receipt = self.w3.eth.wait_for_transaction_receipt(tx_hash)
        tx_event = self.nftContract.events.Approval().processReceipt(tx_receipt, errors=web3.logs.DISCARD)
        return tx_event[0]['args']
        

    def set_ApproveLocal(self, addressUser, privateKeyUser, toAddress, tokenId):
        gasLimit = self.nftContract.functions.approve(toAddress, tokenId).estimateGas({'from': addressUser})
        nonce = self.w3.eth.get_transaction_count(addressUser)
        raw_tx = self.nftContract.functions.approve(toAddress, tokenId).buildTransaction({
                                                                                            'chainId': self.w3.eth.chain_id,
                                                                                            'gas': gasLimit,
                                                                                            'nonce': nonce
                                                                                        })
        signed_tx = self.w3.eth.account.sign_transaction(raw_tx, private_key=privateKeyUser)
        tx_hash = self.w3.eth.send_raw_transaction(signed_tx.rawTransaction)
        currentBlock = self.w3.eth.get_block_number()
        tx_receipt = self.w3.eth.wait_for_transaction_receipt(tx_hash)
        minedBlock = tx_receipt['blockNumber']
        confirmations = abs(minedBlock - currentBlock)
        tx_event = self.nftContract.events.Approval().processReceipt(tx_receipt, errors=web3.logs.DISCARD)
        self.data['number_confirmations'] = confirmations
        self.data['link_polygonscan'] = super()._plotHash(self.w3.toHex(tx_hash), self.network)
        self.data['tx_argsEvent'] = tx_event[0]['args']
        return self.data
            

#nftClass = NFT_FACTORY('build/contracts/NFT_FACTORY.json','0x0d652741d37d0FC70F17c923DD4de9eAdF02D6B2', 'develop', 'develop')
#print(nftClass.get_TotalSupply())
#print(nftClass.get_Data(0))
#print(nftClass.get_Admin())
#print(nftClass.get_OwnerOf(0))
#print(nftClass.get_TotalTokenOfOwnerByIndex('0x48ec1876618d8ff1a0ef0fc9ec71b4fa30e4e5f3'))
#print(nftClass.get_TotalNFTBurned())
#print(nftClass.w3.eth.chain_id)
#newOwnerAddress = nftClass.w3.toChecksumAddress('0x48ab3746039b7dea00d1c295eff88abb9ad7c02a')
#newOwnerPrivateKey = '8343137e44ac32d0a4647796b05ad28b07a4b2260d891da70015ce8a5205c59d'

#data = nftClass.set_CreateInvoiceLocal(
#    newOwnerAddress,
#    newOwnerPrivateKey,
#    nftClass.w3.toChecksumAddress('0x48ec1876618d8ff1a0ef0fc9ec71b4fa30e4e5f3'),
#    'hello world',
#    'First NFT invoice minted', 
#    'none',
#    22,
#    3)

#print(data)



#nftClassMumbai = NFT_FACTORY('build/contracts/NFT_FACTORY.json','0x5673a930Da6dB358E86B532d9d1B3941c5F64Aa3', 'mumbai', 'mumbai')
#account = nftClassMumbai.w3.eth.account.create()
#accountAddress = nftClassMumbai.w3.toChecksumAddress(account.address)
#accountPK= account.privateKey
#print(accountAddress)
#print(accountPK)

#print(nftClassMumbai.w3.fromWei(balance, 'ether'))
#newOwnerAddress= '0xbd91E706bF05497E5E6bfc30Af5e7365a7734056'
#newOwnerPrivateKey= b'`*\x00\xa0G"x\x06F\xdePOk\xdc\x94\x8e\xe3\xbd\x91D\x8a\x13|\x8c\x94\x04\xbdDNF\xdd\x0e'
#balance = nftClassMumbai.w3.eth.get_balance(newOwnerAddress)
#print(balance)
#print(account.address)
#print(nftClassMumbai.w3.toHex(account.privateKey))
#a = BLOCKCHAIN_SELECTOR()
#print(json.JSONEncoder().encode(nftClassMumbai.nft_abi))
#print(a._setProvider('develop'))
#print(nftClassMumbai.get_TotalSupply())
#print(nftClassMumbai.get_Data(0))
#print(nftClassMumbai.get_Admin())
#print(nftClassMumbai.get_OwnerOf(0))
#print(nftClassMumbai.get_TotalTokenOfOwnerByIndex('0x79d2B3b4D0115F92d7970F99684E6f787Eb51275'))
#print(nftClassMumbai.get_TotalNFTBurned())
#print(nftClassMumbai.w3.eth.chain_id)
#adminAddress = nftClassMumbai.w3.toChecksumAddress('0xD82709678672920A9DcDA17d1B9eE5213E0472e8')
#adminPrivateKey = nftClassMumbai.w3.toText('0xdc1b2c6a0baf2450ed438ee96747874b1145ce988e919e42d4b3e02626c19f40')
#data = nftClassMumbai.set_CreateInvoiceLocal(
#    newOwnerAddress,
#    newOwnerPrivateKey,
#    '0x79d2B3b4D0115F92d7970F99684E6f787Eb51275',
#    'hello world',
#    'First NFT invoice minted', 
#    'none',
#    22,
#    4)

#print(data)
#print(balance)
