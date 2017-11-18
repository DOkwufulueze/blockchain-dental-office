pragma solidity 0.4.18;

import "./utilities.sol";
import "./servicesLibrary.sol";
import "./searchLibrary.sol";

library userManager {
  using strings for *;

  //    status:
  //    { 0 => not registered, 1 => active, 2 => blocked }

  //    userType:
  //    { 1 => patient, 2 => dentist, 3 => manager, 4 => admin }

  function getConfig (address dbAddress, string key) internal view returns(uint) {
    return DB(dbAddress).getUIntValue(keccak256(key));
  }

  function getUsersCount (address dbAddress) internal view returns(uint) {
    return DB(dbAddress).getUIntValue(keccak256("users/count"));
  }

  function getAdminsCount (address dbAddress) internal view returns(uint) {
    return DB(dbAddress).getUIntValue(keccak256("admins/count"));
  }

  function getDentistsCount (address dbAddress) internal view returns(uint) {
    return DB(dbAddress).getUIntValue(keccak256("dentists/count"));
  }

  function getManagersCount (address dbAddress) internal view returns(uint) {
    return DB(dbAddress).getUIntValue(keccak256("managers/count"));
  }

  function getPatientsCount (address dbAddress) internal view returns(uint) {
    return DB(dbAddress).getUIntValue(keccak256("patients/count"));
  }

  function isActiveUser (address dbAddress, address userId) internal view returns(bool) {
    return hasStatus(dbAddress, userId, 1);
  }

  function isActiveAdmin (address dbAddress, address userId) internal view returns(bool) {
    return isUserType(dbAddress, userId, 4) && hasStatus(dbAddress, userId, 1);
  }

  function isActiveManager (address dbAddress, address userId) internal view returns(bool) {
    return isUserType(dbAddress, userId, 3) && hasStatus(dbAddress, userId, 1);
  }

  function isActiveDentist (address dbAddress, address userId) internal view returns(bool) {
    return isUserType(dbAddress, userId, 2) && hasStatus(dbAddress, userId, 1);
  }

  function isActivePatient (address dbAddress, address userId) internal view returns(bool) {
    return isUserType(dbAddress, userId, 1) && hasStatus(dbAddress, userId, 1);
  }

  function userExists (address dbAddress, address userId) internal view returns(bool) {
    return getStatus(dbAddress, userId) > 0;
  }

  function getAllUsers (address dbAddress) internal view returns(address[]) {
    return utilities.getAddressArray(dbAddress, "users/ids", "users/count");
  }

  function getAllAdmins (address dbAddress) internal view returns(address[]) {
    return utilities.getAddressArray(dbAddress, "admins/ids", "admins/count");
  }

  function getAllDentists (address dbAddress) internal view returns(address[]) {
    return utilities.getAddressArray(dbAddress, "dentists/ids", "dentists/count");
  }

  function getAllManagers (address dbAddress) internal view returns(address[]) {
    return utilities.getAddressArray(dbAddress, "managers/ids", "managers/count");
  }

  function getAllPatients (address dbAddress) internal view returns(address[]) {
    return utilities.getAddressArray(dbAddress, "patients/ids", "patients/count");
  }

  function setUserIdentity (
    address dbAddress,
    address userId,
    uint8 userType,
    string name,
    string email,
    bytes32 gravatar
  )
    internal
  {
    var nameLen = name.toSlice().len();
    var emailLen = email.toSlice().len();
    require(nameLen <= getConfig(dbAddress, "config/max-user-name-length") && nameLen >= getConfig(dbAddress, "config/min-user-name-length"));
    require(emailLen <= getConfig(dbAddress, "config/max-user-email-length") && emailLen >= getConfig(dbAddress, "config/min-user-email-length"));

    initUser(dbAddress, userId, userType);
    DB(dbAddress).setStringValue(keccak256("user/name", userId), name);
    DB(dbAddress).setStringValue(keccak256("user/email", userId), email);
    DB(dbAddress).setBytes32Value(keccak256("user/gravatar", userId), gravatar);
  }

  function initUser (
    address dbAddress,
    address userId,
    uint8 userType
  )
    internal
  {
    if (!userExists(dbAddress, userId)) {
      DB(dbAddress).setUIntValue(keccak256("user/created-on", userId), now);
      DB(dbAddress).setUInt8Value(keccak256("user/status", userId), 1);
      utilities.addArrayItem(dbAddress, "users/ids", "users/count", userId);

      string memory userTypeKey;
      string memory userTypeIdsKey;
      string memory userTypeCountKey;
      (userTypeKey, userTypeIdsKey, userTypeCountKey) = getUserTypeKey(userType);
      DB(dbAddress).setBooleanValue(keccak256(userTypeKey, userId), true);
      utilities.addArrayItem(dbAddress, userTypeIdsKey, userTypeCountKey, userId);
    }

    DB(dbAddress).setUInt8Value(keccak256("user/type", userId), userType);
  }

  function setUserLocation (
    address dbAddress,
    address userId,
    bytes32 street,
    bytes32 city,
    uint state,
    bytes32 zipCode,
    uint country
  )
    internal
  {
    require(userExists(dbAddress, userId));
    require(isActiveUser(dbAddress, userId));

    DB(dbAddress).setBytes32Value(keccak256("user/street", userId), street);
    DB(dbAddress).setBytes32Value(keccak256("user/city", userId), city);
    DB(dbAddress).setUIntValue(keccak256("user/state", userId), state);
    DB(dbAddress).setBytes32Value(keccak256("user/zip-code", userId), zipCode);
    DB(dbAddress).setUIntValue(keccak256("user/country", userId), country);
  }

  function setUserOptionalValues (
    address dbAddress,
    address userId,
    bytes32 phoneNumber,
    bytes32 socialSecurityNumber,
    bytes32 birthday,
    uint8 gender
  )
    internal
  {
    require(userExists(dbAddress, userId));
    require(isActiveUser(dbAddress, userId));
    DB(dbAddress).setBytes32Value(keccak256("user/phone-number", userId), phoneNumber);
    DB(dbAddress).setBytes32Value(keccak256("user/social-security-number", userId), socialSecurityNumber);
    DB(dbAddress).setBytes32Value(keccak256("user/birthday", userId), birthday);
    DB(dbAddress).setUInt8Value(keccak256("user/gender", userId), gender);
  }

  function getUserTypeKey (uint8 userType) internal pure returns (string memory userTypeKey, string memory userTypeIdsKey, string memory userTypeCountKey) {
    if (userType == 1) {
      userTypeKey = "user/is-patient?";
      userTypeIdsKey = "patients/ids";
      userTypeCountKey = "patients/count";
    } else if (userType == 2) {
      userTypeKey = "user/is-dentist?";
      userTypeIdsKey = "dentists/ids";
      userTypeCountKey = "dentists/count";
    } else if (userType == 3) {
      userTypeKey = "user/is-manager?";
      userTypeIdsKey = "managers/ids";
      userTypeCountKey = "managers/count";
    } else if (userType == 4) {
      userTypeKey = "user/is-admin?";
      userTypeIdsKey = "admins/ids";
      userTypeCountKey = "admins/count";
    }
  }

  function setDentist (
    address dbAddress,
    address userId,
    bool isODLLDentist,
    bool isAvailable,
    string companyName
  )
    internal
  {
    var companyNameLen = companyName.toSlice().len();
    require(userExists(dbAddress, userId));
    require(isActiveUser(dbAddress, userId));
    require(companyNameLen <= getConfig(dbAddress, "config/max-company-name-length") && companyNameLen >= getConfig(dbAddress, "config/min-company-name-length"));
    DB(dbAddress).setBooleanValue(keccak256("user/is-odll-dentist?", userId), isODLLDentist);
    DB(dbAddress).setBooleanValue(keccak256("user/is-available?", userId), isAvailable);
    DB(dbAddress).setStringValue(keccak256("dentist/company-name", userId), companyName);
  }

  function addODLLDentist (
    address dbAddress,
    address userId
  )
    internal
  {
    require(userExists(dbAddress, userId));
    require(isActiveUser(dbAddress, userId));
    DB(dbAddress).setBooleanValue(keccak256("user/is-odll-dentist?", userId), true);
  }

  function hasStatus (address dbAddress, address userId, uint8 status) internal view returns(bool) {
    return status == getStatus(dbAddress, userId);
  }

  function getStatus (address dbAddress, address userId) internal view returns(uint8) {
    return DB(dbAddress).getUInt8Value(keccak256("user/status", userId));
  }

  function isUserType (address dbAddress, address userId, uint8 userType) internal view returns(bool) {
    return userType == getUserType(dbAddress, userId);
  }

  function getUserType (address dbAddress, address userId) internal view returns(uint8) {
    return DB(dbAddress).getUInt8Value(keccak256("user/type", userId));
  }

  function setStatus (address dbAddress, address userId, uint8 status) internal {
    DB(dbAddress).setUInt8Value(keccak256("user/status", userId), status);
  }

  function setUserNotifications (address dbAddress, address userId, bool[] boolNotificationSettings, uint8[] uint8NotificationSettings) internal {
    DB(dbAddress).setBooleanValue(keccak256("user.notification/disabled-all?", userId), boolNotificationSettings[0]);
    DB(dbAddress).setBooleanValue(keccak256("user.notification/disabled-newsletter?", userId), boolNotificationSettings[1]);
    DB(dbAddress).setBooleanValue(keccak256("user.notification/disabled-on-scan-offer?", userId), boolNotificationSettings[2]);
    DB(dbAddress).setBooleanValue(keccak256("user.notification/disabled-on-treatment-offer?", userId), boolNotificationSettings[3]);
    DB(dbAddress).setBooleanValue(keccak256("user.notification/disabled-on-scan-request?", userId), boolNotificationSettings[4]);
    DB(dbAddress).setBooleanValue(keccak256("user.notification/disabled-on-treatment-request?", userId), boolNotificationSettings[5]);
    DB(dbAddress).setBooleanValue(keccak256("user.notification/disabled-on-scan-application-accepted?", userId), boolNotificationSettings[6]);
    DB(dbAddress).setBooleanValue(keccak256("user.notification/disabled-on-treatment-application-accepted?", userId), boolNotificationSettings[7]);
    DB(dbAddress).setBooleanValue(keccak256("user.notification/disabled-on-rated?", userId), boolNotificationSettings[8]);
    DB(dbAddress).setUInt8Value(keccak256("user.notification/scan-result-advert", userId), uint8NotificationSettings[0]);
  }

  function addReceivedMessage  (address dbAddress, address userId, uint messageId) internal {
    utilities.addIdArrayItem(dbAddress, userId, "user/received-messages", "user/received-messages-count", messageId);
  }

  function addSentMessage  (address dbAddress, address userId, uint messageId) internal {
    utilities.addIdArrayItem(dbAddress, userId, "user/sent-messages", "user/sent-messages-count", messageId);
  }

  function writeDentistRating  (address dbAddress, address userId, uint8 rating) internal {
    addToAverageRating(dbAddress, userId, "dentist/average-rating-count", "dentist/average-rating", rating);
  }

  function addToAverageRating  (address dbAddress, address userId, string countKey, string key, uint8 rating) internal {
    var ratingsCount = DB(dbAddress).getUIntValue(keccak256(countKey, userId));
    var currentAverageRating = DB(dbAddress).getUInt8Value(keccak256(key, userId));
    var newRatingsCount = SafeMath.add(ratingsCount, 1);
    uint newAverageRating;
    if (ratingsCount == 0) {
      newAverageRating = rating;
    } else {
      var newTotalRating = SafeMath.add(SafeMath.mul(currentAverageRating, ratingsCount), rating);
      newAverageRating = newTotalRating / newRatingsCount;
    }

    DB(dbAddress).setUIntValue(keccak256(countKey, userId), newRatingsCount);
    DB(dbAddress).setUInt8Value(keccak256(key, userId), uint8(newAverageRating));
  }

  function getDentistAverageRating (address dbAddress, address userId) internal view returns (uint8) {
    return DB(dbAddress).getUInt8Value(keccak256("dentist/average-rating", userId));
  }

  function addToPatientTotalPaid (address dbAddress, address userId, uint amount) internal {
    DB(dbAddress).addUIntValue(keccak256("patient/total-paid", userId), amount);
    DB(dbAddress).addUIntValue(keccak256("patients/total-paid"), amount);
  }

  function addToPatientScanTotalPaid (address dbAddress, address userId, uint amount) internal {
    DB(dbAddress).addUIntValue(keccak256("patient/scan-total-paid", userId), amount);
    DB(dbAddress).addUIntValue(keccak256("patients/scan-total-paid"), amount);
  }

  function addToPatientTreatmentTotalPaid (address dbAddress, address userId, uint amount) internal {
    DB(dbAddress).addUIntValue(keccak256("patient/treatment-total-paid", userId), amount);
    DB(dbAddress).addUIntValue(keccak256("patients/treatment-total-paid"), amount);
  }

  function addToDentistTotalEarned (address dbAddress, address userId, uint amount) internal {
    DB(dbAddress).addUIntValue(keccak256("dentist/total-earned", userId), amount);
    DB(dbAddress).addUIntValue(keccak256("dentists/total-earned"), amount);
  }

  function addToDentistScanTotalEarned (address dbAddress, address userId, uint amount) internal {
    DB(dbAddress).addUIntValue(keccak256("dentist/scan-total-earned", userId), amount);
    DB(dbAddress).addUIntValue(keccak256("dentists/scan-total-earned"), amount);
  }

  function addToDentistTreatmentTotalEarned (address dbAddress, address userId, uint amount) internal {
    DB(dbAddress).addUIntValue(keccak256("dentist/treatment-total-earned", userId), amount);
    DB(dbAddress).addUIntValue(keccak256("dentists/treatment-total-earned"), amount);
  }

  function addToODLLTotalEarned (address dbAddress, address userId, uint amount) internal {
    DB(dbAddress).addUIntValue(keccak256("odll/total-earned", userId), amount);
    DB(dbAddress).addUIntValue(keccak256("odll/total-earned"), amount);
  }

  function addToODLLScanTotalEarned (address dbAddress, address userId, uint amount) internal {
    DB(dbAddress).addUIntValue(keccak256("odll/scan-total-earned", userId), amount);
    DB(dbAddress).addUIntValue(keccak256("odll/scan-total-earned"), amount);
  }

  function addToODLLTreatmentTotalEarned (address dbAddress, address userId, uint amount) internal {
    DB(dbAddress).addUIntValue(keccak256("odll/treatment-total-earned", userId), amount);
    DB(dbAddress).addUIntValue(keccak256("odll/treatment-total-earned"), amount);
  }

  function isFromCountry (address dbAddress, address userId, uint countryId) internal view returns(bool) {
    if (countryId == 0) {
      return true;
    }

    return countryId == DB(dbAddress).getUIntValue(keccak256("user/country", userId));
  }

  function isFromState (address dbAddress, address userId, uint stateId) internal view returns(bool) {
    if (stateId == 0) {
      return true;
    }

    return stateId == DB(dbAddress).getUIntValue(keccak256("user/state", userId));
  }

  function hasMinRating (address dbAddress, address userId, uint8 minAverageRating) internal view returns(bool) {
    if (minAverageRating == 0) {
      return true;
    }

    return minAverageRating <= DB(dbAddress).getUInt8Value(keccak256("dentist/average-rating", userId));
  }

  function hasDentistMinRatingsCount (address dbAddress, address userId, uint minRatingsCount) internal view returns(bool) {
    if (minRatingsCount == 0) {
      return true;
    }

    return minRatingsCount <= DB(dbAddress).getUIntValue(keccak256("dentist/ratings-count", userId));
  }

  function hasScanResultAdverts (address dbAddress, address userId, uint scanResultAdverts) internal view returns (bool) {
      if (scanResultAdverts == 0) {
        return true;
      }
      if (DB(dbAddress).getBooleanValue(keccak256("user.notification/disabled-all?", userId))) {
        return false;
      }

      uint userScanResultAdverts = DB(dbAddress).getUInt8Value(keccak256("user.notification/job-recommendations", userId));
      if (userScanResultAdverts == 0 && scanResultAdverts == 1) { // default value
        return true;
      }

      return userScanResultAdverts == scanResultAdverts;
  }

  function isDentistAvailable (address dbAddress, address userId) internal view returns (bool) {
    return DB(dbAddress).getBooleanValue(keccak256("dentist/is-available?", userId));
  }

  function writeUserDentist (address dbAddress, address userId, address dentistId)
    internal
  {
    utilities.addRemovableIdItem(dbAddress, userId, 'patient/dentist', 'patient/dentists-count', 'patient/dentist-key', dentistId);
    utilities.addRemovableIdItem(dbAddress, dentistId, 'dentist/patient', 'dentist/patient-key', 'dentist/patient-key', userId);
  }

  function fetchUserDentists (
    address dbAddress,
    address userId,
    uint offset, // starting from offset: 0-based
    uint limit, // not more than limit
    uint seed // seed value to give the illusion of randomisation
  )
    internal
    view
    returns (
      uint totalNumberFound,
      address[] dentistsIds
    )
  {
    dentistsIds = utilities.getRemovableIdArrayAddressItems(dbAddress, userId, 'patient/dentist', 'patient/dentists-count', 'patient/dentist-key');
    (totalNumberFound, dentistsIds) = utilities.getSlicedArray(dentistsIds, offset, limit, seed);
  }

  function blockUserDentist (
    address dbAddress,
    address userId,
    address dentistId
  )
    internal
  {
    DB(dbAddress).setUInt8Value(keccak256("patient/dentist", userId, dentistId), 2);
    DB(dbAddress).setUInt8Value(keccak256("dentist/patient", dentistId, userId), 2);
  }

  function unblockUserDentist (
    address dbAddress,
    address userId,
    address dentistId
  )
    internal
  {
    DB(dbAddress).setUInt8Value(keccak256("patient/dentist", userId, dentistId), 1);
    DB(dbAddress).setUInt8Value(keccak256("dentist/patient", dentistId, userId), 1);
  }

  function fetchUserPatients (
    address dbAddress,
    address userId,
    uint offset, // starting from offset: 0-based
    uint limit, // not more than limit
    uint seed // seed value to give the illusion of randomisation
  )
    internal
    view
    returns (
      uint totalNumberFound,
      address[] patientsIds
    )
  {
    patientsIds = utilities.getRemovableIdArrayAddressItems(dbAddress, userId, 'dentist/patient', 'dentist/patients-count', 'dentist/patient-key');
    (totalNumberFound, patientsIds) = utilities.getSlicedArray(patientsIds, offset, limit, seed);
  }

  function findDentists (
    address dbAddress,
    uint stateId,
    uint serviceTypeId,
    uint serviceId,
    uint[] budget, // within budget range
    uint offset, // starting from offset: 0-based
    uint limit, // not more than limit
    uint seed // seed value to give the illusion of randomisation
    )
      internal
      view
      returns (
        uint totalNumberFound,
        address[] foundDentistsIds
      )
  {
    var budgetBasedDentistsIds = searchLibrary.getServiceDentistsByBudget(dbAddress, serviceTypeId, serviceId, budget);
    var stateBasedDentistsIds = searchLibrary.getServiceDentistsByState(dbAddress, serviceTypeId, serviceId, stateId);
    foundDentistsIds = utilities.intersectBudgetAndStateBasedDentists(dbAddress, budgetBasedDentistsIds, stateBasedDentistsIds);

    (totalNumberFound, foundDentistsIds) = utilities.getSlicedArray(foundDentistsIds, offset, limit, seed);
  }

  function addOfficialToODLL (address dbAddress, address officialId, uint8 userType)
    internal
  {
    uint8 userTypeCheck = DB(dbAddress).getUInt8Value(keccak256('user/type', officialId));
    require(officialId != 0x0 && userType != 0 && userTypeCheck == 0);
    initUser(dbAddress, officialId, userType);
  }

  function blockUser (address dbAddress, address userId)
    internal
  {
    DB(dbAddress).setUInt8Value(keccak256("user/status", userId), 2);
  }

  function unblockUser (address dbAddress, address userId)
    internal
  {
    DB(dbAddress).setUInt8Value(keccak256("user/status", userId), 1);
  }

  function fetchDentists (
    address dbAddress,
    uint offset, // starting from offset: 0-based
    uint limit, // not more than limit
    uint seed // seed value to give the illusion of randomisation
  )
    internal
    view
    returns (
      uint totalNumberFound,
      address[] foundDentistsIds
    )
  {
    foundDentistsIds = searchLibrary.getDentists(dbAddress);
    (totalNumberFound, foundDentistsIds) = utilities.getSlicedArray(foundDentistsIds, offset, limit, seed);
  }

  function fetchManagers (
    address dbAddress,
    uint offset, // starting from offset: 0-based
    uint limit, // not more than limit
    uint seed // seed value to give the illusion of randomisation
  )
    internal
    view
    returns (
      uint totalNumberFound,
      address[] foundManagersIds
    )
  {
    foundManagersIds = searchLibrary.getManagers(dbAddress);
    (totalNumberFound, foundManagersIds) = utilities.getSlicedArray(foundManagersIds, offset, limit, seed);
  }

  function fetchServicesWithFees (
    address dbAddress,
    address userId,
    uint serviceTypeId,
    uint offset, // starting from offset: 0-based
    uint limit, // not more than limit
    uint seed // seed value to give the illusion of randomisation
  )
    internal
    view
    returns (
      uint totalNumberFound,
      uint[] foundServiceIds
    )
  {
    (totalNumberFound, foundServiceIds) = fetchServices(dbAddress, userId, serviceTypeId, offset, limit, seed);
  }

  function fetchServices (
    address dbAddress,
    address userId,
    uint serviceTypeId,
    uint offset, // starting from offset: 0-based
    uint limit, // not more than limit
    uint seed // seed value to give the illusion of randomisation
  )
    internal
    view
    returns (
      uint totalNumberFound,
      uint[] foundServiceIds
    )
  {
    foundServiceIds = searchLibrary.getServices(dbAddress, serviceTypeId, userId);
    (totalNumberFound, foundServiceIds) = utilities.getSlicedArray(foundServiceIds, offset, limit, seed);
  }

  function writeServices (
    address dbAddress,
    uint serviceTypeId,
    uint[] serviceIds,
    address userId
  )
    internal
  {
    servicesLibrary.addDentist(dbAddress, serviceTypeId, serviceIds, userId);
  }

  function writeServiceWithFee (
    address dbAddress,
    uint serviceTypeId,
    uint serviceId,
    uint fee,
    address userId
  )
    internal
  {
    servicesLibrary.addDentistToService(dbAddress, serviceTypeId, serviceId, userId);
    servicesLibrary.setFee(dbAddress, serviceTypeId, serviceId, fee, userId);
  }

  function removeDentistFromService (
    address dbAddress,
    uint serviceTypeId,
    uint serviceId,
    address userId
  )
    internal
  {
    servicesLibrary.removeDentistFromService(dbAddress, serviceTypeId, serviceId, userId);
  }

  function removeServices (
    address dbAddress,
    uint serviceTypeId,
    uint[] serviceIds,
    address userId
  )
    internal
  {
    servicesLibrary.removeDentist(dbAddress, serviceTypeId, serviceIds, userId);
  }

  function writeScanRequest (
    address dbAddress,
    address dentistId,
    address patientId,
    uint scanAppointmentId,
    bytes32 appointmentDate,
    bytes32 scanTime,
    string scanInsurance,
    string comment
  )
    internal
  {
    servicesLibrary.writeScanRequest(dbAddress, dentistId, patientId, scanAppointmentId, appointmentDate, scanTime, scanInsurance, comment);
  }

  function cancelScanRequest (
    address dbAddress,
    address patientId,
    uint scanRequestId
  )
    internal
  {
    servicesLibrary.cancelScanRequest(dbAddress, patientId, scanRequestId);
  }

  function expireScanRequest (
    address dbAddress,
    uint scanRequestId
  )
    internal
  {
    servicesLibrary.expireScanRequest(dbAddress, scanRequestId);
  }

  function acceptScanRequest (
    address dbAddress,
    address dentistId,
    address patientId,
    uint scanRequestId,
    uint quote,
    string comment
  )
    internal
  {
    servicesLibrary.acceptScanRequest(dbAddress, dentistId, patientId, scanRequestId, quote, comment);
  }

  function rejectScanRequest (
    address dbAddress,
    address dentistId,
    address patientId,
    uint scanRequestId
  )
    internal
  {
    servicesLibrary.rejectScanRequest(dbAddress, dentistId, patientId, scanRequestId);
  }

  function applyToScan (
    address dbAddress,
    address dentistId,
    address patientId,
    uint scanRequestId,
    uint quote,
    string comment
  )
    internal
  {
    servicesLibrary.applyToScan(dbAddress, dentistId, patientId, scanRequestId, quote, comment);
  }

  function cancelScanApplication (
    address dbAddress,
    address dentistId,
    address patientId,
    uint scanApplicationId
  )
    internal
  {
    servicesLibrary.cancelScanApplication(dbAddress, dentistId, patientId, scanApplicationId);
  }

  function acceptScanApplication (
    address dbAddress,
    address dentistId,
    address patientId,
    uint scanApplicationId,
    uint amount,
    uint quote
  )
    internal
  {
    address ODLLId = DB(dbAddress).getAddressValue(keccak256("odll/payment-address"));
    uint ODLLScanPaymentPercentage = DB(dbAddress).getUIntValue(keccak256("odll/scan-payment-percentage"));
    uint change = SafeMath.sub(amount, quote);
    uint ODLLFee = SafeMath.mul(SafeMath.div(ODLLScanPaymentPercentage, 100), quote);
    uint dentistFee = SafeMath.sub(quote, ODLLFee);

    uint tempODLLFee = ODLLFee;
    ODLLFee = 0;

    uint tempDentistFee = dentistFee;
    dentistFee = 0;

    addToPatientScanTotalPaid(dbAddress, patientId, quote);
    addToPatientTotalPaid(dbAddress, patientId, quote);

    addToDentistScanTotalEarned(dbAddress, dentistId, tempDentistFee);
    addToDentistTotalEarned(dbAddress, dentistId, tempDentistFee);

    addToODLLScanTotalEarned(dbAddress, ODLLId, tempODLLFee);
    addToODLLTotalEarned(dbAddress, ODLLId, tempODLLFee);

    servicesLibrary.acceptScanApplication(dbAddress, dentistId, patientId, scanApplicationId, quote);
    writeUserDentist(dbAddress, patientId, dentistId);

    ODLLId.transfer(tempODLLFee);
    dentistId.transfer(tempDentistFee);
    if (change > 0) {
      uint tempChange = change;
      change = 0;
      patientId.transfer(tempChange);
    }
  }

  function writeTreatmentRequest (
    address dbAddress,
    address patientId,
    bool hasCaseId,
    uint caseId,
    string insurance,
    string scanResults,
    string comment
  )
    internal
  {
    servicesLibrary.writeTreatmentRequest(dbAddress, patientId, hasCaseId, caseId, insurance, scanResults, comment);
  }

  function cancelTreatmentRequest (
    address dbAddress,
    address patientId,
    uint treatmentRequestId
  )
    internal
  {
    servicesLibrary.cancelTreatmentRequest(dbAddress, patientId, treatmentRequestId);
  }

  function applyToTreat (
    address dbAddress,
    address dentistId,
    address patientId,
    uint treatmentRequestId,
    uint quote,
    string comment
  )
    internal
  {
    servicesLibrary.applyToTreat(dbAddress, dentistId, patientId, treatmentRequestId, quote, comment);
  }

  function cancelTreatmentApplication (
    address dbAddress,
    address dentistId,
    address patientId,
    uint treatmentApplicationId
  )
    internal
  {
    servicesLibrary.cancelTreatmentApplication(dbAddress, dentistId, patientId, treatmentApplicationId);
  }

  // treatment status: 1 => pending, 2 => done, 3 => canceled
  function acceptTreatmentApplication (
    address dbAddress,
    address dentistId,
    address patientId,
    uint treatmentApplicationId,
    uint amount,
    uint quote
  )
    internal
  {
    address ODLLId = DB(dbAddress).getAddressValue(keccak256("odll/payment-address"));
    uint ODLLTreatmentPaymentPercentage = DB(dbAddress).getUIntValue(keccak256("odll/treatment-payment-percentage"));
    uint change = SafeMath.sub(amount, quote);
    uint ODLLFee = SafeMath.mul(SafeMath.div(ODLLTreatmentPaymentPercentage, 100), quote);
    uint dentistFee = SafeMath.sub(quote, ODLLFee);

    uint tempODLLFee = ODLLFee;
    ODLLFee = 0;

    uint tempDentistFee = dentistFee;
    dentistFee = 0;

    addToPatientTreatmentTotalPaid(dbAddress, patientId, quote);
    addToPatientTotalPaid(dbAddress, patientId, quote);

    addToDentistTreatmentTotalEarned(dbAddress, dentistId, tempDentistFee);
    addToDentistTotalEarned(dbAddress, dentistId, tempDentistFee);

    addToODLLTreatmentTotalEarned(dbAddress, ODLLId, tempODLLFee);
    addToODLLTotalEarned(dbAddress, ODLLId, tempODLLFee);

    servicesLibrary.acceptTreatmentApplication(dbAddress, dentistId, patientId, treatmentApplicationId, quote);

    ODLLId.transfer(tempODLLFee);
    dentistId.transfer(tempDentistFee);
    if (change > 0) {
      uint tempChange = change;
      change = 0;
      patientId.transfer(tempChange);
    }
  }

  function cancelTreatment (
    address dbAddress,
    address dentistId,
    address patientId,
    uint treatmentId
  )
    internal
  {
    servicesLibrary.cancelTreatment(dbAddress, dentistId, patientId, treatmentId);
  }

  function markTreatmentDone (
    address dbAddress,
    address dentistId,
    address patientId,
    uint treatmentId
  )
    internal
  {
    servicesLibrary.markTreatmentDone(dbAddress, dentistId, patientId, treatmentId);
  }

  function fetchScanRequestsForPatient (
    address dbAddress,
    address patientId,
    uint offset, // starting from offset: 0-based
    uint limit, // not more than limit
    uint seed // seed value to give the illusion of randomisation
  )
    internal
    view
    returns (
      uint totalNumberFound,
      uint[] scanRequestsIds
    )
  {
    scanRequestsIds = searchLibrary.getScanRequestsForPatient(dbAddress, patientId);
    (totalNumberFound, scanRequestsIds) = utilities.getSlicedArray(scanRequestsIds, offset, limit, seed);
  }

  function fetchAcceptedScanRequestsForPatient (
    address dbAddress,
    address patientId,
    uint offset, // starting from offset: 0-based
    uint limit, // not more than limit
    uint seed // seed value to give the illusion of randomisation
  )
    internal
    view
    returns (
      uint totalNumberFound,
      uint[] scanRequestsIds
    )
  {
    scanRequestsIds = searchLibrary.getAcceptedScanRequestsForPatient(dbAddress, patientId);
    (totalNumberFound, scanRequestsIds) = utilities.getSlicedArray(scanRequestsIds, offset, limit, seed);
  }

  function fetchScanApplicationsForPatient (
    address dbAddress,
    address patientId,
    uint offset, // starting from offset: 0-based
    uint limit, // not more than limit
    uint seed // seed value to give the illusion of randomisation
  )
    internal
    view
    returns (
      uint totalNumberFound,
      uint[] scanApplicationsIds
    )
  {
    scanApplicationsIds = searchLibrary.getScanApplicationsForPatient(dbAddress, patientId);
    (totalNumberFound, scanApplicationsIds) = utilities.getSlicedArray(scanApplicationsIds, offset, limit, seed);
  }

  function fetchAllScanRequests (
    address dbAddress,
    uint offset, // starting from offset: 0-based
    uint limit, // not more than limit
    uint seed // seed value to give the illusion of randomisation
  )
    internal
    view
    returns (
      uint totalNumberFound,
      uint[] scanRequestsIds
    )
  {
    scanRequestsIds = searchLibrary.getAllScanRequests(dbAddress);
    (totalNumberFound, scanRequestsIds) = utilities.getSlicedArray(scanRequestsIds, offset, limit, seed);
  }

  function fetchDirectScanRequestsForDentist (
    address dbAddress,
    address dentistId,
    uint offset, // starting from offset: 0-based
    uint limit, // not more than limit
    uint seed // seed value to give the illusion of randomisation
  )
    internal
    view
    returns(
      uint totalNumberFound,
      uint[] scanRequestsIds
    )
  {
    scanRequestsIds = searchLibrary.getDirectScanRequestsForDentist(dbAddress, dentistId);
    (totalNumberFound, scanRequestsIds) = utilities.getSlicedArray(scanRequestsIds, offset, limit, seed);
  }

  function fetchAcceptedScanRequestsForDentist (
    address dbAddress,
    address dentistId,
    uint offset, // starting from offset: 0-based
    uint limit, // not more than limit
    uint seed // seed value to give the illusion of randomisation
  )
    internal
    view
    returns (
      uint totalNumberFound,
      uint[] scanRequestsIds
    )
  {
    scanRequestsIds = searchLibrary.getAcceptedScanRequestsForDentist(dbAddress, dentistId);
    (totalNumberFound, scanRequestsIds) = utilities.getSlicedArray(scanRequestsIds, offset, limit, seed);
  }

  function fetchScanApplicationsForDentist (
    address dbAddress,
    address dentistId,
    uint offset, // starting from offset: 0-based
    uint limit, // not more than limit
    uint seed // seed value to give the illusion of randomisation
  )
    internal
    view
    returns (
      uint totalNumberFound,
      uint[] scanApplicationsIds
    )
  {
    scanApplicationsIds = searchLibrary.getScanApplicationsForDentist(dbAddress, dentistId);
    (totalNumberFound, scanApplicationsIds) = utilities.getSlicedArray(scanApplicationsIds, offset, limit, seed);
  }

  function fetchTreatmentRequestsForPatient (
    address dbAddress,
    address patientId,
    uint offset, // starting from offset: 0-based
    uint limit, // not more than limit
    uint seed // seed value to give the illusion of randomisation
  )
    internal
    view
    returns (
      uint totalNumberFound,
      uint[] treatmentRequestsIds
    )
  {
    treatmentRequestsIds = searchLibrary.getTreatmentRequestsForPatient(dbAddress, patientId);
    (totalNumberFound, treatmentRequestsIds) = utilities.getSlicedArray(treatmentRequestsIds, offset, limit, seed);
  }

  function fetchAllTreatmentRequests (
    address dbAddress,
    uint offset, // starting from offset: 0-based
    uint limit, // not more than limit
    uint seed // seed value to give the illusion of randomisation
  )
    internal
    view
    returns (
      uint totalNumberFound,
      uint[] treatmentRequestsIds
    )
  {
    treatmentRequestsIds = searchLibrary.getAllTreatmentRequests(dbAddress);
    (totalNumberFound, treatmentRequestsIds) = utilities.getSlicedArray(treatmentRequestsIds, offset, limit, seed);
  }

  function fetchTreatmentApplicationsForPatient (
    address dbAddress,
    address patientId,
    uint offset, // starting from offset: 0-based
    uint limit, // not more than limit
    uint seed // seed value to give the illusion of randomisation
  )
    internal
    view
    returns (
      uint totalNumberFound,
      uint[] treatmentApplicationsIds
    )
  {
    treatmentApplicationsIds = searchLibrary.getTreatmentApplicationsForPatient(dbAddress, patientId);
    (totalNumberFound, treatmentApplicationsIds) = utilities.getSlicedArray(treatmentApplicationsIds, offset, limit, seed);
  }

  function fetchTreatmentApplicationsForDentist (
    address dbAddress,
    address dentistId,
    uint offset, // starting from offset: 0-based
    uint limit, // not more than limit
    uint seed // seed value to give the illusion of randomisation
  )
    internal
    view
    returns (
      uint totalNumberFound,
      uint[] treatmentApplicationsIds
    )
  {
    treatmentApplicationsIds = searchLibrary.getTreatmentApplicationsForDentist(dbAddress, dentistId);
    (totalNumberFound, treatmentApplicationsIds) = utilities.getSlicedArray(treatmentApplicationsIds, offset, limit, seed);
  }
}
