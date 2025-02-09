// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.0;

//   ╔═╗ ┬ ┬┌─┐┌─┐┌┬┐╔═╗┬ ┬┌─┐┬┌┐┌┌─┐
//   ║═╬╗│ │├┤ └─┐ │ ║  ├─┤├─┤││││└─┐
//   ╚═╝╚└─┘└─┘└─┘ ┴ ╚═╝┴ ┴┴ ┴┴┘└┘└─┘

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

import "./interfaces/IQuestChain.sol";
import "./interfaces/IQuestChainFactory.sol";
import "./Collection.sol";
import "./Shelf.sol";
import "./QuestChain.sol";
import "./QuestChainToken.sol";

// author: @dan13ram

/* solhint-disable not-rely-on-time */

contract QuestChainFactory is IQuestChainFactory, ReentrancyGuard {
    using SafeERC20 for IERC20Token;

    /********************************
     * STATE VARIABLES
     *******************************/

    IQuestChainToken private immutable _chainToken;
    IQuestChain private immutable _chainTemplate;
    IShelf private immutable _shelfTemplate;
    ICollection private immutable _collectionTemplate;

    uint256 private _chainCount = 0;
    uint256 private _shelfCount = 0;


    address private _admin;
    address public proposedAdmin;
    uint256 public adminProposalTimestamp;

    uint256 private constant ONE_DAY = 60 * 60 * 24;

    /*********************************
     * MAPPING STRUCTS EVENTS MODIFIER
     *********************************/

    mapping(uint256 => IQuestChain) private _chains;

    error NotAdmin(address attempted);

    /**
     * @dev Callable by admin only
     */
    modifier onlyAdmin() {
        require(_admin == msg.sender, NotAdmin(msg.sender));
        _;
    }

    error AddressNotZero(address _address);

    /**
     * @dev Enforces non-zero address
     */
    modifier nonZeroAddr(address _address) {
        require(_address != address(0), AddressNotZero(_address));
        _;
    }

    error UnchangedAddress(address from, address to);

    /**
     * @dev Enforces two addresses to be different
     */
    modifier changedAddr(address _oldAddress, address _newAddress) {
        require(
            _oldAddress != _newAddress,
            UnchangedAddress(_oldAddress, _newAddress)
        );
        _;
    }

    error UnchangedUInt(uint256 from, uint256 to);

    /**
     * @dev Enforces two integers to be different
     */
    modifier changedUint(uint256 _oldUint, uint256 _newUint) {
        require(
            _oldUint != _newUint,
            UnchangedUInt(_oldUint, _newUint)
        );
        _;
    }

    error OneDayWaitRequired(uint256 from);

    /**
     * @dev Enforces timestamps be at least a day ago
     */
    modifier afterOneDay(uint256 _timestamp) {
        require(
            block.timestamp >= _timestamp + ONE_DAY,
            OneDayWaitRequired(_timestamp)
        );
        _;
    }

    constructor(
        address __admin
    )
        nonZeroAddr(__admin)
    {
        _chainToken = new QuestChainToken();
        _chainTemplate = new QuestChain();
        _shelfTemplate = new Shelf();
        _collectionTemplate = new Collection();

        _admin = __admin;

        emit FactorySetup();
    }

    /*************************
     ACCESS CONTROL FUNCTIONS
     *************************/

    /**
     * @dev Proposes a new admin address
     * @param __admin the address of the new admin
     */
    function proposeAdminReplace(
        address __admin
    )
        external
        onlyAdmin
        nonZeroAddr(__admin)
        changedAddr(proposedAdmin, __admin)
    {
        proposedAdmin = __admin;
        adminProposalTimestamp = block.timestamp;

        emit AdminReplaceProposed(__admin);
    }

    error NotProposedAdmin(address proposed, address sent);

    /**
     * @dev Executes the proposed admin replacement
     */
    function executeAdminReplace()
        external
        nonZeroAddr(proposedAdmin)
        afterOneDay(adminProposalTimestamp)
        changedAddr(proposedAdmin, _admin)
    {
        require(
            proposedAdmin == msg.sender,
            NotProposedAdmin(proposedAdmin, msg.sender)
        );

        _admin = proposedAdmin;

        delete proposedAdmin;
        delete adminProposalTimestamp;

        emit AdminReplaced(_admin);
    }

    /**
     * @dev Deploys a new quest chain minimal proxy
     * @param _info the initialization data struct for our new clone
     * @param _salt an arbitrary source of entropy
     */
    function createChain(
        QuestChainCommons.QuestChainInfo calldata _info,
        bytes32 _salt
    ) external returns (IQuestChain) {
        return _createChain(_info, _salt);
    }

    /**
     * @dev Returns the address of a deployed quest chain proxy
     * @param _index the quest chain contract index
     */
    function getQuestChain(
        uint256 _index
    ) external view returns (IQuestChain) {
        return _chains[_index];
    }

    function tokenCount(
    ) external view override returns (uint256) {
        return _chainCount + _shelfCount;
    }

    function createShelf(
        IShelf.ShelfInfo calldata _info,
        bytes32 _salt
    ) external returns (IShelf _shelf) {
        _shelf = _newShelf(_salt);

        uint256 _tokenId = this.tokenCount();

        emit ShelfCreated(_info.admins, _shelf, _tokenId);

        _chainToken.setTokenOwner(_tokenId, address(_shelf));

        _shelf.init(_info);

        unchecked { ++_shelfCount; }
    }

    /**
     * @dev Internal function deploys a new shelf minimal proxy
     * @param _salt a nonce
     */
    function _newShelf(
        bytes32 _salt
    ) internal returns (IShelf) {
        return IShelf(Clones.cloneDeterministic(
            address(_shelfTemplate), _salt
        ));
    }

    function createCollection(
        ICollection.CollectionInfo calldata _info,
        bytes32 _salt
    ) external returns (ICollection _collection) {
        _collection = _newCollection(_salt);

        emit CollectionCreated(_info.admins, _collection);

        _collection.init(_info);
    }

    /**
     * @dev Internal function deploys a new shelf minimal proxy
     * @param _salt a nonce
     */
    function _newCollection(
        bytes32 _salt
    ) internal returns (ICollection) {
        return ICollection(Clones.cloneDeterministic(
            address(_collectionTemplate), _salt
        ));
    }

    /**
     * @dev Internal function deploys and initializes a new quest chain minimal proxy
     * @param _info the initialization data struct for our new clone
     * @param _salt an arbitrary source of entropy
     */
    function _createChain(
        QuestChainCommons.QuestChainInfo calldata _info,
        bytes32 _salt
    ) internal returns (IQuestChain _chain) {
        _chain = _newChain(_salt);
        _setupQuestChain(_chain, _info);
    }

    /**
     * @dev Internal function deploys a new quest chain minimal proxy
     * @param _salt a nonce
     */
    function _newChain(
        bytes32 _salt
    ) internal returns (IQuestChain) {
        address clone = (
            Clones.cloneDeterministic(address(_chainTemplate), _salt)
        );
        return IQuestChain(clone);
    }

    /**
     * @dev Internal function initializes a new quest chain minimal proxy
     * @param _chain the new minimal proxy's address
     * @param _info the initialization parameters
     */
    function _setupQuestChain(
        IQuestChain _chain,
        QuestChainCommons.QuestChainInfo calldata _info
    ) internal {
        _chainToken.setTokenOwner(
            this.tokenCount(), address(_chain)
        );
        _chain.init(_info);
        _chains[_chainCount] = _chain;

        emit QuestChainCreated(_chainCount, address(_chain));

        unchecked { ++_chainCount; }
    }

    function chainCount(
    ) external view override returns (uint256) {
        return _chainCount;
    }

    function chainTemplate(
    ) external view override returns (IQuestChain) {
        return _chainTemplate;
    }

    function shelfTemplate(
    ) external view override returns (IShelf) {
        return _shelfTemplate;
    }

    function collectionTemplate(
    ) external view override returns (ICollection) {
        return _collectionTemplate;
    }

    function chainToken(
    ) external view override returns (IQuestChainToken) {
        return _chainToken;
    }

    function admin() external view override returns (address) {
        return _admin;
    }
}
