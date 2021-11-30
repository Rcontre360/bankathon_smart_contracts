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
   * @dev peggToken is 1:1 with asset token. Helps calculate and represent share of the pool
   */
  IERC20 public assetToken;
  IScoreCalculator public scoreCalculator;
  LendToken public peggToken;
  int256 public expectedInterest; //this is EXPECTED interest received. It assumes all debt will be paid.
  uint256 public limitParticipation = 100;
  mapping(address => Loan) public loans;

  constructor(IERC20 _assetToken, IScoreCalculator _scoreCalculator) {
    assetToken = _assetToken;
    peggToken = new LendToken();
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
    peggToken.mint(sender, amount);
  }

  function withdraw(uint256 amount) public nonReentrant {
    require(amount > 0, "NO_ZERO_AMOUNT");
    address sender = _msgSender();
    peggToken.burnFrom(sender, amount);
    assetToken.transfer(sender, amount);
  }

  function setLimitDeposit(uint256 amount) public onlyOwner {
    limitParticipation = amount;
  }

  function exceedsDepositLimit(uint256 amount) public view returns (bool) {
    uint256 sum = amount + poolBalance();
    return (amount * 100) / sum > limitParticipation;
  }

  function poolBalance() public view returns (uint256) {
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
    loans[recipient] = nxtLoan;

    //@TODO update global interest rate
    assetToken.transfer(recipient, amount);
  }

  function payLoan(uint256 amount, address loanRecipient) public {
    //@TODO update global interest rate
    Loan storage curLoan = loans[loanRecipient];
    require(curLoan.amount > 0, "LOAN_ALREADY_PAID");
    require(amount == curLoan.installmentAmount, "NOT_INSTALLMENT_AMOUNT");
    curLoan.currentInterest = (curLoan.amount * curLoan.currentInterest) / 12;
    curLoan.amount -= amount;
  }

  function getLoan(address borrower) public view returns (Loan memory) {
    return loans[borrower];
  }
}
