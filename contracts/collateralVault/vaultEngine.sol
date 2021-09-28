// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.7.0;
import "../modules/SafeMath.sol";
import "./vaultEngineData.sol";
import "../modules/safeTransfer.sol";
/**
 * @title Tax calculate pool.
 * @dev Borrow system coin, your debt will be increased with interests every minute.
 *
 */
abstract contract vaultEngine is vaultEngineData,safeTransfer {
    using SafeMath for uint256;
    /**
     * @dev default function for foundation input miner coins.
     */
    receive()external payable{

    }
    function setInterestInfo(uint256 _interestRate,uint256 _interestInterval)external onlyOrigin{
        _setInterestInfo(_interestRate,_interestInterval);
    }
    function getCollateralLeft(address account) external view returns (uint256){
        uint256 assetAndInterest =getAssetBalance(account).mul(collateralRate);
        uint256 collateralPrice = oraclePrice(collateralToken);
        uint256 allCollateral = collateralBalances[account].mul(collateralPrice);
        if (allCollateral > assetAndInterest){
            return (allCollateral - assetAndInterest)/calDecimals;
        }
        return 0;
    }
    function canLiquidate(address account) external view returns (bool){
        uint256 assetAndInterest =getAssetBalance(account);
        uint256 collateralPrice = oraclePrice(collateralToken);
        uint256 allCollateral = collateralBalances[account].mul(collateralPrice);
        return assetAndInterest.mul(collateralRate)>allCollateral;
    }
    function checkLiquidate(address account,uint256 removeCollateral,uint256 newMint) internal view returns(bool){
        uint256 collateralPrice = oraclePrice(collateralToken);
        uint256 allCollateral = (collateralBalances[account].sub(removeCollateral)).mul(collateralPrice);
        uint256 assetAndInterest = assetInfoMap[account].assetAndInterest.add(newMint);
        return assetAndInterest.mul(collateralRate)<=allCollateral;
    }
}