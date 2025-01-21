// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.0;

//   ╔═╗ ┬ ┬┌─┐┌─┐┌┬┐╔═╗┬ ┬┌─┐┬┌┐┌┌─┐
//   ║═╬╗│ │├┤ └─┐ │ ║  ├─┤├─┤││││└─┐
//   ╚═╝╚└─┘└─┘└─┘ ┴ ╚═╝┴ ┴┴ ┴┴┘└┘└─┘

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "./interfaces/IQuestChain.sol";
import "./interfaces/ILimiter.sol";

/// @author @dan13ram, @parv3213, @dysbulic, @Omka
contract QuestChain is
    IQuestChain,
    ReentrancyGuard,
    Initializable,
    Pausable,
    AccessControl
{
    /********************************
     * CONSTANT VARIABLES
     *******************************/

    bytes32 public constant OWNER_ROLE = DEFAULT_ADMIN_ROLE;
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant EDITOR_ROLE = keccak256("EDITOR_ROLE");
    bytes32 public constant REVIEWER_ROLE = keccak256("REVIEWER_ROLE");

    /********************************
     * STATE VARIABLES
     *******************************/
    // bool public premium;
    IQuestChainFactory public factory;
    IQuestChainToken public token;
    uint256 public chainId;
    uint256 public questCount;

    address public creator;
    uint256 public length;

    // address public limiterContract;

    /********************************
     * MAPPING STRUCTS EVENTS MODIFIER
     *******************************/

    mapping(uint256 => QuestDetails) public questDetails;
    mapping(address => mapping(uint256 => Status)) private _questStatus;

    /**
     * @dev Callable by factory contract only
     */
    modifier onlyFactory() {
        require(_msgSender() == address(factory), "QuestChain: not factory");
        _;
    }

    // /**
    //  * @dev Functions which are supported only for premium quest chains
    //  */
    // modifier onlyPremium() {
    //     require(premium, "QuestChain: not premium");
    //     _;
    // }

    /**
     * @dev Modifier to make a function callable only when the quest is valid
     */
    modifier validQuest(uint256 _id) {
        require(_id < questCount, "QuestChain: quest not found");
        _;
    }

    constructor() {
        _disableInitializers();
    }

    function init(
        QuestChainCommons.QuestChainInfo calldata _info
    ) external initializer {
        creator = _msgSender();

        factory = IQuestChainFactory(_msgSender());
        token = IQuestChainToken(factory.chainToken());
        chainId = factory.chainCount();

        _setRoleAdmin(ADMIN_ROLE, OWNER_ROLE);
        _setRoleAdmin(EDITOR_ROLE, ADMIN_ROLE);
        _setRoleAdmin(REVIEWER_ROLE, ADMIN_ROLE);

        _setTokenURI(_info.tokenURI);

        require(_info.owners.length > 0, "QuestChain: no owners");

        for(uint256 i = 0; i < _info.owners.length; ) {
            _cascadeGrantRole(OWNER_ROLE, _info.owners[i]);
            unchecked {
                ++i;
            }
        }

        for(uint256 i = 0; i < _info.admins.length; ) {
            _cascadeGrantRole(ADMIN_ROLE, _info.admins[i]);
            unchecked {
                ++i;
            }
        }

        for(uint256 i = 0; i < _info.editors.length; ) {
            _cascadeGrantRole(EDITOR_ROLE, _info.editors[i]);
            unchecked {
                ++i;
            }
        }

        for(uint256 i = 0; i < _info.reviewers.length; ) {
            _cascadeGrantRole(REVIEWER_ROLE, _info.reviewers[i]);
            unchecked {
                ++i;
            }
        }

        questCount = questCount + _info.quests.length;
        if(_info.paused) {
            _pause();
        }

        emit QuestChainInit(_info.details, _info.quests, _info.paused);
    }

    /**
     * @dev Triggers disabled state
     */
    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    /**
     * @dev Returns to enabled state
     */
    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @dev Emits event to update quest chain details
     * @param _details uri of off chain details for quest chain
     */
    function edit(string calldata _details) external onlyRole(ADMIN_ROLE) {
        emit QuestChainEdited(_msgSender(), _details);
    }

    /**
     * @dev Creates quests in quest chain
     * @param _detailsList list of uris of off chain details for new quests
     */
    function createQuests(
        string[] calldata _detailsList
    ) external onlyRole(EDITOR_ROLE) {
        questCount += _detailsList.length;

        emit QuestsCreated(_msgSender(), _detailsList);
    }

    /**
     * @dev Edits existing quests in quest chain
     * @param _idList list of quest ids of the quests to be edited
     * @param _detailsList list of uris of off chain details for each quest
     */
    function editQuests(
        uint256[] calldata _idList,
        string[] calldata _detailsList
    ) external onlyRole(EDITOR_ROLE) {
        // local copy of loop length
        uint256 _loopLength = _idList.length;

        // ensure equal length arrays
        require(
            _loopLength == _detailsList.length,
            "QuestChain: list length mismatch"
        );

        for(uint256 i = 0; i < _loopLength; ) {
            require(_idList[i] < questCount, "QuestChain: quest not found");
            unchecked {
                ++i;
            }
        }

        // log off chain details of quests edited
        emit QuestsEdited(_msgSender(), _idList, _detailsList);
    }

    function configureQuests(
        uint256[] calldata _idList,
        QuestDetails[] calldata _detailsList
    ) external onlyRole(EDITOR_ROLE) {
        uint256 _loopLength = _idList.length;

        // Check if length of questIdList equals questDetailsList
        require(
            _loopLength == _detailsList.length,
            "QuestChain: list length mismatch"
        );

        for (uint256 i = 0; i < _loopLength; ) {
            // Check if quest is valid
            require(_idList[i] < questCount, "QuestChain: quest not found");

            questDetails[_idList[i]] = QuestDetails(
                _detailsList[i].paused,
                _detailsList[i].optional,
                _detailsList[i].skipReview
            );

            unchecked {
                ++i;
            }
        }

        emit ConfiguredQuests(_msgSender(), _idList, _detailsList);
    }

    /**
     * @dev Submit proofs for completing particular quests in quest chain
     * @param _idList list of quest ids of the quest submissions
     * @param _proofList list of off chain proofs for each quest
     */
    function submitProofs(
        uint256[] calldata _idList,
        string[] calldata _proofList
    ) external whenNotPaused {
        uint256 _loopLength = _idList.length;

        require(
            _loopLength == _proofList.length,
            "QuestChain: list length mismatch"
        );

        for (uint256 i = 0; i < _loopLength; ) {
            _submitProof(_idList[i]);
            unchecked {
                ++i;
            }
        }

        emit QuestProofsSubmitted(_msgSender(), _idList, _proofList);
    }

    /**
     * @dev Reviews proofs for proofs previously submitted by questers
     * @param _questerList list of questers whose submissions are being reviewed
     * @param _idList list of quest ids of the quest submissions
     * @param _successList list of booleans accepting or rejecting submissions
     * @param _detailsList list of off chain comments for each submission
     */
    function reviewProofs(
        address[] calldata _questerList,
        uint256[] calldata _idList,
        bool[] calldata _successList,
        string[] calldata _detailsList
    ) external onlyRole(REVIEWER_ROLE) {
        uint256 _loopLength = _questerList.length;

        require(
            _loopLength == _idList.length &&
                _loopLength == _successList.length &&
                _loopLength == _detailsList.length,
            "QuestChain: invalid params"
        );

        for (uint256 i = _loopLength - 1; i >= 0; ) {
            _reviewProof(_questerList[i], _idList[i], _successList[i]);
            unchecked {
                --i;
            }
        }

        emit QuestProofsReviewed(
            _msgSender(),
            _questerList,
            _idList,
            _successList,
            _detailsList
        );
    }

    /**
     * @dev Updates token URI for the quest chain NFT
     * @param _uri off chain token uri
     */
    function setTokenURI(
        string memory _uri
    ) external onlyRole(ADMIN_ROLE) /* onlyPremium */ {
        _setTokenURI(_uri);
    }

    /**
     * @dev Mints NFT to the msg.sender if they have completed all quests
     */
    function mintToken() external {
        require(questCount > 0, "QuestChain: no quests found");
        require(complete(), "QuestChain: not complete");

        token.mint(_msgSender(), chainId);
    }

    /**
     * @dev Burns NFT from the msg.sender
     */
    function burnToken() external {
        token.burn(_msgSender(), chainId);
    }

    // /**
    //  * @dev Upgrades quest chain to premium
    //  */
    // function upgrade() external onlyFactory {
    //     require(!premium, "QuestChain: already upgraded");
    //     premium = true;
    // }

    /**
     * @dev Public getter to read status of completion of a quest by a particular quester
     * @param _quester address of quester
     * @param _id identifier of the quest
     */
    function questStatus(
        address _quester,
        uint256 _id
    ) external view validQuest(_id) returns (Status) {
        return _questStatus[_quester][_id];
    }

    /**
     * @dev Grants cascading roles to user
     * @param _role role to be granted
     * @param _account address of the user
     */
    function grantRole(
        bytes32 _role,
        address _account
    ) public override onlyRole(getRoleAdmin(_role)) {
        _cascadeGrantRole(_role, _account);
    }

    /**
     * @dev Grants cascading roles to user
     * @param _role role to be granted
     * @param _account address of the user
     */
    function _cascadeGrantRole(
        bytes32 _role,
        address _account
    ) internal {
        _grantRole(_role, _account);
        if(_role == OWNER_ROLE) {
            _cascadeGrantRole(ADMIN_ROLE, _account);
        } else if(_role == ADMIN_ROLE) {
            _cascadeGrantRole(EDITOR_ROLE, _account);
        } else if(_role == EDITOR_ROLE) {
            _cascadeGrantRole(REVIEWER_ROLE, _account);
        }
    }

    /**
     * @dev Revokes cascading roles from user
     * @param _role role to be revoked
     * @param _account address of the user
     */
    function revokeRole(
        bytes32 _role,
        address _account
    ) public override onlyRole(getRoleAdmin(_role)) {
        _revokeRole(_role, _account);
        if (_role == REVIEWER_ROLE) {
            revokeRole(EDITOR_ROLE, _account);
        } else if (_role == EDITOR_ROLE) {
            revokeRole(ADMIN_ROLE, _account);
        } else if (_role == ADMIN_ROLE) {
            revokeRole(OWNER_ROLE, _account);
        }
    }

    /**
     * @dev Public getter to view quest chain token uri
     */
    function getTokenURI() public view returns (string memory) {
        return token.uri(chainId);
    }

    /**
     * @return Whether the sender can mint the NFT
     */
    function complete() public view returns (bool) {
        bool _onePassed;

        for (uint256 _id = questCount - 1; _id >= 0; ) {
            require(
                questDetails[_id].optional ||
                    questDetails[_id].paused ||
                    _questStatus[_msgSender()][_id] == Status.pass,
                "QuestChain: chain incomplete"
            );
            if (
                !_onePassed &&
                // At least one quest completed and reviewed.
                _questStatus[_msgSender()][_id] == Status.pass
            ) _onePassed = true;
            unchecked {
                --_id;
            }
        }

        require(_onePassed, "QuestChain: no approved reviews");

        return true;
    }

    /**
     * @dev internal function to update status of quest to review
     * @param _id identifier of quest
     */
    function _submitProof(uint256 _id) internal validQuest(_id) {
        require(!questDetails[_id].paused, "QuestChain: quest paused");
        require(
            _questStatus[_msgSender()][_id] != Status.pass,
            "QuestChain: already passed"
        );

        questDetails[_id].skipReview
            ? _questStatus[_msgSender()][_id] = Status.pass
            : _questStatus[_msgSender()][_id] = Status.review;
    }

    /**
     * @dev internal function to review quest
     * @param _quester quester address
     * @param _id identifier of quest
     * @param _success accepting / rejecting proof
     */
    function _reviewProof(
        address _quester,
        uint256 _id,
        bool _success
    ) internal validQuest(_id) {
        require(
            _questStatus[_quester][_id] == Status.review,
            "QuestChain: quest not in review"
        );

        _questStatus[_quester][_id] = _success ? Status.pass : Status.fail;
    }

    /**
     * @dev internal function to update token uri
     * @param _uri off chain token uri
     */
    function _setTokenURI(string memory _uri) internal {
        token.setTokenURI(chainId, _uri);
        emit QuestChainTokenURIUpdated(_uri);
    }

    function questChainFactory()
        external
        view
        override
        returns (IQuestChainFactory)
    {
        return factory;
    }

    function questChainToken()
        external
        view
        override
        returns (IQuestChainToken)
    {
        return token;
    }

    function questChainId() external view override returns (uint256) {
        return chainId;
    }
}
