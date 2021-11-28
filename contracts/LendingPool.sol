//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./LendToken.sol";

contract LendingPool is Context, Ownable, ReentrancyGuard {
  IERC20 assetToken;
  LendToken peggToken;

  struct Lender {
    uint256 accountId;
    address walletAddress;
    uint256 loanAmount;
    uint256 creditDecision;
  }

  constructor(IERC20 _assetToken, LendToken _peggToken) {
    assetToken = _assetToken;
    peggToken = _peggToken;
  }

  /**
   * @dev assetToken must be approved before transfer
   */
  function deposit(uint256 amount) public nonReentrant {
    require(amount > 0, "NO_ZERO_AMOUNT");
    address sender = _msgSender();
    assetToken.transferFrom(sender, address(this), amount);
    peggToken.mint(sender, amount);
  }

  function withdraw(uint256 amount) public nonReentrant {
    require(amount > 0, "NO_ZERO_AMOUNT");
    address sender = _msgSender();
    peggToken.burnFrom(sender, amount);
    assetToken.transfer(sender, amount);
  }

  function getProposal(uint256 proposalId) public view returns (uint256) {}

  function newProposal() public view onlyOwner {}

  function getActiveLoanID() public view {}

  function revokeMyProposal(uint256 proposalId) public view {} //proposal Owner only

  function getProposalDetails(uint256 proposalId) public view {}

  function callAirnode() public view {}
}
