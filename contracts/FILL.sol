// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Utils/Context.sol";
import "./FLE.sol";
import "@zondax/filecoin-solidity/contracts/v0.8/MinerAPI.sol";
import "@zondax/filecoin-solidity/contracts/v0.8/types/MinerTypes.sol";
import "@zondax/filecoin-solidity/contracts/v0.8/cbor/BytesCbor.sol";
import "@zondax/filecoin-solidity/contracts/v0.8/SendAPI.sol";

interface FILLInterface {
    struct BorrowInfo {
        // uint256 id;
        address account; //birriw account
        uint256 amount; //borrow amount
        bytes minerAddr; //miner
        uint256 interestRate; // interest rate
        uint256 timestamp;
        bool isPayback;
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
    /// @param minerAddr miner address
    /// @param amountFIL the amount of FIL user would like to borrow
    /// @param interestRate approximated interest rate at the point of request
    /// @param slippageTolr slippage tolerance
    /// @return amount actual FIL borrowed
    function borrow(
        bytes memory minerAddr,
        uint256 amountFIL,
        uint256 interestRate,
        uint256 slippageTolr
    ) external returns (uint256 amount);

    /// @dev payback principal and interest
    /// @param minerAddr miner address
    /// @param amountFIL the amount of FIL user would like to repay
    /// @return amount actual FIL repaid
    function payback(bytes memory minerAddr, uint256 amountFIL)
        external
        returns (uint256 amount);

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
        returns (BorrowInfo[] memory infos);

    /// @dev FLE token address
    function fleAddress() external view returns (address);

    /// @dev return FIL/FLE exchange rate: total amount of FIL liquidity divided by total amount of FLE outstanding
    function exchangeRate() external view returns (uint256);

    /// @dev return transaction fee rate
    function feeRate() external view returns (uint256);

    /// @dev return borrowing interest rate : a mathematical function of utilizatonRate
    function interestRate() external view returns (uint256);

    /// @dev return liquidity pool utilization : the amount of FIL being utilized divided by the total liquidity provided (the amount of FIL deposited and the interest repaid)
    function utilizationRate() external view returns (uint256);

