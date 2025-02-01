// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

// ᗪ闩⼕闩ᗪ🝗爪丫 丂卄🝗㇄ﾁ

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "./interfaces/IShelf.sol";
import "./interfaces/IQuestChain.sol";

contract Shelf is
    IShelf,
    ReentrancyGuard,
    Initializable,
    Pausable,
    AccessControl
{
    bytes32 public constant CREATOR_ROLE = DEFAULT_ADMIN_ROLE;
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    address factory;
    address[] public chains;

    function init(
        QuestChainCommons.ShelfInfo calldata _info
    ) external initializer {
        require(
            _info.admins.length > 0,
            "DAShelf: at least one admin required"
        );

        factory = _msgSender();

        _setupRole(CREATOR_ROLE, _info.creator);
        _setupRole(ADMIN_ROLE, _info.creator);

        for(uint256 i = 0; i < _info.admins.length; ) {
            _grantRole(ADMIN_ROLE, _info.admins[i]);
            unchecked { ++i; }
        }

        edit(_info.details);
        order(_info.chains);
    }

    function order(
        address[] calldata _chains
    ) public onlyRole(ADMIN_ROLE) {
        chains = _chains;
        emit ShelfOrdered(chains);
    }

    function edit(
        string calldata details
    ) public onlyRole(ADMIN_ROLE) {
        emit ShelfEdited(details);
    }

    function complete() public view returns (bool completed) {
        completed = true;
        for(uint256 i = 0; completed && i < chains.length; ) {
            completed = completed && IQuestChain(chains[i]).complete();
            unchecked { ++i; }
        }
    }
}
