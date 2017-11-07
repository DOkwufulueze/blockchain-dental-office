import ODLLUserReaderContract from '../../../build/contracts/ODLLUserReader.json'
import blockchainManager from '../BlockchainManager'
import {EXCHANGE_RATE_API} from '../../util/constants'

let odllUser = null

class ODLLUser {
  constructor () {
    odllUser = odllUser || this
    return odllUser
  }

  writeData (state = null, data = {}) {
    const blockchainData = Object.assign({}, data)
    const blockchainMethodName = blockchainData.methodName
    delete blockchainData.methodName
    return blockchainManager.querySmartContract({
      smartContractMethod: blockchainMethodName,
      smartContractMethodParams: (coinbase) => [...(Object.values(blockchainData)), {from: coinbase, gas: 4444444}],
      state,
      smartContractResolve: result => data,
      smartContractReject: error => error
    })
  }

  deleteService (state = null, data = {}) {
    return blockchainManager.querySmartContract({
      smartContractMethod: 'removeDentistFromService',
      smartContractMethodParams: (coinbase) => [...(Object.values(data.serviceObject)), {from: coinbase, gas: 4444444}],
      state,
      smartContractResolve: result => data,
      smartContractReject: error => error
    })
  }

  writeUser (state = null, data = {}) {
    return blockchainManager.querySmartContract({
      smartContractMethod: 'writeUser',
      smartContractMethodParams: (coinbase) => [...(Object.values(data.userObject)), {from: coinbase, gas: 4444444}],
      state,
      smartContractResolve: result => data,
      smartContractReject: error => error
    })
  }

  acceptScanApplication (state = null, data = {}) {
    const quoteInEther = fetch(EXCHANGE_RATE_API)
    .then(response => response.json())
    .then((JSONResponse) => {
      const USDExchange = JSONResponse[0].price_usd
      return (data.requestObject.quote / USDExchange)
    })
    .catch((e) => console.error(e))

    return blockchainManager.querySmartContract({
      smartContractMethod: 'acceptScanApplication',
      smartContractMethodParams: (coinbase) => [...(Object.values(data.requestObject)), {from: coinbase, gas: 4444444, value: state.web3.instance().toWei(quoteInEther, 'ether')}],
      state,
      smartContractResolve: result => data,
      smartContractReject: error => error
    })
  }

  getUserDataFromTheBlockchain (state = null) {
    return new Promise((resolve, reject) => {
      const userObject = {}
      odllUser.getUserIdentityData(state)
      .then((result) => {
        Object.assign(userObject, result)
        odllUser.getUserContactData(state)
        .then((result) => {
          Object.assign(userObject, result)
          odllUser.getUserPersonalData(state)
          .then((result) => {
            if (Number(userObject.type) === 1) {
              odllUser.getUserDentistsIds(state)
              .then((result) => {
                Object.assign(userObject, result)
                resolve(userObject)
              })
            } else {
              Object.assign(userObject, result)
              resolve(userObject)
            }
          })
          .catch(error => reject(error))
        })
        .catch(error => reject(error))
      })
      .catch(error => reject(error))
    })
  }

  getUserIdentityData (state = null, userId = null) {
    return blockchainManager.querySmartContract({
      contractToUse: ODLLUserReaderContract,
      smartContractMethod: 'getUserIdentityData',
      smartContractMethodParams: (coinbase) => [userId || coinbase, {from: coinbase}],
      state,
      smartContractResolve: result => odllUser.getUserObject(state, result, ['type', 'name', 'email', 'gravatar', 'status']),
      smartContractReject: (error) => ({
        error,
        isValid: true,
        warningMessage: "We've encountered a problem fetching your identity information from the blockchain. Please do try again in a few minutes."
      })
    })
  }

