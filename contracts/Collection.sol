// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

// ᗪ闩⼕闩ᗪ🝗爪丫 ⼕ㄖ㇄㇄🝗⼕〸讠ㄖ𝓝

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "./interfaces/ICollection.sol";
import "./interfaces/IShelf.sol";

contract Collection is
    ICollection,
    ReentrancyGuard,
    Initializable,
    AccessControl
{
    error NoOwners();

    bytes32 public constant OWNER_ROLE = DEFAULT_ADMIN_ROLE;
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    IQuestChainFactory factory;
    IShelf[] public shelves;

    function init(
        CollectionInfo calldata _info
    ) external initializer {
        require(_info.owners.length > 0, NoOwners());

        factory = IQuestChainFactory(_msgSender());

        _setRoleAdmin(ADMIN_ROLE, OWNER_ROLE);

        uint256 i = 0;
        while(i < _info.owners.length) {
            _grantRole(OWNER_ROLE, _info.owners[i]);
            _grantRole(ADMIN_ROLE, _info.owners[i]);
            unchecked { ++i; }
        }

        for(i = 0; i < _info.admins.length; ) {
            _grantRole(ADMIN_ROLE, _info.admins[i]);
            unchecked { ++i; }
        }

        _edit(_info.details);
        _order(_info.shelves);
    }

    function order(
        IShelf[] calldata _shelves
    ) public onlyRole(ADMIN_ROLE) {
        _order(_shelves);
    }

    function _order(
        IShelf[] calldata _shelves
    ) internal {
        shelves = _shelves;
        emit CollectionOrdered(shelves);
    }

    function edit(
        string calldata details
    ) public onlyRole(ADMIN_ROLE) {
        _edit(details);
    }

   function _edit(
        string calldata details
    ) internal {
        emit CollectionEdited(details);
    }

    function complete() public view returns (bool completed) {
        completed = true;
        for(uint256 i = 0; completed && i < shelves.length; ) {
            completed = completed && shelves[i].complete();
            unchecked { ++i; }
        }
    }
}
