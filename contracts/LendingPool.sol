//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./LendToken.sol";

contract LendingPool is Context, Ownable, ReentrancyGuard {
  struct Loan {
    uint256 amount;
    uint256 interest;
    uint256 currentInterest;
    uint256 startDate;
    uint8 installmentNumber;
    uint8 installmentAmount;
    address recipient;
  }

  enum LaboralStatus {
    Employed,
    SelfEmployee,
    Student,
    Unemployed
  }

  struct Borrower {
    uint256 age;
    LaboralStatus status;
    uint256 income;
    uint256 walletActivity;
    uint256 comunityScore;
    bool evidence;
    bool exist;
  }

  /**
   * @dev lendToken is 1:1 with asset token. Helps calculate and represent share of the pool
   */
  IERC20 public assetToken;
  LendToken public lendToken;
  uint256 public expectedInterest; //this is EXPECTED interest received. It assumes all debt will be paid.
  uint256 public limitParticipation = 100;
  mapping(address => uint256) public currentLoan;
  mapping(address => Borrower) public borrowerData;
  mapping(address => mapping(uint256 => Loan)) loans;

  constructor(IERC20 _assetToken) {
    assetToken = _assetToken;
    lendToken = new LendToken();
  }

  /**
   * @dev assetToken must be approved before transfer
   */
  function deposit(uint256 amount) public nonReentrant {
    require(amount > 0, "NO_ZERO_AMOUNT");
    require(exceedsDepositLimit(amount) == false, "AMOUNT_EXCEEDS_LIMIT");

    address sender = _msgSender();
    assetToken.transferFrom(sender, address(this), amount);
    lendToken.mint(sender, amount);
  }

  function withdraw(uint256 amount) public nonReentrant {
    require(amount > 0, "NO_ZERO_AMOUNT");
    address sender = _msgSender();
    lendToken.burnFrom(sender, amount);
    assetToken.transfer(sender, amount);
  }

  function setLimitDeposit(uint256 amount) public onlyOwner {
    limitParticipation = amount;
  }

  function exceedsDepositLimit(uint256 amount) internal view returns (bool) {
    uint256 sum = amount + poolBalance();
    return (amount * 100) / sum > limitParticipation;
  }

  function poolBalance() internal view returns (uint256) {
    return assetToken.balanceOf(address(this));
  }

  function createLoan(
    uint256 amount,
    uint256 interest,
    uint8 installmentNumber,
    uint8 installmentAmount,
    address recipient
  ) public {
    require(borrowerData[recipient].exist, "BORROWER_DOESNT_EXIST");
    require(canApproveLoan(installmentAmount, recipient), "CANNOT_APPROVE_LOAN");
    Loan memory nxtLoan;
    nxtLoan.amount = amount;
    nxtLoan.interest = interest;
    nxtLoan.installmentNumber = installmentNumber;
    nxtLoan.installmentAmount = installmentAmount;
    nxtLoan.recipient = recipient;
    nxtLoan.startDate = block.timestamp;

    uint256 loanNumber = currentLoan[recipient];
    loans[recipient][loanNumber] = nxtLoan;
    currentLoan[recipient] = loanNumber + 1;

    uint256 paidAmount = (amount * (interest + 100)) / 100;
    expectedInterest += ((paidAmount + poolBalance() - amount) * 100) / poolBalance() - 100;
    assetToken.transfer(recipient, amount);
  }

  function canApproveLoan(uint256 installmentAmount, address recipient) public returns (bool) {
    Borrower memory borrower = borrowerData[recipient];
    uint256 agePts = getAgeScore(borrower.age);
    uint256 laboralPts = getStatusScore(borrower.status);
    uint256 incomePts = getIncomeScore(borrower.income - installmentAmount);
    uint256 walletPts = getWalletScore(borrower.walletActivity);
    uint256 comunityPts = getCommunityScore(borrower.comunityScore);
    uint256 evidenceScore = borrower.evidence ? 5 : 0;

    uint256 score = ((agePts +
      laboralPts +
      incomePts +
      walletPts +
      comunityPts +
      evidenceScore) * 100) / 55;
    return score >= 3 ? true : false;
  }

  function payLoan(
    uint256 amount,
    uint256 loanId,
    address loanRecipient
  ) public {
    Loan storage curLoan = loans[loanRecipient][loanId];
    require(curLoan.amount > 0, "LOAN_ALREADY_PAID");
    require(amount >= curLoan.installmentAmount, "NOT_INSTALLMENT_AMOUNT");

    uint256 finalAmount = curLoan.installmentAmount > curLoan.amount
      ? curLoan.amount
      : curLoan.installmentAmount;
    uint256 prevAmount = curLoan.amount;

    assetToken.transferFrom(loanRecipient, address(this), finalAmount);

    unchecked {
      curLoan.currentInterest = ((curLoan.amount * curLoan.interest) / 100) / 12;
      uint256 principal = curLoan.installmentAmount - curLoan.currentInterest;
      curLoan.amount -= principal;
    }

    if (curLoan.amount > prevAmount) curLoan.amount = 0;

    lendToken.addPoolGains(curLoan.currentInterest);
  }

  function getLoan(address borrower, uint256 loanId) public view returns (Loan memory) {
    return loans[borrower][loanId];
  }

  function registerBorrower(
    address borrowerAddress,
    uint256 age,
    LaboralStatus status,
    uint256 income,
    uint256 activity,
    uint256 score,
    bool evidence
  ) public onlyOwner {
    borrowerData[borrowerAddress] = Borrower(
      age,
      status,
      income,
      activity,
      score,
      evidence,
      true
    );
  }

  function getAgeScore(uint256 age) internal pure returns (uint256 score) {
    if (age >= 18 && age <= 22) return 6;
    if (age >= 23 && age <= 40) return 10;
    if (age >= 41 && age <= 60) return 8;
    if (age >= 60) return 3;
  }

  function getStatusScore(LaboralStatus status) internal returns (uint256 score) {
    if (uint256(status) == uint256(LaboralStatus.Employed)) return 10;
    if (uint256(status) == uint256(LaboralStatus.SelfEmployee)) return 8;
    if (uint256(status) == uint256(LaboralStatus.Student)) return 3;
    if (uint256(status) == uint256(LaboralStatus.Unemployed)) return 0;
  }

  function getIncomeScore(uint256 delta) internal pure returns (uint256 score) {
    if (delta >= 0 && delta <= 50) return 10;
    if (delta >= 51 && delta <= 100) return 5;
    if (delta >= 100) return 0;
  }

  function getWalletScore(uint256 activity) internal pure returns (uint256 score) {
    if (activity >= 0 && activity <= 4) return 3;
    if (activity >= 5 && activity <= 15) return 6;
    if (activity >= 15 && activity <= 25) return 8;
    if (activity >= 25) return 10;
  }

  function getCommunityScore(uint256 comScore) internal pure returns (uint256 score) {
    if (comScore >= 0 && comScore <= 2) return 0;
    if (comScore == 3) return 3;
    if (comScore == 4) return 7;
    if (comScore == 5) return 10;
  }
}
