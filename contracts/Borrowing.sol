//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Borrowing is Ownable {
  using Address for address;
  IERC20 public asset;

  enum BorrowingStatus {
    Waiting,
    Successfull,
    Failed
  }
  enum LaboralStatus {
    Employee,
    SelfEmployee,
    Unemploy
  }
  struct Borrower {
    bytes id;
    uint8 age;
    uint256 income;
    uint8 professionalEvaluation;
    uint8 transactionHistory;
    LaboralStatus status;
  }

  event Borrow(address user, uint256 amount);
  event StatusBorrowLimit(LaboralStatus status, uint256 amount);
  event AgeBorrowLimit(uint256 age, uint256 amount);

  mapping(LaboralStatus => uint256) public statusBorrowLimit;
  mapping(uint8 => uint256) public ageBorrowLimit;

  constructor(IERC20 _asset) {
    asset = _asset;
  }

  function hasActionLoan() public {}

  function newLoan() public {}

  function acceptProposal() public {}

  function getLoanDetails(uint256 loanId) public {}

  function getLoanState(uint256 loanId) public {}

  function lockLoan(uint256 loanId) public {}

  function getRepayValue() public {}

  function repayLoan(uint256 loanId, uint256 amount) public {}
}
