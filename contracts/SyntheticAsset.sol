//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SyntheticAsset is Ownable {
    using Address for address;
    IERC20 public asset;

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
}
