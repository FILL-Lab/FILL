# FILL

### [A Filecoin Liquidity Pool for Storage Providers](https://github.com/FILL-Lab/FILL_doc)




```solidity
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
```
