//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@api3/airnode-protocol/contracts/AirnodeClient.sol";

contract ScoreCalculator is AirnodeClient {
    mapping(bytes32 => bool) public incomingFulfillments;
    mapping(bytes32 => bytes32) public fulfilledData;

    constructor(address airnodeAddress) public AirnodeClient(airnodeAddress) {}

    function getCustomerAttributes(uint256 bankId, uint256 customerId)
        public
        returns (bytes32)
    {
        // call makeRequest
    }

    function getCustomerAttributes(bytes32 requestId)
        public
        view
        returns (bytes32)
    {
        return fulfilledData[requestId];
    }

    function canApproveLoan(
        uint256 amount,
        uint256 interest,
        uint8 installmentMonths,
        uint8 installmentAmount,
        address recipient,
        bytes32 requestId
    ) public view returns (bool) {
        //get user data stored and calculate risk of loan
        return true;
    }

    function makeRequest(
        bytes32 providerId,
        bytes32 endpointId,
        uint256 requesterInd,
        address designatedWallet,
        bytes calldata parameters
    ) external {
        bytes32 requestId = airnode.makeFullRequest(
            providerId,
            endpointId,
            requesterInd,
            designatedWallet,
            address(this),
            this.fulfill.selector,
            parameters
        );
        incomingFulfillments[requestId] = true;
    }

    function fulfill(
        bytes32 requestId,
        uint256 statusCode,
        bytes32 data
    ) external onlyAirnode {
        require(incomingFulfillments[requestId], "No such request made");
        delete incomingFulfillments[requestId];
        if (statusCode == 0) {
            fulfilledData[requestId] = data;
        } else {
            fulfilledData[requestId] = bytes32(statusCode);
        }
    }
}
