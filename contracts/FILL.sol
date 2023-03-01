// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@zondax/filecoin-solidity/contracts/v0.8/MinerAPI.sol";
import "@zondax/filecoin-solidity/contracts/v0.8/types/MinerTypes.sol";
import "@zondax/filecoin-solidity/contracts/v0.8/cbor/BigIntCbor.sol";
import "@zondax/filecoin-solidity/contracts/v0.8/types/CommonTypes.sol";
import "@zondax/filecoin-solidity/contracts/v0.8/SendAPI.sol";

import "./Utils/Context.sol";
import "./Utils/Validation.sol";
import "./Utils/Convertion.sol";
import "./FLE.sol";

interface FILLInterface {
    struct BorrowInfo {
        uint256 id; // borrow id
        address account; //borrow account
        uint256 amount; //borrow amount
        uint64 minerId; //miner
        uint256 interestRate; // interest rate
        uint256 borrowTime; // borrow time
        uint256 paybackTime; // payback time
        bool isPayback; // flag for status
    }
    struct MinerBorrowInfo {
        uint64 minerId;
        BorrowInfo[] borrows;
    }
    struct MinerStakingInfo {
        uint64 minerId;
        uint256 quota;
        uint256 borrowCount;
        uint256 paybackCount;
        uint64 expiration;
    }
    struct FILLInfo {
        uint256 availableFIL; // a.	Available FIL Liquidity a=b+d-c
        uint256 totalDeposited; // b.	Total Deposited Liquidity
        uint256 utilizedLiquidity; // c.	Current Utilized Liquidity c=b+d-a
        uint256 accumulatedInterest; // d.	Accumulated Interest Payment Received
        uint256 accumulatedPayback; // e.	Accumulated Repayments
        uint256 accumulatedRedeem; // f.	Accumulated FIL Redemptions
        uint256 accumulatedBurnFLE; // g.	Accumulated FLE Burnt
        uint256 utilizationRate; // h.	Current Utilization Rate  h=c/(b+d-e)
        uint256 exchangeRate; // i.	Current FLE/FIL Exchange Rate
        uint256 interestRate; // j.	Current Interest Rate
        uint256 collateralizationRate; // k. Current Collateralization Rate
        uint256 totalFee; // l.	Total Transaction Fee Received
        uint256 leastDepositingAmount; // m. Least Depositing Amount 
    }

    /// @dev deposit FIL to the contract, mint FLE
    /// @param amountFIL  the amount of FIL user would like to deposit
    /// @param exchangeRate approximated exchange rate at the point of request
    /// @param slippageTolr slippage tolerance
    /// @return amount actual FLE minted
    function deposit(
        uint256 amountFIL,
        uint256 exchangeRate,
        uint256 slippageTolr
    ) external payable returns (uint256 amount);

    /// @dev redeem FLE to the contract, withdraw FIL
    /// @param amountFLE the amount of FLE user would like to redeem
    /// @param exchangeRate approximated exchange rate at the point of request
    /// @param slippageTolr slippage tolerance
    /// @return amount actual FIL withdrawal
    function redeem(
        uint256 amountFLE,
        uint256 exchangeRate,
        uint256 slippageTolr
    ) external returns (uint256 amount);

    /// @dev borrow FIL from the contract
    /// @param minerId miner id
    /// @param amountFIL the amount of FIL user would like to borrow
    /// @param interestRate approximated interest rate at the point of request
    /// @param slippageTolr slippage tolerance
    /// @return amount actual FIL borrowed
    function borrow(
        uint64 minerId,
        uint256 amountFIL,
        uint256 interestRate,
        uint256 slippageTolr
    ) external returns (uint256 amount);

    /// @dev payback principal and interest
    /// @param minerId miner id
    /// @param borrowId borrow id
    /// @return amount actual FIL repaid
    function payback(uint64 minerId, uint256 borrowId)
        external
        returns (uint256 amount);

    /// @dev staking miner : change beneficiary to contract , need owner for miner propose change beneficiary first
    /// @param minerId miner id
    /// @return flag result flag for change beneficiary
    function stakingMiner(uint64 minerId) external returns (bool);

    /// @dev unstaking miner : change beneficiary back to miner owner, need payback all first
    /// @param minerId miner id
    /// @return flag result flag for change beneficiary
    function unstakingMiner(uint64 minerId) external returns (bool);

    /// @dev FLE balance of a user
    /// @param account user account
    /// @return balance user’s FLE account balance
    function fleBalanceOf(address account)
        external
        view
        returns (uint256 balance);

