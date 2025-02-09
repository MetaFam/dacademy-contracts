// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

// ᗪ闩⼕闩ᗪ🝗爪丫 ⼕ㄖ㇄㇄🝗⼕〸讠ㄖ𝓝

import "../interfaces/IShelf.sol";

interface ICollection {
    struct CollectionInfo {
        address[] owners;
        address[] admins;
        IShelf[] shelves;
        string details;
    }

    event CollectionOrdered(IShelf[] shelves);

    event CollectionEdited(string details);

    event CollectionAdminAdded(address actor, address admin);

    event CollectionAdminRemoved(address actor, address admin);

    function init(CollectionInfo calldata _info) external;
}
