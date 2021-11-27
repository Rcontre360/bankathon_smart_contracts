//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Lending is Ownable {
  using Address for address;
  IERC20 public asset;

  enum UserStatus {
    Employee,
    SelfEmployee,
    Unemploy
  }
  struct User {
    bytes id;
    uint8 age;
    UserStatus status;
  }
  event Borrow(address user, uint256 amount);
  event StatusBorrowLimit(UserStatus status, uint256 amount);
  event AgeBorrowLimit(uint256 age, uint256 amount);

  mapping(UserStatus => uint256) public statusBorrowLimit;
  mapping(uint8 => uint256) public ageBorrowLimit;

  constructor(IERC20 _asset) {
    asset = _asset;
  }

  function borrow(
    uint8 age,
    UserStatus status,
    uint256 amount,
    uint256 period,
    address recipient
  ) public {
    require(
      amount < statusBorrowLimit[status] && amount < ageBorrowLimit[age],
      "DOESNT_MEET_CONDITIONS"
    );

    asset.transfer(recipient, amount);
    emit Borrow(recipient, amount);
  }

  function setStatusBorrowLimit(UserStatus status, uint256 amount)
    public
    onlyOwner
  {
    statusBorrowLimit[status] = amount;
    emit StatusBorrowLimit(status, amount);
  }

  function setAgeBorrowLimit(uint8 age, uint256 amount) public onlyOwner {
    ageBorrowLimit[age] = amount;
    emit AgeBorrowLimit(age, amount);
  }
}
