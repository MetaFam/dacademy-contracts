// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

// ᗪ闩⼕闩ᗪ🝗爪丫

import "../interfaces/IQuestChain.sol";

interface IShelf {
    struct ShelfInfo {
        address[] owners;
        address[] admins;
        IQuestChain[] chains;
        string details;
        string tokenURI;
    }

    event ShelfOrdered(IQuestChain[] chains);

    event ShelfEdited(string details);

    event ShelfAdminAdded(address actor, address admin);

    event ShelfAdminRemoved(address actor, address admin);

    function init(ShelfInfo calldata _info) external;

    function complete() external view returns (bool);
}
