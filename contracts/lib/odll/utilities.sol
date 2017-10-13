pragma solidity ^0.4.11;

import "../../odll/ODLLDB.sol";

library utilities {
  function getCount(address dbAddress, string countKey) internal returns(uint) {
    return ODLLDB(dbAddress).getUIntValue(sha3(countKey));
  }

  function createNext(address dbAddress, string countKey) internal returns(uint index) {
    var count = getCount(dbAddress, countKey);
    ODLLDB(dbAddress).addUIntValue(sha3(countKey), 1);
    return count + 1;
  }

  function containsValue(address dbAddress, uint id, string key, uint8[] array) internal returns(bool) {
    if (array.length == 0) {
      return true;
    }
    var val = ODLLDB(dbAddress).getUInt8Value(sha3(key, id));
    for (uint i = 0; i < array.length ; i++) {
      if (array[i] == val) {
        return true;
      }
    }

    return false;
  }

  function addArrayItem(address dbAddress, string key, string countKey, address val) internal {
    var idx = ODLLDB(dbAddress).getUIntValue(sha3(countKey));
    ODLLDB(dbAddress).setAddressValue(sha3(key, idx), val);
    ODLLDB(dbAddress).setUIntValue(sha3(countKey), idx + 1);
  }

  function getAddressArray(address dbAddress, string key, string countKey) internal returns(address[] result) {
    var totalNumberOfUsers = ODLLDB(dbAddress).getUIntValue(sha3(countKey));
    result = new address[](totalNumberOfUsers);
    for (uint i = 0; i < totalNumberOfUsers; i++) {
      result[i] = ODLLDB(dbAddress).getAddressValue(sha3(key, i));
    }

    return result;
  }

  function getIdArrayItemsCount(address dbAddress, uint id, string countKey) internal returns(uint) {
    return ODLLDB(dbAddress).getUIntValue(sha3(countKey, id));
  }

  function getIdArrayItemsCount(address dbAddress, address id, string countKey) internal returns(uint) {
    return ODLLDB(dbAddress).getUIntValue(sha3(countKey, id));
  }

  function addIdArrayItem(address dbAddress, uint id, string key, string countKey, uint val) internal {
    var idx = getIdArrayItemsCount(dbAddress, id, countKey);
    ODLLDB(dbAddress).setUIntValue(sha3(key, id, idx), val);
    ODLLDB(dbAddress).setUIntValue(sha3(countKey, id), idx + 1);
  }

  function addIdArrayItem(address dbAddress, uint id, string key, string countKey, address val) internal {
    var idx = getIdArrayItemsCount(dbAddress, id, countKey);
    ODLLDB(dbAddress).setAddressValue(sha3(key, id, idx), val);
    ODLLDB(dbAddress).setUIntValue(sha3(countKey, id), idx + 1);
  }

  function addIdArrayItem(address dbAddress, address id, string key, string countKey, uint val) internal {
    var idx = getIdArrayItemsCount(dbAddress, id, countKey);
    ODLLDB(dbAddress).setUIntValue(sha3(key, id, idx), val);
    ODLLDB(dbAddress).setUIntValue(sha3(countKey, id), idx + 1);
  }

  function setIdArray(address dbAddress, uint id, string key, string countKey, uint[] array) internal {
    for (uint i = 0; i < array.length; i++) {
      require(array[i] != 0);
      ODLLDB(dbAddress).setUIntValue(sha3(key, id, i), array[i]);
    }

    ODLLDB(dbAddress).setUIntValue(sha3(countKey, id), array.length);
  }

  function setIdArray(address dbAddress, address id, string key, string countKey, uint[] array) internal {
    for (uint i = 0; i < array.length; i++) {
      require(array[i] != 0);
      ODLLDB(dbAddress).setUIntValue(sha3(key, id, i), array[i]);
    }

    ODLLDB(dbAddress).setUIntValue(sha3(countKey, id), array.length);
  }

  function getIdArray(address dbAddress, uint id, string key, string countKey) internal returns(uint[] result) {
    uint count = getIdArrayItemsCount(dbAddress, id, countKey);
    result = new uint[](count);
    for (uint i = 0; i < count; i++) {
      result[i] = ODLLDB(dbAddress).getUIntValue(sha3(key, id, i));
    }

    return result;
  }

  function getIdArray(address dbAddress, address id, string key, string countKey) internal returns(uint[] result) {
    uint count = getIdArrayItemsCount(dbAddress, id, countKey);
    result = new uint[](count);
    for (uint i = 0; i < count; i++) {
      result[i] = ODLLDB(dbAddress).getUIntValue(sha3(key, id, i));
    }

    return result;
  }

  function setIdArray(address dbAddress, uint id, string key, string countKey, address[] array) internal {
    for (uint i = 0; i < array.length; i++) {
      require(array[i] != 0x0);
      ODLLDB(dbAddress).setAddressValue(sha3(key, id, i), array[i]);
    }

    ODLLDB(dbAddress).setUIntValue(sha3(countKey, id), array.length);
  }

  function getAddressIdArray(address dbAddress, uint id, string key, string countKey) internal returns(address[] result) {
    uint count = getIdArrayItemsCount(dbAddress, id, countKey);
    result = new address[](count);
    for (uint i = 0; i < count; i++) {
      result[i] = ODLLDB(dbAddress).getAddressValue(sha3(key, id, i));
    }

    return result;
  }

  function addRemovableIdArrayItem(address dbAddress, uint[] ids, string key, string countKey, string keysKey, uint val) internal {
    if (ids.length == 0) {
      return;
    }
    for (uint i = 0; i < ids.length; i++) {
      if (ODLLDB(dbAddress).getUInt8Value(sha3(key, ids[i], val)) == 0) { // never seen before
        addIdArrayItem(dbAddress, ids[i], keysKey, countKey, val);
      }

      ODLLDB(dbAddress).setUInt8Value(sha3(key, ids[i], val), 1); // 1 == active
    }
  }

  function addRemovableIdArrayItem(address dbAddress, uint[] ids, string key, string countKey, string keysKey, address val) internal {
    if (ids.length == 0) {
      return;
    }

    for (uint i = 0; i < ids.length; i++) {
      if (ODLLDB(dbAddress).getUInt8Value(sha3(key, ids[i], val)) == 0) { // never seen before
        addIdArrayItem(dbAddress, ids[i], keysKey, countKey, val);
      }

      ODLLDB(dbAddress).setUInt8Value(sha3(key, ids[i], val), 1); // 1 == active
    }
  }

  function getRemovableIdArrayItems(address dbAddress, uint id, string key, string countKey, string keysKey)
    internal returns (uint[] result)
  {
    var count = getIdArrayItemsCount(dbAddress, id, countKey);
    result = new uint[](count);
    uint j = 0;
    for (uint i = 0; i < count; i++) {
      var itemId = ODLLDB(dbAddress).getUIntValue(sha3(keysKey, id, i));
      if (ODLLDB(dbAddress).getUInt8Value(sha3(key, id, itemId)) == 1) { // 1 == active
        result[j] = itemId;
        j++;
      }
    }

    return take(j, result);
  }

  function getRemovableIdArrayAddressItems(address dbAddress, uint id, string key, string countKey, string keysKey)
    internal returns (address[] result)
  {
    var count = getIdArrayItemsCount(dbAddress, id, countKey);
    result = new address[](count);
    uint j = 0;
    for (uint i = 0; i < count; i++) {
      var itemId = ODLLDB(dbAddress).getAddressValue(sha3(keysKey, id, i));
      if (ODLLDB(dbAddress).getUInt8Value(sha3(key, id, itemId)) == 1) { // 1 == active
        result[j] = itemId;
        j++;
      }
    }

    return take(j, result);
  }

  function removeIdArrayItem(address dbAddress, uint[] ids, string key, uint val) internal {
    if (ids.length == 0) {
      return;
    }

    for (uint i = 0; i < ids.length; i++) {
      ODLLDB(dbAddress).setUInt8Value(sha3(key, ids[i], val), 2); // 2 == blocked
    }
  }

  function removeIdArrayItem(address dbAddress, uint[] ids, string key, address val) internal {
    if (ids.length == 0) {
      return;
    }

    for (uint i = 0; i < ids.length; i++) {
      ODLLDB(dbAddress).setUInt8Value(sha3(key, ids[i], val), 2); // 2 == blocked
    }
  }

  function getPage(uint[] array, uint offset, uint limit, bool cycle) internal returns (uint[] result) {
    uint j = 0;
    uint length = array.length;
    if (offset >= length || limit == 0) {
      return result;
    }

    result = new uint[](limit);
    for (uint i = offset; i < (offset + limit); i++) {
      if (length == i) {
        break;
      }

      result[j] = array[i];
      j++;
    }

    if (cycle && j < limit) {
      var k = limit - j;
      for (i = 0; i <= k; i++) {
        if (limit == j) {
          break;
        }

        result[j] = array[i];
        j++;
      }
    }

    return take(j, result);
  }

  function getPage(address[] array, uint offset, uint limit, bool cycle) internal returns (address[] result) {
    uint j = 0;
    uint length = array.length;
    if (offset >= length || limit == 0) {
      return result;
    }

    result = new address[](limit);
    for (uint i = offset; i < (offset + limit); i++) {
      if (length == i) {
        break;
      }

      result[j] = array[i];
      j++;
    }

    if (cycle && j < limit) {
      var k = limit - j;
      for (i = 0; i <= k; i++) {
        if (limit == j) {
          break;
        }

        result[j] = array[i];
        j++;
      }
    }

    return take(j, result);
  }

  /* Assumes a and b are sorted */
  function intersect(uint[] a, uint[] b) internal returns(uint[] c) {
    uint aLen = a.length;
    uint bLen = b.length;
    if (aLen == 0 || bLen == 0) {
      return c;
    }
    c = new uint[](aLen);
    uint i = 0;
    uint j = 0;
    uint k = 0;
    while (i < aLen && j < bLen) {
      if (a[i] > b[j]) {
        j++;
      } else if (a[i] < b[j]) {
        i++;
      } else {
        c[k] = a[i];
        i++;
        j++;
        k++;
      }
    }

    return take(k, c);
  }

  /* Assumes a and b are sorted */
  function intersect(address[] a, address[] b) internal returns(address[] c) {
    uint aLen = a.length;
    uint bLen = b.length;
    if (aLen == 0 || bLen == 0) {
      return c;
    }
    c = new address[](aLen);
    uint i = 0;
    uint j = 0;
    uint k = 0;
    while (i < aLen && j < bLen) {
      if (a[i] > b[j]) {
        j++;
      } else if (a[i] < b[j]) {
        i++;
      } else {
        c[k] = a[i];
        i++;
        j++;
        k++;
      }
    }

    return take(k, c);
  }

  /* Assumes a and b are sorted */
  function union(uint[] a, uint[] b) internal returns(uint[] c) {
    uint aLen = a.length;
    uint bLen = b.length;
    c = new uint[](aLen + bLen);
    uint i = 0;
    uint j = 0;
    uint k = 0;
    while (i < aLen && j < bLen) {
      if (a[i] < b[j]) {
        c[k] = a[i];
        i++;
      } else if (b[j] < a[i]) {
        c[k] = b[j];
        j++;
      } else {
        c[k] = a[i];
        i++;
        j++;
      }

      k++;
    }

    while (i < aLen) {
      c[k] = a[i];
      i++;
      k++;
    }

    while (j < bLen) {
      c[k] = b[j];
      j++;
      k++;
    }

    return take(k, c);
  }

  /* Assumes a and b are sorted */
  function union(address[] a, address[] b) internal returns(address[] c) {
    uint aLen = a.length;
    uint bLen = b.length;
    c = new address[](aLen + bLen);
    uint i = 0;
    uint j = 0;
    uint k = 0;
    while (i < aLen && j < bLen) {
      if (a[i] < b[j]) {
        c[k] = a[i];
        i++;
      } else if (b[j] < a[i]) {
        c[k] = b[j];
        j++;
      } else {
        c[k] = a[i];
        i++;
        j++;
      }

      k++;
    }

    while (i < aLen) {
      c[k] = a[i];
      i++;
      k++;
    }

    while (j < bLen) {
      c[k] = b[j];
      j++;
      k++;
    }

    return take(k, c);
  }

  function diff(uint[] _old, uint[] _new) internal returns(uint[] added, uint[] removed) {
    if (_old.length == 0 && _new.length == 0) {
      return (added, removed);
    }

    var maxCount = _old.length + _new.length;
    added = new uint[](maxCount);
    removed = new uint[](maxCount);

    _old = sort(_old);
    _new = sort(_new);
    uint ol_i = 0;
    uint ne_i = 0;
    uint ad_i = 0;
    uint re_i = 0;
    while (ol_i < _old.length && ne_i < _new.length) {
      if (_old[ol_i] > _new[ne_i]) {
        added[ad_i] = _new[ne_i];
        ne_i++;
        ad_i++;
      } else if (_old[ol_i] < _new[ne_i]) {
        removed[re_i] = _old[ol_i];
        ol_i++;
        re_i++;
      } else {
        ol_i++;
        ne_i++;
      }
    }

    if (_old.length > ol_i) {
      while (ol_i < _old.length) {
        removed[re_i] = _old[ol_i];
        ol_i++;
        re_i++;
      }
    }

    if (_new.length > ne_i) {
      while (ne_i < _new.length) {
        added[ad_i] = _new[ne_i];
        ne_i++;
        ad_i++;
      }
    }

    return (take(ad_i, added), take(re_i, removed));
  }

  function sort(uint[] array) internal returns (uint[]) {
    for (uint i = 1; i < array.length; i++) {
      var t = array[i];
      var j = i;
      while(j > 0 && array[j - 1] > t) {
        array[j] = array[j - 1];
        j--;
      }

      array[j] = t;
    }

    return array;
  }

  function sort(address[] array) internal returns (address[]) {
    for (uint i = 1; i < array.length; i++) {
      var t = array[i];
      var j = i;
      while(j > 0 && array[j - 1] > t) {
        array[j] = array[j - 1];
        j--;
      }

      array[j] = t;
    }

    return array;
  }

  function sortDescBy(uint[] array, uint[] compareArray) internal returns (uint[]) {
    for (uint i = 1; i < array.length; i++) {
      var t = array[i];
      var t2 = compareArray[i];
      var j = i;
      while(j > 0 && compareArray[j - 1] < t2) {
        array[j] = array[j - 1];
        compareArray[j] = compareArray[j - 1];
        j--;
      }

      array[j] = t;
      compareArray[j] = t2;
    }

    return array;
  }


  function take(uint n, uint[] array) internal returns(uint[] result) {
    if (n > array.length) {
      return array;
    }

    result = new uint[](n);
    for (uint i = 0; i < n ; i++) {
      result[i] = array[i];
    }

    return result;
  }

  function take(uint n, bytes32[] array) internal returns(bytes32[] result) {
    if (n > array.length) {
      return array;
    }

    result = new bytes32[](n);
    for (uint i = 0; i < n ; i++) {
      result[i] = array[i];
    }

    return result;
  }

  function take(uint n, address[] array) internal returns(address[] result) {
    if (n > array.length) {
      return array;
    }

    result = new address[](n);
    for (uint i = 0; i < n ; i++) {
      result[i] = array[i];
    }

    return result;
  }

  function findTopNValues(uint[] values, uint n) internal returns(uint[]) {
    uint length = values.length;

    for (uint i = 0; i <= n; i++) {
      uint maxPos = i;
      for (uint j = i + 1; j < length; j++) {
        if (values[j] > values[maxPos]) {
          maxPos = j;
        }
      }

      if (maxPos != i) {
        uint maxValue = values[maxPos];
        values[maxPos] = values[i];
        values[i] = maxValue;
      }
    }

    return take(n, values);
  }

  function filter(
    address dbAddress,
    function (address, uint[] memory, uint) returns (bool) f,
    uint[] memory items,
    uint[] memory args
  )
    internal returns (uint[] memory r)
  {
    uint j = 0;
    r = new uint[](items.length);
    for (uint i = 0; i < items.length; i++) {
      if (f(dbAddress, args, items[i])) {
        r[j] = items[i];
        j++;
      }
    }

    return take(j, r);
  }

  function filter(
    address dbAddress,
    function (address, address[] memory, uint) returns (bool) f,
    uint[] memory items,
    address[] memory args
  )
    internal returns (uint[] memory r)
  {
    uint j = 0;
    r = new uint[](items.length);
    for (uint i = 0; i < items.length; i++) {
      if (f(dbAddress, args, items[i])) {
        r[j] = items[i];
        j++;
      }
    }

    return take(j, r);
  }

  function filter(
    address dbAddress,
    function (address, uint[] memory, uint[] memory, uint) returns (bool) f,
    uint[] memory items,
    uint[] memory args,
    uint[] memory args2
  )
    internal returns (uint[] memory r)
  {
    uint j = 0;
    r = new uint[](items.length);
    for (uint i = 0; i < items.length; i++) {
      if (f(dbAddress, args, args2, items[i])) {
        r[j] = items[i];
        j++;
      }
    }

    return take(j, r);
  }

  function contains(address[] array, address val) internal returns(bool) {
    for (uint i = 0; i < array.length ; i++) {
      if (array[i] == val) {
        return true;
      }
    }

    return false;
  }

  function contains(uint[] array, uint val) internal returns(bool) {
    for (uint i = 0; i < array.length ; i++) {
      if (array[i] == val) {
        return true;
      }
    }

    return false;
  }

  function bytes32ToString(bytes32 x) constant returns (string) {
    bytes memory bytesString = new bytes(32);
    uint charCount = 0;
    for (uint j = 0; j < 32; j++) {
      byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
      if (char != 0) {
        bytesString[charCount] = char;
        charCount++;
      }
    }

    bytes memory bytesStringTrimmed = new bytes(charCount);
    for (j = 0; j < charCount; j++) {
      bytesStringTrimmed[j] = bytesString[j];
    }

    return string(bytesStringTrimmed);
  }

  function intersectBudgetAndStateBasedDentists
  (
    address dbAddress,
    address[] budgetBasedDentistsIds,
    address[] stateBasedDentistsIds
  )
    internal returns (address[] result)
  {
    var maxCount = ODLLDB(dbAddress).getUIntValue(sha3("dentists/count"));
    if (maxCount == 0) {
      return result;
    }

    budgetBasedDentistsIds = sort(budgetBasedDentistsIds);
    stateBasedDentistsIds = sort(stateBasedDentistsIds);

    return intersect(budgetBasedDentistsIds, stateBasedDentistsIds);
  }

  function unionSkills
  (
    address db,
    uint[] skillsOr,
    function(address, uint) returns (uint[] memory) getFromSkills,
    uint[] fromItems
  )
    internal returns (uint[] result)
  {
    result = intersect(fromItems, sort(getFromSkills(db, skillsOr[0])));
    for (uint i = 1; i < skillsOr.length ; i++) {
      result = union(result, intersect(fromItems, sort(getFromSkills(db, skillsOr[i]))));
    }

    return result;
  }

  function unionSkills
  (
    address db,
    uint[] skillsOr,
    function(address, uint) returns (uint[] memory) getFromSkills
  )
    internal returns (uint[] result)
  {
    result = sort(getFromSkills(db, skillsOr[0]));
    for (uint i = 1; i < skillsOr.length ; i++) {
      result = union(result, sort(getFromSkills(db, skillsOr[i])));
    }

    return result;
  }

  function unionSkills
  (
    address db,
    uint[] skillsOr,
    function(address, uint) returns (address[] memory) getFromSkills,
    address[] fromItems
  )
    internal returns (address[] result)
  {
    result = intersect(fromItems, sort(getFromSkills(db, skillsOr[0])));
    for (uint i = 1; i < skillsOr.length ; i++) {
      result = union(result, intersect(fromItems, sort(getFromSkills(db, skillsOr[i]))));
    }

    return result;
  }

  function unionSkills
  (
    address db,
    uint[] skillsOr,
    function(address, uint) returns (address[] memory) getFromSkills
  )
    internal returns (address[] result)
  {
    result = sort(getFromSkills(db, skillsOr[0]));
    for (uint i = 1; i < skillsOr.length ; i++) {
      result = union(result, sort(getFromSkills(db, skillsOr[i])));
    }

    return result;
  }
}
