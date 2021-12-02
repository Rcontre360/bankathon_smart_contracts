//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./LendToken.sol";

interface IScoreCalculator {
  function canApproveLoan(
    uint256 amount,
    uint256 interest,
    uint8 installmentNumber,
    uint8 installmentAmount,
    address recipient,
    bytes32 requestId
  ) external returns (bool);
}

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

  struct Lender {
    uint256 accountId;
    address walletAddress;
    uint256 loanAmount;
    uint256 creditDecision;
  }

  /**
   * @dev lendToken is 1:1 with asset token. Helps calculate and represent share of the pool
   */
  IERC20 public assetToken;
  IScoreCalculator public scoreCalculator;
  LendToken public lendToken;
  uint256 public expectedInterest; //this is EXPECTED interest received. It assumes all debt will be paid.
  uint256 public limitParticipation = 100;
  mapping(address => uint256) public currentLoan;
  mapping(address => mapping(uint256 => Loan)) loans;

  constructor(IERC20 _assetToken, IScoreCalculator _scoreCalculator) {
    assetToken = _assetToken;
    lendToken = new LendToken();
    scoreCalculator = _scoreCalculator;
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
    address recipient,
    bytes32 requestId
  ) public {
    require(
      scoreCalculator.canApproveLoan(
        amount,
        interest,
        installmentNumber,
        installmentAmount,
        recipient,
        requestId
      ),
      "CANNOT_APPROVE_LOAN"
    );
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

  function payLoan(
    uint256 amount,
    uint256 loanId,
    address loanRecipient
  ) public {
    Loan storage curLoan = loans[loanRecipient][loanId];
    require(curLoan.amount > 0, "LOAN_ALREADY_PAID");
    require(amount >= curLoan.installmentAmount, "NOT_INSTALLMENT_AMOUNT");

    console.log("payLoan % % %", curLoan.interest, curLoan.amount, curLoan.currentInterest);
    console.log("payLoan %", curLoan.installmentAmount);
    uint256 finalAmount = curLoan.installmentAmount > curLoan.amount
      ? curLoan.amount
      : curLoan.installmentAmount;

    assetToken.transferFrom(loanRecipient, address(this), finalAmount);

    curLoan.currentInterest =
      ((curLoan.amount * curLoan.interest) / 100) /
      curLoan.installmentNumber;
    curLoan.amount -= finalAmount - curLoan.currentInterest;
    lendToken.addPoolGains(curLoan.currentInterest);
  }

  function getLoan(address borrower, uint256 loanId) public view returns (Loan memory) {
    return loans[borrower][loanId];
  }
}
