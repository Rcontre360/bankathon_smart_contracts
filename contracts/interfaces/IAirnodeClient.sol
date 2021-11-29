//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IAirnodeClient {
    function makeRequest(
        bytes32 providerId,
        bytes32 endpointId,
        uint256 requesterInd,
        address designatedWallet,
        bytes calldata parameters
    ) external;
}
