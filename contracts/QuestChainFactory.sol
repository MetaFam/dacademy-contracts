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

    uint256 private _chainCount = 0;

    address private _admin;
    address public proposedAdmin;
    uint256 public adminProposalTimestamp;

    uint256 private constant ONE_DAY = 60 * 60 * 24;

    /*********************************
     * MAPPING STRUCTS EVENTS MODIFIER
     *********************************/

    mapping(uint256 => IQuestChain) private _chains;

    /**
     * @dev Callable by admin only
     */
    modifier onlyAdmin() {
        require(_admin == msg.sender, "QCFactory: not admin");
        _;
    }

    /**
     * @dev Enforces non-zero address
     */
    modifier nonZeroAddr(address _address) {
        require(_address != address(0), "QCFactory: 0x0 address");
        _;
    }

    /**
     * @dev Enforces two addresses to be different
     */
    modifier changedAddr(address _oldAddress, address _newAddress) {
        require(_oldAddress != _newAddress, "QCFactory: no change");
        _;
    }

    /**
     * @dev Enforces two integers to be different
     */
    modifier changedUint(uint256 _oldUint, uint256 _newUint) {
        require(_oldUint != _newUint, "QCFactory: no change");
        _;
    }

    /**
     * @dev Enforces timestamps be at least a day ago
     */
    modifier afterOneDay(uint256 _timestamp) {
        require(
            block.timestamp >= _timestamp + ONE_DAY,
            "QCFactory: wait a day"
        );
        _;
    }

    constructor(
        address __admin
    )
        // address _treasury,
        // address _paymentToken,
        // uint256 _upgradeFee
        nonZeroAddr(__admin)
    {
        _chainToken = new QuestChainToken();
        _chainTemplate = new QuestChain();
        _shelfTemplate = new Shelf();

        _admin = __admin;

        // treasury = _treasury;
        // paymentToken = IERC20Token(_paymentToken);
        // upgradeFee = _upgradeFee;

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
            "QCFactory: not the proposed admin"
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
    function getQuestChain(uint256 _index) external view returns (IQuestChain) {
        return _chains[_index];
    }

    function createShelf(
        QuestChainCommons.ShelfInfo calldata _info,
        bytes32 _salt
    ) internal returns (address _shelfAddress) {
        _shelfAddress = _newShelf(_salt);

        _chainToken.setTokenOwner(_chainCount, _shelfAddress);
        IShelf(_shelfAddress).init(_info);

        emit ShelfCreated(_chainCount, _shelfAddress);

        unchecked {
            ++_chainCount;
        }
    }

    /**
     * @dev Internal function deploys a new shelf minimal proxy
     * @param _salt a nonce
     */
    function _newShelf(bytes32 _salt) internal returns (address) {
        return Clones.cloneDeterministic(address(_shelfTemplate), _salt);
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
    function _newChain(bytes32 _salt) internal returns (IQuestChain) {
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
        _chainToken.setTokenOwner(_chainCount, address(_chain));
        _chain.init(_info);
        _chains[_chainCount] = _chain;

        emit QuestChainCreated(_chainCount, address(_chain));

        unchecked {
            ++_chainCount;
        }
    }

    function chainCount() external view override returns (uint256) {
        return _chainCount;
    }

    function chainTemplate() external view override returns (IQuestChain) {
        return _chainTemplate;
    }

    function chainToken() external view override returns (IQuestChainToken) {
        return _chainToken;
    }

    function admin() external view override returns (address) {
        return _admin;
    }
}
