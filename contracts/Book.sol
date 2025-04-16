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

import "./interfaces/IBook.sol";
import "./interfaces/ILimiter.sol";

/// @author @dan13ram, @parv3213, @dysbulic, @Omka
contract Book is
    IBook,
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
    IBookFactory public factory;
    IBookToken public token;
    uint256 public bookId;
    uint256 public tokenId;
    uint256 public chapterCount;

    // address public limiterContract;

    /********************************
     * MAPPING STRUCTS EVENTS MODIFIER
     *******************************/

    mapping(uint256 => ChapterDetails) public chapterDetails;
    mapping(address => mapping(uint256 => Status)) private _chapterStatus;

    /**
     * @dev Callable by factory contract only
     */
    modifier onlyFactory() {
        require(_msgSender() == address(factory), "Book: not factory");
        _;
    }

    // /**
    //  * @dev Functions which are supported only for premium books
    //  */
    // modifier onlyPremium() {
    //     require(premium, "Book: not premium");
    //     _;
    // }

    /**
     * @dev Modifier to make a function callable only when the book is valid
     */
    modifier validChapter(uint256 _id) {
        require(_id < chapterCount, "Book: chapter not found");
        _;
    }

    constructor() {
        _disableInitializers();
    }

    function init(
        BookCommons.BookInfo calldata _info
    ) external initializer {
        factory = IBookFactory(_msgSender());
        token = IBookToken(factory.bookToken());
        bookId = factory.bookCount();
        tokenId = factory.tokenCount();

        _setRoleAdmin(ADMIN_ROLE, OWNER_ROLE);
        _setRoleAdmin(EDITOR_ROLE, ADMIN_ROLE);
        _setRoleAdmin(REVIEWER_ROLE, ADMIN_ROLE);

        _setTokenURI(_info.tokenURI);

        require(_info.owners.length > 0, "Book: no owners");

        for(uint256 i = 0; i < _info.owners.length; ) {
            _cascadeGrantRole(OWNER_ROLE, _info.owners[i]);
            unchecked { ++i; }
        }

        for(uint256 i = 0; i < _info.admins.length; ) {
            _cascadeGrantRole(ADMIN_ROLE, _info.admins[i]);
            unchecked { ++i; }
        }

        for(uint256 i = 0; i < _info.editors.length; ) {
            _cascadeGrantRole(EDITOR_ROLE, _info.editors[i]);
            unchecked { ++i; }
        }

        for(uint256 i = 0; i < _info.reviewers.length; ) {
            _cascadeGrantRole(REVIEWER_ROLE, _info.reviewers[i]);
            unchecked { ++i; }
        }

        chapterCount = chapterCount + _info.chapters.length;
        if(_info.paused) {
            _pause();
        }

        emit BookInit(_info.details, _info.chapters, _info.paused);
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
     * @dev Emits event on update of book details
     * @param _details uri of book details for book
     */
    function edit(string calldata _details) external onlyRole(ADMIN_ROLE) {
        emit BookEdited(_msgSender(), _details);
    }

    /**
     * @dev Creates chapters in a book
     * @param _detailsList list of uris of off book details for new chapters
     */
    function createChapters(
        string[] calldata _detailsList
    ) external onlyRole(EDITOR_ROLE) {
        chapterCount += _detailsList.length;

        emit ChaptersCreated(_msgSender(), _detailsList);
    }

    /**
     * @dev Edits existing chapters in book
     * @param _idList list of chapter ids of the chapters to be edited
     * @param _detailsList list of uris of details for each chapter
     */
    function editChapters(
        uint256[] calldata _idList,
        string[] calldata _detailsList
    ) external onlyRole(EDITOR_ROLE) {
        // local copy of loop length
        uint256 _loopLength = _idList.length;

        // ensure equal length arrays
        require(
            _loopLength == _detailsList.length,
            "Book: list length mismatch"
        );

        for(uint256 i = 0; i < _loopLength; ) {
            require(_idList[i] < chapterCount, "Book: chapter not found");
            unchecked { ++i; }
        }

        // log of book details of chapters edited
        emit ChaptersEdited(_msgSender(), _idList, _detailsList);
    }

    function configureChapters(
        uint256[] calldata _idList,
        ChapterDetails[] calldata _detailsList
    ) external onlyRole(EDITOR_ROLE) {
        uint256 _loopLength = _idList.length;

        require(
            _loopLength == _detailsList.length,
            "Book: list length mismatch"
        );

        for(uint256 i = 0; i < _loopLength; ) {
            require(_idList[i] < chapterCount, "Book: chapter not found");

            chapterDetails[_idList[i]] = ChapterDetails(
                _detailsList[i].paused,
                _detailsList[i].optional,
                _detailsList[i].skipReview
            );

            unchecked { ++i; }
        }

        emit ConfiguredChapters(_msgSender(), _idList, _detailsList);
    }

    /**
     * @dev Submit proofs for completing particular chapters in book
     * @param _idList list of chapter ids of the chapter submissions
     * @param _proofList list of off book proofs for each chapter
     */
    function submitProofs(
        uint256[] calldata _idList,
        string[] calldata _proofList
    ) external whenNotPaused {
        uint256 _loopLength = _idList.length;

        require(
            _loopLength == _proofList.length,
            "Book: list length mismatch"
        );

        for(uint256 i = 0; i < _loopLength; ) {
            _submitProof(_idList[i]);
            unchecked { ++i; }
        }

        emit ChapterProofsSubmitted(_msgSender(), _idList, _proofList);
    }

    /**
     * @dev Reviews proofs for proofs previously submitted by users
     * @param _userList list of users whose submissions are being reviewed
     * @param _idList list of chapter ids of the submissions
     * @param _successList list of booleans accepting or rejecting submissions
     * @param _detailsList list of comments for each submission
     */
    function reviewProofs(
        address[] calldata _userList,
        uint256[] calldata _idList,
        bool[] calldata _successList,
        string[] calldata _detailsList
    ) external onlyRole(REVIEWER_ROLE) {
        uint256 _loopLength = _userList.length;

        require(
            _loopLength == _idList.length &&
                _loopLength == _successList.length &&
                _loopLength == _detailsList.length,
            "Book: invalid params"
        );

        for(uint256 i = 0; i < _loopLength; ) {
            _reviewProof(_userList[i], _idList[i], _successList[i]);
            unchecked { ++i; }
        }

        emit ChapterProofsReviewed(
            _msgSender(),
            _userList,
            _idList,
            _successList,
            _detailsList
        );
    }

    /**
     * @dev Updates token URI for the book NFT
     * @param _uri off book token uri
     */
    function setTokenURI(
        string memory _uri
    ) external onlyRole(ADMIN_ROLE) /* onlyPremium */ {
        _setTokenURI(_uri);
    }

    /**
     * @dev Mints NFT to the msg.sender if they have completed all chapters
     */
    function mintToken() external {
        require(chapterCount > 0, "Book: no chapters found");
        require(complete(), "Book: not complete");

        token.mint(_msgSender(), tokenId);
    }

    /**
     * @dev Burns NFT from the msg.sender
     */
    function burnToken() external {
        token.burn(_msgSender(), tokenId);
    }

    // /**
    //  * @dev Upgrades book to premium
    //  */
    // function upgrade() external onlyFactory {
    //     require(!premium, "Book: already upgraded");
    //     premium = true;
    // }

    /**
     * @dev Public getter to read status of completion of a chapter by a particular user
     * @param _user address of user
     * @param _id identifier of the chapter
     */
    function chapterStatus(
        address _user,
        uint256 _id
    ) external view validChapter(_id) returns (Status) {
        return _chapterStatus[_user][_id];
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
    function _cascadeGrantRole(bytes32 _role, address _account) internal {
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
        if(_role == REVIEWER_ROLE) {
            revokeRole(EDITOR_ROLE, _account);
        } else if(_role == EDITOR_ROLE) {
            revokeRole(ADMIN_ROLE, _account);
        } else if(_role == ADMIN_ROLE) {
            revokeRole(OWNER_ROLE, _account);
        }
    }

    /**
     * @dev Public getter to view book token uri
     */
    function getTokenURI() public view returns (string memory) {
        return token.uri(tokenId);
    }

    /**
     * @return Whether the sender can mint the NFT
     */
    function complete() public view returns (bool) {
        bool _onePassed;

        for(uint256 _id = 0; _id < chapterCount; ) {
            require(
                (
                    chapterDetails[_id].optional
                    || chapterDetails[_id].paused
                    || _chapterStatus[_msgSender()][_id] == Status.pass
                ),
                "Book: book incomplete"
            );
            if(
                !_onePassed
                // At least one chapter completed and reviewed.
                && _chapterStatus[_msgSender()][_id] == Status.pass
            ) _onePassed = true;
            unchecked { ++_id; }
        }

        require(_onePassed, "Book: no approved reviews");

        return true;
    }

    /**
     * @dev internal function to update status of chapter to review
     * @param _id identifier of chapter
     */
    function _submitProof(uint256 _id) internal validChapter(_id) {
        require(!chapterDetails[_id].paused, "Book: chapter paused");
        require(
            _chapterStatus[_msgSender()][_id] != Status.pass,
            "Book: already passed"
        );

        chapterDetails[_id].skipReview
            ? _chapterStatus[_msgSender()][_id] = Status.pass
            : _chapterStatus[_msgSender()][_id] = Status.review;
    }

    /**
     * @dev internal function to review chapter
     * @param _user user address
     * @param _id identifier of chapter
     * @param _success accepting / rejecting proof
     */
    function _reviewProof(
        address _user,
        uint256 _id,
        bool _success
    ) internal validChapter(_id) {
        require(
            _chapterStatus[_user][_id] == Status.review,
            "Book: chapter not in review"
        );

        _chapterStatus[_user][_id] = _success ? Status.pass : Status.fail;
    }

    /**
     * @dev internal function to update token uri
     * @param _uri off book token uri
     */
    function _setTokenURI(string memory _uri) internal {
        token.setTokenURI(tokenId, _uri);
        emit BookTokenURIUpdated(_uri);
    }

    function bookFactory()
        external
        view
        override
        returns (IBookFactory)
    {
        return factory;
    }

    function bookToken()
        external
        view
        override
        returns (IBookToken)
    {
        return token;
    }
}
