//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./LendToken.sol";

contract LendingPool is Context, Ownable, ReentrancyGuard {
  struct Loan {
    uint256 amount;
    uint256 interest;
    uint8 installmentMonths;
    address recipient;
  }

  struct Lender {
    uint256 accountId;
    address walletAddress;
    uint256 loanAmount;
    uint256 creditDecision;
  }

  IERC20 assetToken;
  LendToken peggToken;
  uint256 public LIMIT_PARTICIPATION;
  uint256 public LENDING_INTEREST_RATE;
  uint256 public BORROWING_INTEREST_RATE;
  mapping(address => Loan) public loans;

  constructor(IERC20 _assetToken, LendToken _peggToken) {
    assetToken = _assetToken;
    peggToken = _peggToken;
  }

  /**
   * @dev assetToken must be approved before transfer
   */
  function deposit(uint256 amount) public nonReentrant {
    require(amount > 0, "NO_ZERO_AMOUNT");
    require(exceedsDepositLimit(amount) == false, "AMOUNT_EXCEEDS_LIMIT");

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

  function setLimitDeposit(uint256 amount) public onlyOwner {
    LIMIT_PARTICIPATION = amount;
  }

  function setLendingInterest(uint256 amount) public onlyOwner {
    LENDING_INTEREST_RATE = amount;
  }

  function setBorrowingInterest(uint256 amount) public onlyOwner {
    BORROWING_INTEREST_RATE = amount;
  }

  function poolBalance() public view returns (uint256) {
    return assetToken.balanceOf(address(this));
  }

  function exceedsDepositLimit(uint256 amount) public view returns (bool) {
    uint256 sum = amount + poolBalance();
    return (amount * 100) / sum > LIMIT_PARTICIPATION;
  }

  function crateLoan(
    uint256 amount,
    uint256 interest,
    uint8 installmentMonths,
    address recipient
  ) public {
    Loan memory nxtLoan;
    nxtLoan.amount = amount;
    nxtLoan.interest = interest;
    nxtLoan.installmentMonths = installmentMonths;
    nxtLoan.recipient = recipient;
    loans[recipient] = nxtLoan;
    assetToken.transfer(recipient, amount);
  }
}
