pragma solidity 0.4.18;
import "./Restrictor.sol";
import "../lib/odll/userManager.sol";

contract TreatmentRequestWriter is Restrictor {

  function TreatmentRequestWriter(address _dbAddress) public {
    require(_dbAddress != 0x0);
    dbAddress = _dbAddress;
  }

  function writeTreatmentRequest (
    address dentistId,
    address patientId,
    bool hasCaseId,
    uint caseId,
    bytes32 insurance,
    bytes32[] scanResults,
    bytes32 comment
  )
    external
    onlyPermittedSmartContract
  {
    userManager.writeTreatmentRequest(dbAddress, dentistId, msg.sender, hasCaseId, caseId, insurance, scanResults, comment);
  }

  function cancelTreatmentRequest (
    address patientId,
    uint treatmentRequestId
  )
    external
    onlyPermittedSmartContract
  {
    userManager.cancelTreatmentRequest(dbAddress, msg.sender, treatmentRequestId);
  }
}