  getUserContactData (state = null, userId = null) {
    return blockchainManager.querySmartContract({
      contractToUse: ODLLUserReaderContract,
      smartContractMethod: 'getUserContactData',
      smartContractMethodParams: (coinbase) => [userId || coinbase, {from: coinbase}],
      state,
      smartContractResolve: result => odllUser.getUserObject(state, result, ['street', 'city', 'phoneNumber', 'state', 'zipCode', 'country']),
      smartContractReject: (error) => ({
        error,
        isValid: true,
        warningMessage: "We've encountered a problem fetching your contact information from the blockchain. Please do try again in a few minutes."
      })
    })
  }

  getUserPersonalData (state = null, userId = null) {
    return blockchainManager.querySmartContract({
      contractToUse: ODLLUserReaderContract,
      smartContractMethod: 'getUserPersonalData',
      smartContractMethodParams: (coinbase) => [userId || coinbase, {from: coinbase}],
      state,
      smartContractResolve: result => odllUser.getUserObject(state, result, ['gender', 'socialSecurityNumber', 'birthday']),
      smartContractReject: (error) => ({
        error,
        isValid: true,
        warningMessage: "We've encountered a problem fetching your personal information from the blockchain. Please do try again in a few minutes."
      })
    })
  }

  getUserDentistsIds (state = null, userId = null) {
    return blockchainManager.querySmartContract({
      contractToUse: ODLLUserReaderContract,
      smartContractMethod: 'getUserDentistsIds',
      smartContractMethodParams: (coinbase) => [userId || coinbase, {from: coinbase}],
      state,
      smartContractResolve: result => odllUser.getUserObject(state, result, ['dentistsIds']),
      smartContractReject: (error) => ({
        error,
        isValid: true,
        warningMessage: "We've encountered a problem fetching your dentists from the blockchain. Please do try again in a few minutes."
      })
    })
  }

  getDentistFeeData (state = null, dataObject = {}) {
    const userId = dataObject.dentistId
    return blockchainManager.querySmartContract({
      contractToUse: ODLLUserReaderContract,
      smartContractMethod: 'getDentistFeeData',
      smartContractMethodParams: (coinbase) => [dataObject.serviceTypeId, dataObject.serviceId, userId || coinbase, {from: coinbase}],
      state,
      smartContractResolve: result => ({fee: result}),
      smartContractReject: (error) => ({
        error,
        isValid: true,
        warningMessage: "We've encountered a problem getting dentist fee from the blockchain. Please do try again in a few minutes."
      })
    })
  }

  getDentistRatingData (state = null, userId = null) {
    return blockchainManager.querySmartContract({
      contractToUse: ODLLUserReaderContract,
      smartContractMethod: 'getDentistRatingData',
      smartContractMethodParams: (coinbase) => [userId || coinbase, {from: coinbase}],
      state,
      smartContractResolve: result => ({rating: result}),
      smartContractReject: (error) => ({
        error,
        isValid: true,
        warningMessage: "We've encountered a problem getting dentist ratings from the blockchain. Please do try again in a few minutes."
      })
    })
  }

  getUserObject (state, results, keys) {
    const arrayResult = state && state.web3 && state.web3.instance && results && results.length > 0 ? results : []
    const userObject = keys.reduce((hash, key, index) => {
      hash[key] = arrayResult[index] ? arrayResult[index].toString() : ''
      return hash
    }, {})

    return userObject
  }

  defaultUserObject () {
    return {
      type: '0',
      lastName: '',
      firstName: '',
      middleName: '',
      name: '',
      email: '',
      gravatar: '',
      street: '',
      city: '',
      state: 0,
      zipCode: '',
      country: '',
      phoneNumber: '',
      socialSecurityNumber: '',
      areaNumber: '',
      groupNumber: '',
      sequenceNumber: '',
      day: '',
      month: '',
      year: '',
      birthday: '',
      gender: '',
      dentistsIds: [],
      hasWeb3InjectedBrowser: false,
      hasCoinbase: false,
      isConnectedToODLLNetwork: false,
      coinbase: '',
      isValid: false,
      isPatient: false,
      canBeNewPatient: false,
      patientable: false,
      isDentist: false,
      isODLLAdmin: false,
      isODLLManager: false,
      warningMessage: ''
    }
  }
}

odllUser = new ODLLUser()
export default odllUser
