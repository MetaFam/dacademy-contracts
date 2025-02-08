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
    bytes32 public constant OWNER_ROLE = DEFAULT_ADMIN_ROLE;
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    IQuestChainFactory factory;
    IQuestChainToken token;
    IQuestChain[] public chains;
    uint256 public tokenId;

    function init(
        QuestChainCommons.ShelfInfo calldata _info
    ) external initializer {
        require(
            _info.owners.length > 0,
            "DA Shelf: no owners"
        );

        factory = IQuestChainFactory(_msgSender());
        token = IQuestChainToken(factory.chainToken());

        tokenId = factory.tokenCount();

        _setRoleAdmin(ADMIN_ROLE, OWNER_ROLE);

        _setTokenURI(_info.tokenURI);

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
        _order(_info.chains);
    }

    function order(
        IQuestChain[] calldata _chains
    ) public onlyRole(ADMIN_ROLE) {
        _order(_chains);
    }

    function _order(
        IQuestChain[] calldata _chains
    ) internal {
        chains = _chains;
        emit ShelfOrdered(chains);
    }

    function edit(
        string calldata details
    ) public onlyRole(ADMIN_ROLE) {
        _edit(details);
    }

   function _edit(
        string calldata details
    ) internal {
        emit ShelfEdited(details);
    }

    function complete() public view returns (bool completed) {
        completed = true;
        for(uint256 i = 0; completed && i < chains.length; ) {
            completed = completed && IQuestChain(chains[i]).complete();
            unchecked { ++i; }
        }
    }

    function getTokenURI() public view returns (string memory) {
        return token.uri(tokenId);
    }

    function setTokenURI(
        string memory _uri
    ) external onlyRole(ADMIN_ROLE) {
        _setTokenURI(_uri);
    }

    function _setTokenURI(string memory _uri) internal {
        token.setTokenURI(tokenId, _uri);
        // emit URIUpdated(_uri);
    }

    function burnToken() external {
        token.burn(_msgSender(), tokenId);
    }

    function mintToken() external {
        require(complete(), "Shelf: not complete");

        token.mint(_msgSender(), tokenId);
    }
}
