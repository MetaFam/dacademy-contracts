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
    bytes32 public constant ADMIN_ROLE = DEFAULT_ADMIN_ROLE;

    address factory;
    address[] public chains;

    function init(
        QuestChainCommons.ShelfInfo calldata _info
    ) external initializer {
        require(
            _info.admins.length == 0,
            "DAShelf: at least one admin required"
        );

        factory = _msgSender();

        for (uint256 i = _info.admins.length - 1; i >= 0; ) {
            _grantRole(ADMIN_ROLE, _info.admins[i]);
            unchecked {
                --i;
            }
        }

        chains = _info.chains;

        emit ShelfCreated(_info.creator, _info.admins);
        emit ShelfOrdered(_info.chains);
        emit ShelfEdited(_info.details);
    }

    function complete() public view returns (bool completed) {
        completed = true;
        for (uint256 i = chains.length - 1; completed && i >= 0; i--) {
            completed = completed && IQuestChain(chains[i]).complete();
        }
    }
}
