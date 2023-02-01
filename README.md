# FILL

### [A Filecoin Liquidity Pool for Storage Providers](https://github.com/FILL-Lab/FILL_doc)




```solidity
    struct BorrowInfo {
        uint256 id; // borrow id
        address account; //borrow account
        uint256 amount; //borrow amount
        bytes minerAddr; //miner
        uint256 interestRate; // interest rate
        uint256 borrowTime;
        uint256 paybackTime;
        bool isPayback;
    }
    struct MinerStackInfo {
        bytes minerAddr;
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
        uint256 totalFee; // k.	Total Transaction Fee Received
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
    /// @param borrowId borrow id
    /// @return amount actual FIL repaid
    function payback(bytes memory minerAddr, uint256 borrowId)
        external
        returns (uint256 amount);

    /// @dev stacking miner : change beneficiary to contract , need owner for miner propose change beneficiary first
    /// @param minerAddr miner address
    /// @return flag result flag for change beneficiary
    function stackingMiner(bytes memory minerAddr) external returns (bool);

    /// @dev unstacking miner : change beneficiary back to miner owner, need payback all first
    /// @param minerAddr miner address
    /// @return flag result flag for change beneficiary
    function unstackingMiner(bytes memory minerAddr) external returns (bool);

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
        uint256 indexed id,
        address indexed account,
        bytes indexed minerAddr,
        uint256 amountFIL
    );
    /// @dev Emitted when user `account` repays `amount` FIL with `minerId`
    event Payback(
        uint256 indexed id,
        address indexed account,
        bytes indexed minerAddr,
        uint256 amountFIL
    );

    // / @dev Emitted when stacking `minerAddr` : change beneficiary to `beneficiary` with info `quota`,`expiration`
    event StackingMiner(
        bytes minerAddr,
        bytes beneficiary,
        uint256 quota,
        uint64 expiration
    );
    // / @dev Emitted when unstacking `minerAddr` : change beneficiary to `beneficiary` with info `quota`,`expiration`
    event UnstackingMiner(
        bytes minerAddr,
        bytes beneficiary,
        uint256 quota,
        uint64 expiration
    );
```
