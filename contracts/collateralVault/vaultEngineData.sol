// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.7.0;
import "../modules/Halt.sol";
import "../interface/IDSOracle.sol";
import "../interface/ISystemCoin.sol";
import "../interestEngine/interestEngine.sol";
import "../modules/ReentrancyGuard.sol";
abstract contract vaultEngineData is Halt,ImportOracle,ReentrancyGuard,interestEngine {
    uint256 public emergencyStart = uint(-1);
    bytes32 public vaultID;
    //Special decimals for calculation
    uint256 constant calDecimals = 1e18;

    uint256 public collateralRate;
    uint256 public liquidationReward;
    uint256 public liquidationPenalty;

    //collateral balance
    mapping(address=>uint256) public collateralBalances;
    
    address public collateralToken;
    address public reservePool;
    ISystemCoin public systemCoin;

    event MintSystemCoin(address indexed sender,address indexed account,uint256 amount);
    event RepaySystemCoin(address indexed sender,address indexed account,uint256 amount);
    event Liquidate(address indexed sender,address indexed account,address indexed collateralToken,
        uint256 debt,uint256 punishment,uint256 amount);
    event Join(address indexed sender, address indexed account, uint256 amount);
    event Exit(address indexed sender, address indexed account, uint256 amount);
    event EmergencyExit(address indexed sender, address indexed account, uint256 amount);
    event SetLiquidationInfo(address indexed sender,uint256 _liquidationReward,uint256 _liquidationPenalty);
    event SetPoolLimitation(address indexed sender,uint256 _assetCeiling,uint256 _assetFloor);
}