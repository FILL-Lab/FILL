// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@zondax/filecoin-solidity/contracts/v0.8/MinerAPI.sol";
import "@zondax/filecoin-solidity/contracts/v0.8/AccountAPI.sol";

import "./Context.sol";

contract Validation is Context {
    mapping(bytes => uint256) private nonces;

    function validateOwner(
        uint64 minerID,
        bytes memory signature,
        address sender
    ) external {
        bytes memory ownerAddr = getOwner(minerID);
        bytes memory digest = getDigest(
            ownerAddr,
            minerID,
            sender
        );
        AccountAPI.authenticateMessage(
            CommonTypes.FilActorId.wrap(minerID),
            AccountTypes.AuthenticateMessageParams({
                signature: signature,
                message: digest
            })
        );
        
        nonces[ownerAddr] += 1;
    }

    function getSigningMsg(uint64 minerID) external returns (bytes memory) {
        bytes memory ownerAddr = getOwner(minerID);
        return getDigest(ownerAddr, minerID, _msgSender());
    }

    function getDigest(
        bytes memory ownerAddr,
        uint64 minerID,
        address sender
    ) private view returns (bytes memory) {
        bytes32 digest = keccak256(abi.encode(
            keccak256("validateOwner"),
            ownerAddr,
            minerID,
            sender,
            nonces[ownerAddr],
            getChainId()
        ));
        return bytes.concat(digest);
    }

    function getOwner(uint64 minerID) private returns (bytes memory) {
        return MinerAPI.getOwner(CommonTypes.FilActorId.wrap(minerID)).owner.data;
    }

    function getChainId() private view returns (uint256 chainId) {
        assembly {
            chainId := chainid()
        }
    }
}
