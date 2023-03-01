// SPDX-License-Identifier: MIT
pragma solidity >=0.4.25 <=0.8.17;

import "@zondax/filecoin-solidity/contracts/v0.8/MinerAPI.sol";
import "@zondax/filecoin-solidity/contracts/v0.8/types/MinerTypes.sol";
import "@zondax/filecoin-solidity/contracts/v0.8/SendAPI.sol";
import "@zondax/filecoin-solidity/contracts/v0.8/types/CommonTypes.sol";
import "hardhat/console.sol";

import "./Utils/Convertion.sol";

contract MinerOp {
    using Convertion for *;

    function test(uint64 minerID, uint256 amount) public {
        SendAPI.send(CommonTypes.FilActorId.wrap(minerID) , amount);
    }

    function testBeneficiary(uint64 minerID) public {
        // get beneficiary
        CommonTypes.FilActorId id = CommonTypes.FilActorId.wrap(minerID);
        MinerTypes.PendingBeneficiaryChange memory proposedBeneficiaryRet = MinerAPI
            .getBeneficiary(id).proposed;

        MinerTypes.ChangeBeneficiaryParams memory changeParams = MinerTypes
            .ChangeBeneficiaryParams({
                new_beneficiary: proposedBeneficiaryRet.new_beneficiary,
                new_quota: proposedBeneficiaryRet.new_quota,
                new_expiration: proposedBeneficiaryRet.new_expiration
            });
        MinerAPI.changeBeneficiary(id, changeParams);
    }

    function get_owner(uint64 minerID)
        public
        returns (MinerTypes.GetOwnerReturn memory)
    {
        return MinerAPI.getOwner(CommonTypes.FilActorId.wrap(minerID));
    }

    function change_owner_address(uint64 minerID, bytes memory ownerAddr)
        public
    {
        MinerAPI.changeOwnerAddress(CommonTypes.FilActorId.wrap(minerID), CommonTypes.FilAddress(ownerAddr));
    }

    function is_controlling_address(uint64 minerID, bytes memory addr)
        public
        returns (bool)
    {
        return MinerAPI.isControllingAddress(CommonTypes.FilActorId.wrap(minerID), CommonTypes.FilAddress(addr));
    }

    function get_sector_size(uint64 target)
        public
        returns (uint64)
    {
        return MinerAPI.getSectorSize(CommonTypes.FilActorId.wrap(target));
    }

    function get_available_balance(uint64 target)
        public
        returns (CommonTypes.BigInt memory)
    {
        return MinerAPI.getAvailableBalance(CommonTypes.FilActorId.wrap(target));
    }

    function get_vesting_funds(uint64 target)
        public
        returns (MinerTypes.GetVestingFundsReturn memory)
    {
        return MinerAPI.getVestingFunds(CommonTypes.FilActorId.wrap(target));
    }

    function change_beneficiary(
        uint64 target,
        MinerTypes.ChangeBeneficiaryParams memory params
    ) public {
        return MinerAPI.changeBeneficiary(CommonTypes.FilActorId.wrap(target), params);
    }

    function get_beneficiary(uint64 target)
        public
        returns (MinerTypes.GetBeneficiaryReturn memory)
    {
        return MinerAPI.getBeneficiary(CommonTypes.FilActorId.wrap(target));
    }

    function change_worker_address(
        uint64 target,
        MinerTypes.ChangeWorkerAddressParams memory params
    ) public {
        MinerAPI.changeWorkerAddress(CommonTypes.FilActorId.wrap(target), params);
    }

    function change_peer_id(
        uint64 target,
        CommonTypes.FilAddress memory newId
    ) public {
        MinerAPI.changePeerId(CommonTypes.FilActorId.wrap(target), newId);
    }

    function change_multiaddresses(
        uint64 target,
        MinerTypes.ChangeMultiaddrsParams memory params
    ) public {
        MinerAPI.changeMultiaddresses(CommonTypes.FilActorId.wrap(target), params);
    }

    function repay_debt(uint64 target) public {
        MinerAPI.repayDebt(CommonTypes.FilActorId.wrap(target));
    }

    function confirm_change_worker_address(uint64 target) public {
        MinerAPI.confirmChangeWorkerAddress(CommonTypes.FilActorId.wrap(target));
    }

    function get_peer_id(uint64 target)
        public
        returns (CommonTypes.FilAddress memory)
    {
        return MinerAPI.getPeerId(CommonTypes.FilActorId.wrap(target));
    }

    function get_multiaddresses(uint64 target)
        public
        returns (MinerTypes.GetMultiaddrsReturn memory)
    {
        return MinerAPI.getMultiaddresses(CommonTypes.FilActorId.wrap(target));
    }

    function withdraw_balance(
        uint64 target,
        CommonTypes.BigInt memory amount
    ) public returns (CommonTypes.BigInt memory) {
        return MinerAPI.withdrawBalance(CommonTypes.FilActorId.wrap(target), amount);
    }
}
