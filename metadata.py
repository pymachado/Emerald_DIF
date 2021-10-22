import json
from web3 import Web3;


metadataStandard = {
        'name': "HELLO WORLD",
        'description': "",
        'data custumer': {
            'tenant_name': "a",
            'tenant_street1': "b",
            'tenant_street2': "c",
            'tenant_city': "",
            'tenant_state': "",
            'tenant_zip': "",
            'tenant_country': "",
            'tenant_phone': "",
            'tenant_reserva_id': "",
            'client_name': "",
            'client_street': "",
            'client_street2': "",
            'client_city': "",
            'client_state': "",
            'client_zip': "",
            'client_country': "",
            'client_phone': "",
            'client_reserva_id': "",
            'date_invoice': "",
            'date_due': "",
            'interest_rate': "",
            'interest_rate_overdue': "",
            'source_document': "",
            'invoice_request_reserva_id': ""
        },

        'value of NFT': 0,
        'balance advance': 0,
        'address seller': ""       
    }
    

dataToStored = json.JSONEncoder().encode(metadataStandard['data custumer'])


#print(metadataStandard['data custumer']['tenant_name'])

#dataDecode = json.JSONDecoder().decode(dataToStored)
#print(dataDecode['name'])

w3 = Web3(Web3.HTTPProvider('http://127.0.0.1:9545/'))

contract_relative_path = 'build/contracts/NFT_FACTORY.json'
addressContract = '0xBDA48C708F067b08fa43A05Def5c9CE0560FF5Fe'

with open(contract_relative_path) as file:
    contract_json = json.load(file)
    contract_abi = contract_json['abi']


nftContract = w3.eth.contract(address = addressContract, abi = contract_abi)


#total = nftContract.functions.totalSupply().call()
#gasLimit = nftContract.functions.createInvoice('hello world','great!', dataToStored, metadataStandard['value of NFT'], metadataStandard['price of sell']).estimateGas() 

#tx_hash = nftContract.functions.createInvoice('hello world','great!', dataToStored, metadataStandard['value of NFT'], metadataStandard['price of sell']).transact({'from': w3.eth.accounts[0], 'gas':gasLimit})

#tx_receipt = w3.eth.wait_for_transaction_receipt(tx_hash)

#print(tx_receipt)

dataOfToken = nftContract.functions.getData(1).call();
dataCustumerFrom = json.JSONDecoder().decode(dataOfToken[2])
print(len(dataCustumerFrom))
