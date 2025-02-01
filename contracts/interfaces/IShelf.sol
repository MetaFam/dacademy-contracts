// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

// ᗪ闩⼕闩ᗪ🝗爪丫

import "../libraries/QuestChainCommons.sol";

interface IShelf {
    event ShelfOrdered(address[] chains);

    event ShelfEdited(string details);

    event ShelfAdminAdded(address actor, address admin);

    event ShelfAdminRemoved(address actor, address admin);

    function init(QuestChainCommons.ShelfInfo calldata _info) external;
}
