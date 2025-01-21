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
     STATE VARIABLES
     *******************************/

    IQuestChainToken private immutable _chainToken;
    IQuestChain private immutable _chainTemplate;
    IShelf private immutable _shelfTemplate;

    // address public immutable treasury;

    uint256 private _chainCount = 0;

    address private _admin;
    address public proposedAdmin;
    uint256 public adminProposalTimestamp;

    // IERC20Token public paymentToken;
    // address public proposedPaymentToken;
    // uint256 public paymentTokenProposalTimestamp;

    // uint256 public upgradeFee;
    // uint256 public proposedUpgradeFee;
    // uint256 public upgradeFeeProposalTimestamp;

    uint256 private constant ONE_DAY = 60 * 60 * 24;

    /********************************
     * MAPPING STRUCTS EVENTS MODIFIER
     *******************************/

    mapping(uint256 => address) private _chains;

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

    // /**
    //  * @dev Proposes a new paymentToken address
    //  * @param _paymentToken the address of the new paymentToken
    //  */
    // function proposePaymentTokenReplace(
    //     address _paymentToken
    // )
    //     external
    //     onlyAdmin
    //     nonZeroAddr(_paymentToken)
    //     changedAddr(proposedPaymentToken, _paymentToken)
    // {
    //     // set proposed paymentToken address
    //     proposedPaymentToken = _paymentToken;
    //     paymentTokenProposalTimestamp = block.timestamp;

    //     // log proposedPaymentToken change data
    //     emit PaymentTokenReplaceProposed(_paymentToken);
    // }

    // /**
    //  * @dev Executes the proposed paymentToken replacement
    //  */
    // function executePaymentTokenReplace()
    //     external
    //     onlyAdmin
    //     nonZeroAddr(proposedPaymentToken)
    //     afterOneDay(paymentTokenProposalTimestamp)
    //     changedAddr(proposedPaymentToken, address(paymentToken))
    // {
    //     // replace paymentToken
    //     paymentToken = IERC20Token(proposedPaymentToken);

    //     delete proposedPaymentToken;
    //     delete paymentTokenProposalTimestamp;

    //     // log paymentToken change data
    //     emit PaymentTokenReplaced(paymentToken);
    // }

    // /**
    //  * @dev Proposes a new upgradeFee
    //  * @param _upgradeFee the new upgradeFee
    //  */
    // function proposeUpgradeFeeReplace(
    //     uint256 _upgradeFee
    // ) external onlyAdmin changedUint(proposedUpgradeFee, _upgradeFee) {
    //     // set proposed upgradeFee
    //     proposedUpgradeFee = _upgradeFee;
    //     upgradeFeeProposalTimestamp = block.timestamp;

    //     // log proposedUpgradeFee change data
    //     emit UpgradeFeeReplaceProposed(_upgradeFee);
    // }

    // /**
    //  * @dev Executes the proposed upgradeFee replacement
    //  */
    // function executeUpgradeFeeReplace()
    //     external
    //     onlyAdmin
    //     afterOneDay(upgradeFeeProposalTimestamp)
    //     changedUint(proposedUpgradeFee, upgradeFee)
    // {
    //     upgradeFee = proposedUpgradeFee;

    //     delete proposedUpgradeFee;
    //     delete upgradeFeeProposalTimestamp;

    //     emit UpgradeFeeReplaced(upgradeFee);
    // }

    /**
     * @dev Deploys a new quest chain minimal proxy
     * @param _info the initialization data struct for our new clone
     * @param _salt an arbitrary source of entropy
     */
    function createChain(
        QuestChainCommons.QuestChainInfo calldata _info,
        bytes32 _salt
    ) external returns (address) {
        return _createChain(_info, _salt);
    }

    // /**
    //  * @dev Deploys a new quest chain minimal proxy and runs an upgrade
    //  * @param _info the initialization data struct for our new clone
    //  * @param _salt an arbitrary source of entropy
    //  */
    // function createAndUpgrade(
    //     QuestChainCommons.QuestChainInfo calldata _info,
    //     bytes32 _salt
    // ) external nonReentrant returns (address) {
    //     // deploy new quest chain minimal proxy
    //     address questChainAddress = _create(_info, _salt);

    //     // upgrade new quest chain and transfer upgrade fee to treasury
    //     _upgradeQuestChain(questChainAddress);
    //     return questChainAddress;
    // }

    // /**
    //  * @dev Deploys a new quest chain minimal proxy and runs an upgrade while permitting upgrade fee
    //  * @param _info the initialization data struct for our new clone
    //  * @param _salt an arbitrary source of entropy
    //  * @param _deadline the timestamp where permit expires
    //  * @param _signature the ERC20 permit signature
    //  */
    // function createAndUpgradeWithPermit(
    //     QuestChainCommons.QuestChainInfo calldata _info,
    //     bytes32 _salt,
    //     uint256 _deadline,
    //     bytes calldata _signature
    // ) external nonReentrant returns (address) {
    //     // deploy new quest chain minimal proxy
    //     address questChainAddress = _create(_info, _salt);

    //     // upgrade new quest chain and permit fee
    //     _upgradeQuestChainWithPermit(questChainAddress, _deadline, _signature);
    //     return questChainAddress;
    // }

    // /**
    //  * @dev Upgrades an existing quest chain contract
    //  * @param _questChainAddress the quest chain contract to be upgraded
    //  */
    // function upgradeQuestChain(
    //     address _questChainAddress
    // ) external nonReentrant {
    //     // upgrade new quest chain and transfer upgrade fee to treasury
    //     _upgradeQuestChain(_questChainAddress);
    // }

    // /**
    //  * @dev Upgrades an existing quest chain contract
    //  * @param _questChainAddress the quest chain contract to be upgraded
    //  * @param _deadline the timestamp where permit expires
    //  * @param _signature the ERC20 permit signature
    //  */
    // function upgradeQuestChainWithPermit(
    //     address _questChainAddress,
    //     uint256 _deadline,
    //     bytes calldata _signature
    // ) external nonReentrant {
    //     _upgradeQuestChainWithPermit(_questChainAddress, _deadline, _signature);
    // }

    /**
     * @dev Returns the address of a deployed quest chain proxy
     * @param _index the quest chain contract index
     */
    function getQuestChainAddress(
        uint256 _index
    ) external view returns (address) {
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
     * @dev Internal function deploys and initializes a new quest chain minimal proxy
     * @param _info the initialization data struct for our new clone
     * @param _salt an arbitrary source of entropy
     */
    function _createChain(
        QuestChainCommons.QuestChainInfo calldata _info,
        bytes32 _salt
    ) internal returns (address _chainAddress) {
        _chainAddress = _newChain(_salt);

        _setupQuestChain(_chainAddress, _info);
    }

    /**
     * @dev Internal function deploys a new quest chain minimal proxy
     * @param _salt a nonce
     */
    function _newChain(bytes32 _salt) internal returns (address) {
        return Clones.cloneDeterministic(address(_chainTemplate), _salt);
    }

    /**
     * @dev Internal function deploys a new shelf minimal proxy
     * @param _salt a nonce
     */
    function _newShelf(bytes32 _salt) internal returns (address) {
        return Clones.cloneDeterministic(address(_shelfTemplate), _salt);
    }

    /**
     * @dev Internal function initializes a new quest chain minimal proxy
     * @param _chainAddress the new minimal proxy's address
     * @param _info the initialization parameters
     */
    function _setupQuestChain(
        address _chainAddress,
        QuestChainCommons.QuestChainInfo calldata _info
    ) internal {
        _chainToken.setTokenOwner(_chainCount, _chainAddress);
        IQuestChain(_chainAddress).init(_info);
        _chains[_chainCount] = _chainAddress;

        emit QuestChainCreated(_chainCount, _chainAddress);

        unchecked {
            ++_chainCount;
        }
    }

    // /**
    //  * @dev Internal function upgrades an existing quest chain and transfers upgrade fee to treasury
    //  * @param _questChainAddress the new minimal proxy's address
    //  */
    // function _upgradeQuestChain(address _questChainAddress) internal {
    //     // transfer upgrade fee to the treasury from caller
    //     paymentToken.safeTransferFrom(msg.sender, treasury, upgradeFee);

    //     // assign quest chain as premium
    //     IQuestChain(_questChainAddress).upgrade();

    //     // log quest chain premium upgrade data
    //     emit QuestChainUpgraded(msg.sender, _questChainAddress);
    // }

    // /**
    //  * @dev Internal function upgrades an existing quest chain and permits upgrade fee
    //  * @param _questChainAddress the new minimal proxy's address
    //  * @param _deadline the timestamp permit expires upon
    //  * @param _signature the ERC20Permit signature
    //  */
    // function _upgradeQuestChainWithPermit(
    //     address _questChainAddress,
    //     uint256 _deadline,
    //     bytes calldata _signature
    // ) internal {
    //     // recover signature parameters
    //     (uint8 v, bytes32 r, bytes32 s) = QuestChainCommons.recoverParameters(
    //         _signature
    //     );

    //     // permit upgrade fee
    //     paymentToken.safePermit(
    //         msg.sender,
    //         address(this),
    //         upgradeFee,
    //         _deadline,
    //         v,
    //         r,
    //         s
    //     );

    //     // upgrade the quest chain to premium
    //     _upgradeQuestChain(_questChainAddress);
    // }
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