    /// @dev user’s borrowing information
    /// @param account user’s account address
    /// @return infos user’s borrowing informations
    function userBorrows(address account)
        external
        view
        returns (MinerBorrowInfo[] memory infos);

    /// @dev get staking miner info : minerId,quota,borrowCount,paybackCount,expiration
    /// @param minerId miner id
    /// @return info return staking miner info
    function getStakingMinerInfo(uint64 minerId)
        external
        view
        returns (MinerStakingInfo memory);

    /// @dev FLE token address
    function fleAddress() external view returns (address);

    /// @dev Validation contract address
    function validationAddress() external view returns (address);

    /// @dev return FIL/FLE exchange rate: total amount of FIL liquidity divided by total amount of FLE outstanding
    function exchangeRate() external view returns (uint256);

    /// @dev return transaction fee rate
    function feeRate() external view returns (uint256);

    /// @dev return borrowing interest rate : a mathematical function of utilizatonRate
    function interestRate() external view returns (uint256);

    /// @dev return liquidity pool utilization : the amount of FIL being utilized divided by the total liquidity provided (the amount of FIL deposited and the interest repaid)
    function utilizationRate() external view returns (uint256);

    /// @dev return fill contract infos
    function fillInfo() external view returns (FILLInfo memory);

    /// @dev Emitted when `account` deposits `amountFIL` and mints `amountFLE`
    event Deposit(
        address indexed account,
        uint256 amountFIL,
        uint256 amountFLE
    );
    /// @dev Emitted when `account` redeems `amountFLE` and withdraws `amountFIL`
    event Redeem(address indexed account, uint256 amountFLE, uint256 amountFIL);
    /// @dev Emitted when user `account` borrows `amountFIL` with `minerId`
    event Borrow(
        uint256 indexed borrowId,
        address indexed account,
        uint64 indexed minerId,
        uint256 amountFIL
    );
    /// @dev Emitted when user `account` repays `amount` FIL with `minerId`
    event Payback(
        uint256 indexed borrowId,
        address indexed account,
        uint64 indexed minerId,
        uint256 amountFIL
    );

    // / @dev Emitted when staking `minerId` : change beneficiary to `beneficiary` with info `quota`,`expiration`
    event StakingMiner(
        uint64 minerId,
        bytes beneficiary,
        uint256 quota,
        uint64 expiration
    );
    // / @dev Emitted when unstaking `minerId` : change beneficiary to `beneficiary` with info `quota`,`expiration`
    event UnstakingMiner(
        uint64 minerId,
        bytes beneficiary,
        uint256 quota,
        uint64 expiration
    );
}

