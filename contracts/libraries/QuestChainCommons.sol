// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.0;

//   ╔═╗ ┬ ┬┌─┐┌─┐┌┬┐╔═╗┬ ┬┌─┐┬┌┐┌┌─┐
//   ║═╬╗│ │├┤ └─┐ │ ║  ├─┤├─┤││││└─┐
//   ╚═╝╚└─┘└─┘└─┘ ┴ ╚═╝┴ ┴┴ ┴┴┘└┘└─┘

library QuestChainCommons {
    struct QuestChainInfo {
        address[] owners;
        address[] admins;
        address[] editors;
        address[] reviewers;
        string[] quests;
        bool paused;
        string details;
        string tokenURI;
    }

    error BadSignature(uint256 length);

    function recoverParameters(
        bytes memory _signature
    ) internal pure returns (uint8 v, bytes32 r, bytes32 s) {
        require(_signature.length == 65, BadSignature(_signature.length));
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(_signature, 0x20))
            s := mload(add(_signature, 0x40))
            v := byte(0, mload(add(_signature, 0x60)))
        }
    }
}
