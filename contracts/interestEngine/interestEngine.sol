pragma solidity =0.5.16;
import "../PhoenixModules/modules/SafeMath.sol";
/**
 * @title FPTCoin mine pool, which manager contract is FPTCoin.
 * @dev A smart-contract which distribute some mine coins by FPTCoin balance.
 *
 */
contract interestEngine{
    using SafeMath for uint256;

        //Special decimals for calculation
    uint256 constant rayDecimals = 1e27;

    uint256 public totalAssetAmount;
        // Maximum amount of debt that can be generated with this collateral type
    uint256 public assetCeiling;       // [rad]
    // Minimum amount of debt that must be generated by a SAFE using this collateral
    uint256 public assetFloor;         // [rad]
    //interest rate
    uint256 internal interestRate;
    uint256 internal interestInterval;
    struct assetInfo{
        uint256 originAsset;
        uint256 assetAndInterest;
        uint256 interestRateOrigin;
    }
    // debt balance
    mapping(address=>assetInfo) public assetInfoMap;

        // latest time to settlement
    uint256 internal latestSettleTime;
    uint256 internal accumulatedRate;

    /**
     * @dev retrieve Interest informations.
     * @return distributed Interest rate and distributed time interval.
     */
    function getInterestInfo()public view returns(uint256,uint256){
        return (interestRate,interestInterval);
    }

    /**
     * @dev Set mineCoin mine info, only foundation owner can invoked.
     * @param _interestRate mineCoin distributed amount
     * @param _interestInterval mineCoin distributied time interval
     */
    function _setInterestInfo(uint256 _interestRate,uint256 _interestInterval)internal {
        require(_interestRate<rayDecimals,"input mine amount is too large");
        require(_interestInterval>0,"input mine Interval must larger than zero");
        _interestSettlement();
        interestRate = _interestRate;
        interestInterval = _interestInterval;
    }
    function getAssetBalance(address account)public view returns(uint256){
        if(assetInfoMap[account].interestRateOrigin == 0 || interestInterval == 0){
            return 0;
        }
        uint256 newRate = rpower(rayDecimals+interestRate,(now-latestSettleTime)/interestInterval,rayDecimals);
        newRate = accumulatedRate.mul(newRate)/rayDecimals;
        return assetInfoMap[account].assetAndInterest.mul(newRate)/assetInfoMap[account].interestRateOrigin;
    }
    /**
     * @dev mint mineCoin to account when account add collateral to collateral pool, only manager contract can modify database.
     * @param account user's account
     * @param amount the mine shared amount
     */
    function addAsset(address account,uint256 amount) internal {
        _interestSettlement();
        settleUserInterest(account);
        assetInfoMap[account].originAsset = assetInfoMap[account].originAsset.add(amount);
        assetInfoMap[account].assetAndInterest = assetInfoMap[account].assetAndInterest.add(amount);
        totalAssetAmount = totalAssetAmount.add(amount);
        require(assetInfoMap[account].assetAndInterest >= assetFloor, "Debt is below the limit");
        require(totalAssetAmount <= assetCeiling, "vault debt is overflow");
    }
    /**
     * @dev repay user's debt and taxes.
     * @param amount repay amount.
     */
    function subAsset(address account,uint256 amount)internal returns(uint256) {
        _interestSettlement();
        settleUserInterest(account);
        uint256 originBalance = assetInfoMap[account].originAsset;
        uint256 assetAndInterest = assetInfoMap[account].assetAndInterest;
        
        uint256 _subAsset;
        if(assetAndInterest == amount){
            _subAsset = originBalance;
            assetInfoMap[account].originAsset = 0;
            assetInfoMap[account].assetAndInterest = 0;
        }else if(assetAndInterest > amount){
            _subAsset = originBalance.mul(amount)/assetAndInterest;
            assetInfoMap[account].assetAndInterest = assetAndInterest.sub(amount);
            require(assetInfoMap[account].assetAndInterest >= assetFloor, "Debt is below the limit");
            assetInfoMap[account].originAsset = originBalance.sub(_subAsset);

        }else{
            require(false,"overflow asset balance");
        }
        totalAssetAmount = totalAssetAmount.sub(amount);
        return _subAsset;
    }
    function rpower(uint256 x, uint256 n, uint256 base) internal pure returns (uint256 z) {
        assembly {
            switch x case 0 {switch n case 0 {z := base} default {z := 0}}
            default {
                switch mod(n, 2) case 0 { z := base } default { z := x }
                let half := div(base, 2)  // for rounding.
                for { n := div(n, 2) } n { n := div(n,2) } {
                    let xx := mul(x, x)
                    if iszero(eq(div(xx, x), x)) { revert(0,0) }
                    let xxRound := add(xx, half)
                    if lt(xxRound, xx) { revert(0,0) }
                    x := div(xxRound, base)
                    if mod(n,2) {
                        let zx := mul(z, x)
                        if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0,0) }
                        let zxRound := add(zx, half)
                        if lt(zxRound, zx) { revert(0,0) }
                        z := div(zxRound, base)
                    }
                }
            }
        }
    }
    /**
     * @dev the auxiliary function for _mineSettlementAll.
     */    
    function _interestSettlement()internal{
        uint256 _interestInterval = interestInterval;
        if (_interestInterval>0){
            uint256 newRate = rpower(rayDecimals+interestRate,(now-latestSettleTime)/_interestInterval,rayDecimals);
            totalAssetAmount = totalAssetAmount.mul(newRate)/rayDecimals;
            accumulatedRate = accumulatedRate.mul(newRate)/rayDecimals;
            latestSettleTime = now/_interestInterval*_interestInterval;
        }else{
            latestSettleTime = now;
        }
    }

    /**
     * @dev settle user's debt balance.
     * @param account user's account
     */
    function settleUserInterest(address account)internal{
        assetInfoMap[account].assetAndInterest = _settlement(account);
        assetInfoMap[account].interestRateOrigin = accumulatedRate;
    }
    /**
     * @dev subfunction, settle user's latest tax amount.
     * @param account user's account
     */
    function _settlement(address account)internal view returns (uint256) {
        if (assetInfoMap[account].interestRateOrigin == 0){
            return 0;
        }
        return assetInfoMap[account].assetAndInterest.mul(accumulatedRate)/assetInfoMap[account].interestRateOrigin;
    }
}