contract FILL is Context, FILLInterface {
    using Convertion for *;

    uint64[] public allMiners;
    mapping(uint64 => BorrowInfo[]) public minerBorrows;
    mapping(address => uint64[]) private userMinerPairs;
    mapping(uint64 => address) private minerBindsMap;
    mapping(uint64 => MinerStakingInfo) private minerStaking;

    address private _owner;
    uint256 private _accumulatedDepositFIL;
    uint256 private _accumulatedRedeemFIL;
    uint256 private _accumulatedBorrowFIL;
    uint256 private _accumulatedPaybackFIL;
    uint256 private _accumulatedInterestFIL;
    uint256 private _totalFee;

    uint256 constant DEFAULT_RATE_BASE = 1000000;
    uint256 constant DEFAULT_COLLATERALIZATION_RATE = 1500000;
    uint256 constant DEFAULT_FEE_RATE = 5000;
    uint256 constant DEFAULT_LEAST_DEPOSIT = 10 ** 18;

    uint256 private _feeRate; // fee=_feeRate/DEFAULT_RATE_BASE
    uint256 private _exchangeRate; // FIL/FLE=_exchangeRate/DEFAULT_RATE_BASE
    uint256 private _interestRate; // interestRate=_interestRate/DEFAULT_RATE_BASE
    uint256 private _utilizationRate; //
    uint256 private _collateralizationRate; // collateralizationRate=_collateralizationRate/DEFAULT_RATE_BASE
    uint256 private _leastDepositingAmount; // Least deposit amount acceptable

    FLE _tokenFLE;
    Validation _validation;

    constructor(address fleAddr, address validationAddr) {
        _tokenFLE = FLE(fleAddr);
        _validation = Validation(validationAddr);
        _owner = _msgSender();
        _feeRate = DEFAULT_FEE_RATE;
        _exchangeRate = DEFAULT_RATE_BASE;
        _interestRate = 43400;
        _collateralizationRate = DEFAULT_COLLATERALIZATION_RATE;
        _leastDepositingAmount = DEFAULT_LEAST_DEPOSIT;
    }

    function deposit(
        uint256 amountFIL,
        uint256 exchRate,
        uint256 slippage
    ) external payable returns (uint256) {
        checkExchangeRate(exchRate, slippage);
        require(msg.value == amountFIL, "depositing value not match");
        require(msg.value >= _leastDepositingAmount, "depositing value too small");
        uint256 amountFLE = (amountFIL * DEFAULT_RATE_BASE) / _exchangeRate;
        _tokenFLE.mint(_msgSender(), amountFLE);

        _accumulatedDepositFIL += amountFIL;
        emit Deposit(_msgSender(), amountFIL, amountFLE);

        return amountFLE;
    }

    function redeem(
        uint256 amountFLE,
        uint256 exchRate,
        uint256 slippage
    ) external returns (uint256) {
        checkExchangeRate(exchRate, slippage);
        _tokenFLE.burn(_msgSender(), amountFLE);
        uint256 amountFIL = (amountFLE * _exchangeRate) / DEFAULT_RATE_BASE;
        payable(_msgSender()).transfer(amountFIL);
        _accumulatedRedeemFIL += amountFIL;

        emit Redeem(_msgSender(), amountFLE, amountFIL);
        return amountFIL;
    }

    function borrow(
        uint64 minerId,
        uint256 amount,
        uint256 interest_rate,
        uint256 slippage
    ) external returns (uint256) {
        haveStaking(minerId);
        isBindMiner(_msgSender(), minerId);
        checkInterestRate(interest_rate, slippage);
        //todo: add check upon pledgable amount rather than quota
        require(
            (amount + minerStaking[minerId].borrowCount) <
                minerStaking[minerId].quota * _collateralizationRate / DEFAULT_RATE_BASE,
            "not enough to borrow"
        );
        // add a borrow
        BorrowInfo[] storage borrows = minerBorrows[minerId];
        borrows.push(
            BorrowInfo({
                id: borrows.length,
                account: _msgSender(),
                amount: amount,
                minerId: minerId,
                interestRate: interest_rate,
                borrowTime: block.timestamp,
                paybackTime: 0,
                isPayback: false
            })
        );
        minerStaking[minerId].borrowCount += amount;
        _accumulatedBorrowFIL += amount;
        // send fil to miner
        SendAPI.send(CommonTypes.FilActorId.wrap(minerId), amount);

        emit Borrow(borrows.length - 1, _msgSender(), minerId, amount);
        return amount;
    }

    function payback(uint64 minerId, uint256 borrowId)
        external
        returns (uint256)
    {
        require(minerId != 0, "invalid miner id");
        BorrowInfo storage info = minerBorrows[minerId][borrowId];
        require(
            info.minerId == minerId,
            "invalid borrowId"
        );
        require(info.isPayback == false, "no need payback");
        // calc interest
        uint256 borrowingPeriod = 0; // todo : 0 only for dev
        uint256 interest = (info.amount * borrowingPeriod) /
            _interestRate;
        uint256 paybackAmount = info.amount + interest;

        // pay back use miner withdraw
        MinerAPI.withdrawBalance(
            CommonTypes.FilActorId.wrap(minerId),
            paybackAmount.uint2BigInt()
        );
        _accumulatedPaybackFIL += info.amount;
        _accumulatedInterestFIL += interest;

        minerStaking[minerId].paybackCount += info.amount;

        info.paybackTime = block.timestamp;
        info.isPayback = true;

        emit Payback(borrowId, _msgSender(), minerId, paybackAmount);

        return paybackAmount;
    }

    function bindMiner(
        uint64 minerId,
        bytes memory signature
    ) external returns (bool) {
        if (minerBindsMap[minerId] == address(0)) {
            address sender = _msgSender();
            _validation.validateOwner(minerId, signature, sender);
            minerBindsMap[minerId] = sender;
            userMinerPairs[sender].push(minerId);
            allMiners.push(minerId);
            return true;
        } else {
            return false;
        }
    }

    function unbindMiner(uint64 minerId) external returns (bool) {
        address sender = _msgSender();
        isBindMiner(sender, minerId);
        delete minerBindsMap[minerId];
        uint64[] storage miners = userMinerPairs[sender];
        for (uint256 i = 0; i < miners.length; i++) {
            if (miners[i] == minerId) {
                if (i != miners.length - 1) {
                    miners[i] = miners[miners.length - 1];
                }
                miners.pop();
                break;
            }
        }
        for (uint256 i = 0; i < allMiners.length; i++) {
            if (allMiners[i] == minerId) {
                if (i != allMiners.length - 1) {
                    allMiners[i] = allMiners[allMiners.length - 1];
                }
                allMiners.pop();
                break;
            }
        }
        return true;
    }

    function stakingMiner(uint64 minerId) external returns (bool) {
        noStaking(minerId);
        isBindMiner(_msgSender(), minerId);
        // get propose for change beneficiary
        CommonTypes.FilActorId wrappedId = CommonTypes.FilActorId.wrap(minerId);
        MinerTypes.PendingBeneficiaryChange memory proposedBeneficiaryRet = MinerAPI
            .getBeneficiary(wrappedId).proposed;

        // todo : check new_beneficiary

        // new_quota check
        uint256 quota = uint256(
            bytes32(
                BigIntCBOR.serializeBigInt(proposedBeneficiaryRet.new_quota)
            )
        );
        require(quota > 0, "need quota > 0");
        require(
            proposedBeneficiaryRet.new_expiration > block.number,
            "expiration invalid"
        );

        // change beneficiary to contract
        MinerAPI.changeBeneficiary(
            wrappedId,
            MinerTypes.ChangeBeneficiaryParams({
                new_beneficiary: proposedBeneficiaryRet.new_beneficiary,
                new_quota: proposedBeneficiaryRet.new_quota,
                new_expiration: proposedBeneficiaryRet.new_expiration
            })
        );

        //  todo : check beneficiary again ?

        // add minerStaking
        minerStaking[minerId] = MinerStakingInfo({
            minerId: minerId,
            quota: quota,
            borrowCount: 0,
            paybackCount: 0,
            expiration: proposedBeneficiaryRet.new_expiration
        });

        emit StakingMiner(
            minerId,
            proposedBeneficiaryRet.new_beneficiary.data,
            quota,
            proposedBeneficiaryRet.new_expiration
        );
        return true;
    }

    function unstakingMiner(uint64 minerId) external returns (bool) {
        haveStaking(minerId);
        isBindMiner(_msgSender(), minerId);
        require(
            minerStaking[minerId].borrowCount ==
                minerStaking[minerId].paybackCount,
            "payback first"
        );

        // change Beneficiary to owner
        CommonTypes.FilActorId wrappedId = CommonTypes.FilActorId.wrap(minerId);
        CommonTypes.FilAddress memory owner = MinerAPI.getOwner(
            wrappedId
        ).owner;
        CommonTypes.FilAddress memory beneficiary = MinerAPI
            .getBeneficiary(wrappedId).active.beneficiary;
        if (
            uint256(bytes32(beneficiary.data)) !=
            uint256(bytes32(owner.data))
        ) {
            MinerAPI.changeBeneficiary(
                wrappedId,
                MinerTypes.ChangeBeneficiaryParams({
                    new_beneficiary: owner,
                    new_quota: CommonTypes.BigInt(hex"00", false),
                    new_expiration: 0
                })
            );
        }

        delete minerStaking[minerId];
        emit UnstakingMiner(minerId, owner.data, 0, 0);

        return true;
    }

    function fleBalanceOf(address account) external view returns (uint256) {
        return _tokenFLE.balanceOf(account);
    }

    function userBorrows(address account)
        external
        view
        returns (MinerBorrowInfo[] memory) 
    {
        MinerBorrowInfo[] memory result = new MinerBorrowInfo[](userMinerPairs[account].length);
        for (uint256 i = 0; i < result.length; i++) {
            uint64 minerId = userMinerPairs[account][i];
            result[i].minerId = minerId;
            result[i].borrows = minerBorrows[minerId];
        }
        return result;
    }

    function getStakingMinerInfo(uint64 minerId)
        external
        view
        returns (MinerStakingInfo memory)
    {
        return minerStaking[minerId];
    }

    function fillInfo() external view returns (FILLInfo memory) {
        return
            FILLInfo({
                availableFIL: (_accumulatedDepositFIL +
                    _accumulatedInterestFIL -
                    (_accumulatedBorrowFIL - _accumulatedPaybackFIL)),
                totalDeposited: _accumulatedDepositFIL,
                utilizedLiquidity: (_accumulatedBorrowFIL -
                    _accumulatedPaybackFIL),
                accumulatedInterest: _accumulatedInterestFIL,
                accumulatedPayback: _accumulatedPaybackFIL,
                accumulatedRedeem: _accumulatedRedeemFIL,
                accumulatedBurnFLE: _accumulatedRedeemFIL,
                utilizationRate: _utilizationRate,
                exchangeRate: _exchangeRate,
                interestRate: _interestRate,
                collateralizationRate: _collateralizationRate,
                totalFee: _totalFee,
                leastDepositingAmount: _leastDepositingAmount
            });
    }

    function fleAddress() external view returns (address) {
        return address(_tokenFLE);
    }

    function validationAddress() external view returns (address) {
        return address(_validation);
    }

    function exchangeRate() external view returns (uint256) {
        return _exchangeRate;
    }

    // todo : remove it later
    function setExchangeRate(uint64 newRate)
        public
        onlyOwner
        returns (uint256)
    {
        _exchangeRate = newRate;
        return _exchangeRate;
    }

    function leastDepositingAmount() external view returns (uint256) {
        return _leastDepositingAmount;
    }

    function setleastDepositingAmount(uint64 newRate) external onlyOwner returns (uint256) {
        _leastDepositingAmount = newRate;
        return _leastDepositingAmount;
    }

    function collateralizationRate() external view returns (uint256) {
        return _collateralizationRate;
    }

    function setCollateralizationRate(uint64 newRate) external onlyOwner returns (uint256) {
        _collateralizationRate = newRate;
        return _collateralizationRate;
    }

    function feeRate() external view returns (uint256) {
        return _feeRate;
    }

    function setFeeRate(uint64 newRate) external onlyOwner returns (uint256) {
        _feeRate = newRate;
        return _feeRate;
    }

    function utilizationRate() external view returns (uint256) {
        return _utilizationRate;
    }

    function interestRate() external view returns (uint256) {
        return _interestRate;
    }

    function setInterestRate(uint64 newRate)
        external
        onlyOwner
        returns (uint256)
    {
        _interestRate = newRate;
        return _interestRate;
    }

    function userMiners(address account) external view returns (uint64[] memory) {
        return userMinerPairs[account];
    }

    // ------------------ function only for dev ------------------begin
    function send(address account, uint256 amount) external onlyOwner {
        payable(account).transfer(amount);
    }

    function devManage(
        uint256 code,
        uint64 minerId,
        uint256 amount
    ) external onlyOwner {
        CommonTypes.FilActorId wrappedId = CommonTypes.FilActorId.wrap(minerId);
        if (code == 1) {
            // confirmBeneficiary
            MinerTypes.GetBeneficiaryReturn memory beneficiaryRet = MinerAPI
                .getBeneficiary(wrappedId);
            MinerAPI.changeBeneficiary(
                wrappedId,
                MinerTypes.ChangeBeneficiaryParams({
                    new_beneficiary: beneficiaryRet.proposed.new_beneficiary,
                    new_quota: beneficiaryRet.proposed.new_quota,
                    new_expiration: beneficiaryRet.proposed.new_expiration
                })
            );
        } else if (code == 2) {
            MinerAPI.withdrawBalance(
                wrappedId,
                amount.uint2BigInt()
            );
        } else if (code == 3) {
            // change Beneficiary to owner
            MinerTypes.GetOwnerReturn memory minerInfo = MinerAPI.getOwner(
                wrappedId
            );
            MinerAPI.changeBeneficiary(
                wrappedId,
                MinerTypes.ChangeBeneficiaryParams({
                    new_beneficiary: minerInfo.owner,
                    new_quota: CommonTypes.BigInt(hex"00", false),
                    new_expiration: 0
                })
            );
        }
    }

    // ------------------ function only for dev ------------------end
    //
    modifier onlyOwner() {
        require(msg.sender == _owner, "unauthorized");
        _;
    }

    function noStaking(uint64 _id) private view {
        require(minerStaking[_id].quota == 0, "unstaking first");
    }

    function haveStaking(uint64 _id) private view {
        require(minerStaking[_id].quota > 0, "staking first");
    }

    function checkExchangeRate(uint256 exchRate, uint256 slippage)
        private
        view
    {
        // require(
        //     (exchRate - slippage) <= _exchangeRate &&
        //         _exchangeRate <= (exchRate + slippage),
        //     "check exchange rate failed"
        // );
    }

    function checkInterestRate(uint256 interest_rate, uint256 slippage)
        private
        view
    {
        // require(
        //     (interest_rate - slippage) <= _interestRate &&
        //         _interestRate <= (interest_rate + slippage),
        //     "check interest rate failed"
        // );
    }

    function isBindMiner(address account, uint64 minerId) private view {
        require(account != address(0), "invalid account");
        require(minerId != 0, "invalid minerId");
        require(minerBindsMap[minerId] == account, "not bind");
    }
}
