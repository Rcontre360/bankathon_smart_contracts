//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SyntheticAsset is Context, Ownable, IERC20 {
    mapping (address => uint256) private _balances;
    IERC20 public asset;
    uint256 private _totalSupply;
    string private AssetName;
    string private _symbol;

    enum TradingStatus {
        Trading,
        Halted
    }

    enum AssetType {
        Commodity,
        Security,
        Currency
    }

    struct SyntheticAsset {
        uint256 price;
        uint256 smaPrice;
        bytes assetName;
        AssetType assetType;
        TradingStatus status;
    }

    event Purchase(address to, uint256 amount);
    event collateralBuyLimit(AssetType assetType, uint256 price, uint256 amount);
    event tradingHalted(TradingStatus status);

    constructor (IERC20 _asset) {
        asset = _asset;
    }

    function getName() public view returns (string memory) {
        return _name;
    }

    function getSymbol() public view returns(string memory) {
        return _symbol;
    }

    function getDecimals() public view returns(uint8) {
        return 18;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function getBalance(address user) public view override returns (uint256) {
        return _balances[user];
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }


    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to zero asset");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }


}