    /// @dev Emitted when `account` deposits `amountFIL` and mints `amountFLE`
    event Deposit(
        address indexed account,
        uint256 amountFIL,
        uint256 amountFLE
    );
    /// @dev Emitted when `account` redeems `amountFLE` and withdraws `amountFIL`
    event Redeem(address indexed account, uint256 amountFLE, uint256 amountFIL);
    /// @dev Emitted when user `account` borrows `amountFIL` with `minerId`
    event Borrow(address account, bytes indexed minerId, uint256 amountFIL);
    /// @dev Emitted when user `account` repays `amount` FIL with `minerId`
    event Payback(address account, bytes indexed minerId, uint256 amountFIL);
}

contract FILL is Context, FILLInterface {
    using BytesCBOR for bytes;

    // struct FILLInfo {
    //     uint256 availableFIL; // Available FIL Liquidity
    //     uint256 totalDeposited; // total Deposited Liquidity
    // }

    // miner stack
    struct MinerStackInfo {
        bytes minerAddr;
        BigInt quota;
        uint64 expiration;
    }

    mapping(bytes => address) accountBinds;
    mapping(bytes => FILLInterface.BorrowInfo) public borrows;
    mapping(uint256 => bytes) miners;
    uint256 _minerCount;

    address private _owner;
    uint256 private _cumulativeDepositFil;
    uint256 private _cumulativeRedeemFil;
    uint256 private _cumulativeBorrowFil;
    uint256 private _cumulativePaybackFil;
    uint256 private _cumulativePaybackFilInterest;

    uint256 constant DEFAULT_RATE_BASE = 1000000;
    uint256 _feeRate; // fee=_feeRate/DEFAULT_RATE_BASE
    uint256 _exchangeRate; // FIL/FLE=_exchangeRate/DEFAULT_RATE_BASE
    uint256 _interestRate; // interestRate=_interestRate/DEFAULT_RATE_BASE
    uint256 _utilizationRate; //

    FLE _tokenFLE;

    constructor(address fleAddr) {
        _tokenFLE = FLE(fleAddr);
        _owner = _msgSender();
        _feeRate = 1000;
        _exchangeRate = DEFAULT_RATE_BASE;
        _interestRate = 43400;
    }

    function deposit(
        uint256 amountFIL,
        uint256 exchRate,
        uint256 slippage
    ) external payable checkExchangeRate(exchRate, slippage) returns (uint256) {
        require(msg.value == amountFIL, "amountFIL does not match msg.value");
        uint256 amountFLE = (amountFIL * DEFAULT_RATE_BASE) / _exchangeRate;
        _tokenFLE.mint(_msgSender(), amountFLE);

        emit Deposit(_msgSender(), amountFIL, amountFLE);
        _cumulativeDepositFil += amountFIL;

        return _tokenFLE.balanceOf(_msgSender());
    }

    function redeem(
        uint256 amountFLE,
        uint256 exchRate,
        uint256 slippage
    ) external checkExchangeRate(exchRate, slippage) returns (uint256) {
        _tokenFLE.burn(_msgSender(), amountFLE);

        uint256 amountFIL = (amountFLE * _exchangeRate) / DEFAULT_RATE_BASE;
        payable(_msgSender()).transfer(amountFIL);

        emit Redeem(_msgSender(), amountFLE, amountFIL);
        _cumulativeRedeemFil += amountFIL;
        return _tokenFLE.balanceOf(_msgSender());
    }

    function redeemAll() external {
        // todo : not ready ...
    }

    function borrow(
        bytes memory minerAddr,
        uint256 amount,
        uint256 interest_rate,
        uint256 slippage
    )
        external
        noArrears(minerAddr)
        checkinterestRate(interest_rate, slippage)
        returns (uint256)
    {
        require(amount > 0, "need amount > 0");
        // get propose for change beneficiary
        MinerTypes.GetBeneficiaryReturn memory beneficiaryRet = MinerAPI
            .getBeneficiary(minerAddr);

        MinerTypes.ChangeBeneficiaryParams memory changeParams = MinerTypes
            .ChangeBeneficiaryParams({
                new_beneficiary: beneficiaryRet.proposed.new_beneficiary,
                new_quota: beneficiaryRet.proposed.new_quota,
                new_expiration: beneficiaryRet.proposed.new_expiration
            });
        // todo : add new_expiration check

        // todo : add new_quota check

        // change beneficiary to contract
        MinerAPI.changeBeneficiary(minerAddr, changeParams);

        addBorrowInfo(minerAddr, _msgSender(), amount, interest_rate);
        // send fil to miner
        SendAPI.send(minerAddr, amount);

        _cumulativeBorrowFil += amount;

        emit Borrow(_msgSender(), minerAddr, amount);
        return borrows[minerAddr].amount;
    }

    function payback(bytes memory minerAddress, uint256 amount)
        public
        haveArrears(minerAddress)
        returns (uint256)
    {
        FILLInterface.BorrowInfo memory _borrow = borrows[minerAddress];
        require(
            amount == _borrow.amount,
            "input amount not equal borrow amount"
        );
        // calc interest
        uint256 borrowingPeriod = 0;
        uint256 interest = (amount * borrowingPeriod) / _interestRate;
        uint256 paybackAmount = amount + interest;

        // withdraw amount
        // MinerTypes.WithdrawBalanceReturn memory withdrawRet =
        MinerAPI.withdrawBalance(
            minerAddress,
            MinerTypes.WithdrawBalanceParams({
                amount_requested: abi.encodePacked(bytes32(paybackAmount))
            })
        );

        // change Beneficiary to owner
        MinerTypes.GetOwnerReturn memory minerInfo = MinerAPI.getOwner(
            minerAddress
        );
        MinerTypes.ChangeBeneficiaryParams memory changeParams = MinerTypes
            .ChangeBeneficiaryParams({
                new_beneficiary: minerInfo.owner,
                new_quota: abi.encodePacked(bytes32(0)).deserializeBigInt(),
                new_expiration: 0
            });
        MinerAPI.changeBeneficiary(minerAddress, changeParams);

        delete borrows[minerAddress];
        emit Payback(_msgSender(), minerAddress, paybackAmount);

        return paybackAmount;
    }

    function bindMiner(
        bytes memory minerAddr,
        string memory _message,
        bytes memory signature
    ) public returns (bool) {
        // todo : not ready
    }

    function ubindMine(
        bytes memory minerAddr,
        string memory _message,
        bytes memory signature
    ) public returns (bool) {
        // todo : not ready
    }

    function staskMiner() public returns (MinerStackInfo memory) {
        // todo : not ready
    }

    function unstaskMiner() public returns (MinerStackInfo memory) {
        // todo : not ready
    }

    function fleBalanceOf(address account) external view returns (uint256) {
        return _tokenFLE.balanceOf(account);
    }

    function minerBorrow(bytes memory minerAddr)
        public
        view
        returns (BorrowInfo memory)
    {
        return borrows[minerAddr];
    }

    function userBorrows(address account)
        public
        view
        returns (FILLInterface.BorrowInfo[] memory)
    {
        // todo : add code here
    }

    function allBorrows() public view returns (BorrowInfo[] memory) {
        BorrowInfo[] memory ret = new BorrowInfo[](_minerCount);
        uint256 j = 0;
        for (uint256 i = 0; i < _minerCount; i++) {
            ret[j] = borrows[miners[i]];
        }
        return ret;
    }

    function depositsBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function fleAddress() public view returns (address) {
        return address(_tokenFLE);
    }

    function exchangeRate() public view returns (uint256) {
        return _exchangeRate;
    }

    function setExchangeRate(uint64 newRate)
        public
        onlyOwner
        returns (uint256)
    {
        _exchangeRate = newRate;
        return _exchangeRate;
    }

    function feeRate() public view returns (uint256) {
        return _feeRate;
    }

    function setFeeRate(uint64 newRate) public onlyOwner returns (uint256) {
        _feeRate = newRate;
        return _feeRate;
    }

    function utilizationRate() public view returns (uint256) {
        return _utilizationRate;
    }

    function interestRate() public view returns (uint256) {
        return _interestRate;
    }

    function setInterestRate(uint64 newRate)
        public
        onlyOwner
        returns (uint256)
    {
        _interestRate = newRate;
        return _interestRate;
    }

    function addBorrowInfo(
        bytes memory minerAddr,
        address account,
        uint256 amount,
        uint256 interest_rate
    ) internal {
        // if (borrows[minerAddr].amount == 0) {
        //     miners[minerCount] = minerAddr;
        //     minerCount++;
        // }
        miners[_minerCount] = minerAddr;
        _minerCount++;
        borrows[minerAddr] = BorrowInfo({
            account: account,
            amount: amount,
            minerAddr: minerAddr,
            interestRate: interest_rate,
            timestamp: block.timestamp,
            isPayback: false
        });
    }

    //
    modifier onlyOwner() {
        require(msg.sender == _owner, "caller is not the owner");
        _;
    }
    modifier noArrears(bytes memory _addr) {
        require(borrows[_addr].amount == 0, "need to payback first");
        _;
    }
    modifier haveArrears(bytes memory _addr) {
        require(borrows[_addr].amount > 0, "no need to payback");
        _;
    }
    modifier checkExchangeRate(uint256 exchRate, uint256 slippage) {
        // todo : add exchangeRate check here
        _;
    }
    modifier checkinterestRate(uint256 interest_rate, uint256 slippage) {
        // todo : add exchangeRate check here
        _;
    }
}
