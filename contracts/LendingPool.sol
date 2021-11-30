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
    uint8 installmentMonths,
    address recipient,
    bytes32 requestId
  ) external;
}

contract LendingPool is Context, Ownable, ReentrancyGuard {
  struct Loan {
    uint256 amount;
    uint256 interest;
    uint256 startDate;
    uint256 paidAmount;
    uint8 installmentMonths;
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
  IERC20 assetToken;
  IScoreCalculator scoreCalculator;
  LendToken peggToken;
  uint256 public expectedInterest;
  uint256 public LIMIT_PARTICIPATION;
  uint256 public BORROWING_INTEREST_RATE;
  mapping(address => Loan) public loans;

  constructor(
    IERC20 _assetToken,
    LendToken _peggToken,
    IScoreCalculator _scoreCalculator
  ) {
    assetToken = _assetToken;
    peggToken = _peggToken;
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
    LIMIT_PARTICIPATION = amount;
  }

  function setBorrowingInterest(uint256 amount) public onlyOwner {
    BORROWING_INTEREST_RATE = amount;
  }

  function exceedsDepositLimit(uint256 amount) public view returns (bool) {
    uint256 sum = amount + poolBalance();
    return (amount * 100) / sum > LIMIT_PARTICIPATION;
  }

  function poolBalance() public view returns (uint256) {
    return assetToken.balanceOf(address(this));
  }

  function crateLoan(
    uint256 amount,
    uint256 interest,
    uint8 installmentMonths,
    address recipient,
    bytes32 requestId
  ) public {
    require(
      scoreCalculator.canApproveLoan(
        amount,
        interest,
        installmentMonths,
        recipient,
        requestId
      ),
      "CANNOT_APPROVE_LOAN"
    );
    Loan memory nxtLoan;
    nxtLoan.amount = amount;
    nxtLoan.interest = interest;
    nxtLoan.installmentMonths = installmentMonths;
    nxtLoan.recipient = recipient;
    nxtLoan.startDate = block.timestamp;
    loans[recipient] = nxtLoan;
    assetToken.transfer(recipient, amount);
  }

  function payLoan(uint256 amount, address loanRecipient) public {
    loans[loanRecipient].paidAmount += amount;
  }
}
