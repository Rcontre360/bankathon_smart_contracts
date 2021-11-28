//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Loan is Ownable {
  struct Lender {
    uint256 accountId;
    address walletAddress;
    uint256 loanAmount;
    uint256 creditDecision;
  }

  function getProposal(uint256 proposalId) public view returns (uint256) {}

  function newProposal() public onlyOwner {}

  function getActiveLoanID() public view {}

  function revokeMyProposal(uint256 proposalId) public {} //proposal Owner only

  function getProposalDetails(uint256 proposalId) public {}
}
