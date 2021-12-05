import {expect} from "chai";
import {ethers} from "hardhat";
import crypto from "crypto";

const randomAddress = () => {
  const id = crypto.randomBytes(32).toString("hex");
  const privateKey = "0x" + id;

  const wallet = new ethers.Wallet(privateKey);
  return wallet.address;
};

describe("LendingPool", function () {
  const LIMIT_DEPOSIT_PERCENTAGE = "10";

  it("Deployment should assign token and calculator contract. Should deploy lend token", async function () {
    const [owner] = await ethers.getSigners();

    const LendingPool = await ethers.getContractFactory("LendingPool");
    const AssetToken = await ethers.getContractFactory("MockToken");
    const LendToken = await ethers.getContractFactory("LendToken");

    this.token = await AssetToken.deploy();
    this.pool = await LendingPool.deploy(this.token.address);

    const assetAddress = await this.pool.assetToken();
    const lendTokenAddress = await this.pool.lendToken();

    this.lendToken = LendToken.attach(lendTokenAddress);

    expect(assetAddress).to.equal(this.token.address);
    expect(lendTokenAddress.length).to.equal(42);
  });

  it("Deposit only when amount is under maximum", async function () {
    const [owner] = await ethers.getSigners();
    const firstDeposit = "10000";
    const secondDeposit = "100000";
    await this.token.approve(this.pool.address, Number(firstDeposit) + Number(secondDeposit));

    await this.pool.deposit(firstDeposit);
    await this.pool.setLimitDeposit(LIMIT_DEPOSIT_PERCENTAGE);

    const limitDeposit = await this.pool.limitParticipation();
    const poolBalance = await this.token.balanceOf(this.pool.address);
    await expect(this.pool.deposit(secondDeposit)).to.be.revertedWith("");

    const lendTokenReceived = await this.lendToken.balanceOf(owner.address);

    expect(lendTokenReceived).to.equal(firstDeposit);
  });

  it("Withdraw should burn lendToken and give 1:1 asset token", async function () {
    const [owner] = await ethers.getSigners();
    const withdrawAmount = "100";
    const prevWithdrawAmount = await this.token.balanceOf(owner.address);
    const prevLendTokenAmount = await this.lendToken.balanceOf(owner.address);

    this.lendToken.approve(this.pool.address, withdrawAmount);
    this.pool.withdraw(withdrawAmount);

    const lendTokenAmount = await this.lendToken.balanceOf(owner.address);
    const assetTokenAmount = await this.token.balanceOf(owner.address);

    expect(Number(prevLendTokenAmount) - Number(lendTokenAmount)).to.equal(
      Number(withdrawAmount)
    );
    expect(Number(assetTokenAmount) - Number(prevWithdrawAmount)).to.equal(
      Number(withdrawAmount)
    );
  });

  it("Should register borrower info", async function () {
    const [owner] = await ethers.getSigners();

    await this.pool.registerBorrower(
      owner.address, 24, 1, 350, 4, 5, true
    );
    const borrower = await this.pool.borrowerData(owner.address);
    console.log(borrower)

  })

  it("Should create loan, fund borrower and update expected interest.", async function () {
    const [owner] = await ethers.getSigners();
    const loan = {
      amount: 1200,
      interest: 15,
      installmentNumber: 24,
      installmentAmount: 58,
      recipient: owner.address,
    };
    const balancePreLoan = await this.token.balanceOf(owner.address);
    await this.pool.createLoan(
      loan.amount,
      loan.interest,
      loan.installmentNumber,
      loan.installmentAmount,
      loan.recipient,
    );
    const balancePostLoan = await this.token.balanceOf(owner.address);
    const expectedInterest = await this.pool.expectedInterest();

    expect(Number(balancePostLoan) - Number(balancePreLoan)).to.equal(loan.amount);
    expect(Number(expectedInterest)).to.be.equal(1);
  });

  it("Should pay loan properly and update pool gains", async function () {
    const [owner] = await ethers.getSigners();
    const installmentAmount = 58;
    const installmentNumber = 24;
    const balanceBeforePay = await this.lendToken.balanceOf(owner.address);

    await this.token.approve(this.pool.address, installmentNumber * installmentAmount);
    for await (let i of new Array(installmentNumber)) {
      const loan = await this.pool.getLoan(owner.address, 0)
      if (Number(loan.amount) > 0)
        await this.pool.payLoan(installmentAmount, 0, owner.address);
    }

    const balanceAfterPay = await this.lendToken.balanceOf(owner.address);
    expect(Number(balanceAfterPay) - Number(balanceBeforePay)).to.be.within(0, 200);
    expect(Number(await this.lendToken.poolGains())).to.be.within(100, 200);
  });

  it("Should withdraw amount properly", async function () {
    const [owner] = await ethers.getSigners();
    const ownerPreAsset = await this.token.balanceOf(owner.address);

    await this.lendToken.approve(this.pool.address, '9900');
    await this.pool.withdraw('9900');

    const ownerAssetBalance = await this.token.balanceOf(owner.address);
    expect(Number(ownerAssetBalance)).to.be.greaterThan(Number(ownerPreAsset));
  });

});
