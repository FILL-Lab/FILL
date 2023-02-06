// SPDX-License-Identifier: MIT
pragma solidity >=0.4.25 <=0.8.17;

import "@zondax/filecoin-solidity/contracts/v0.8/MinerAPI.sol";
import "@zondax/filecoin-solidity/contracts/v0.8/types/MinerTypes.sol";
import "@zondax/filecoin-solidity/contracts/v0.8/cbor/BytesCbor.sol";
import "@zondax/filecoin-solidity/contracts/v0.8/SendAPI.sol";
import "hardhat/console.sol";

contract MinerOp {
    using BytesCBOR for bytes;

    function test(bytes memory minerAddress, uint256 amount) public {
        SendAPI.send(minerAddress, amount);
    }

    function testBeneficiary(bytes memory minerAddress) public {
        // get beneficiary
        CommonTypes.PendingBeneficiaryChange memory proposedBeneficiaryRet = MinerAPI
            .getBeneficiary(minerAddress).proposed;

        MinerTypes.ChangeBeneficiaryParams memory changeParams = MinerTypes
            .ChangeBeneficiaryParams({
                new_beneficiary: proposedBeneficiaryRet.new_beneficiary,
                new_quota: proposedBeneficiaryRet.new_quota,
                new_expiration: proposedBeneficiaryRet.new_expiration
            });
        MinerAPI.changeBeneficiary(minerAddress, changeParams);
    }

    function get_owner(bytes memory target)
        public
        returns (MinerTypes.GetOwnerReturn memory)
    {
        return MinerAPI.getOwner(target);
    }

    function change_owner_address(bytes memory target, bytes memory addr)
        public
    {
        MinerAPI.changeOwnerAddress(target, addr);
    }

    function is_controlling_address(bytes memory target, bytes memory addr)
        public
        returns (MinerTypes.IsControllingAddressReturn memory)
    {
        return MinerAPI.isControllingAddress(target, addr);
    }

    function get_sector_size(bytes memory target)
        public
        returns (MinerTypes.GetSectorSizeReturn memory)
    {
        return MinerAPI.getSectorSize(target);
    }

    function get_available_balance(bytes memory target)
        public
        returns (MinerTypes.GetAvailableBalanceReturn memory)
    {
        return MinerAPI.getAvailableBalance(target);
    }

    function get_vesting_funds(bytes memory target)
        public
        returns (MinerTypes.GetVestingFundsReturn memory)
    {
        return MinerAPI.getVestingFunds(target);
    }

    function change_beneficiary(
        bytes memory target,
        MinerTypes.ChangeBeneficiaryParams memory params
    ) public {
        return MinerAPI.changeBeneficiary(target, params);
    }

    function get_beneficiary(bytes memory target)
        public
        returns (MinerTypes.GetBeneficiaryReturn memory)
    {
        return MinerAPI.getBeneficiary(target);
    }

    function change_worker_address(
        bytes memory target,
        MinerTypes.ChangeWorkerAddressParams memory params
    ) public {
        MinerAPI.changeWorkerAddress(target, params);
    }

    function change_peer_id(
        bytes memory target,
        MinerTypes.ChangePeerIDParams memory params
    ) public {
        MinerAPI.changePeerId(target, params);
    }

    function change_multiaddresses(
        bytes memory target,
        MinerTypes.ChangeMultiaddrsParams memory params
    ) public {
        MinerAPI.changeMultiaddresses(target, params);
    }

    function repay_debt(bytes memory target) public {
        MinerAPI.repayDebt(target);
    }

    function confirm_change_worker_address(bytes memory target) public {
        MinerAPI.confirmChangeWorkerAddress(target);
    }

    function get_peer_id(bytes memory target)
        public
        returns (MinerTypes.GetPeerIDReturn memory)
    {
        return MinerAPI.getPeerId(target);
    }

    function get_multiaddresses(bytes memory target)
        public
        returns (MinerTypes.GetMultiaddrsReturn memory)
    {
        return MinerAPI.getMultiaddresses(target);
    }

    function withdraw_balance(
        bytes memory target,
        MinerTypes.WithdrawBalanceParams memory params
    ) public returns (MinerTypes.WithdrawBalanceReturn memory) {
        return MinerAPI.withdrawBalance(target, params);
    }
}
