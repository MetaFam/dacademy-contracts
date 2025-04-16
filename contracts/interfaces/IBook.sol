// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.0;

//   ╔═╗ ┬ ┬┌─┐┌─┐┌┬┐╔═╗┬ ┬┌─┐┬┌┐┌┌─┐
//   ║═╬╗│ │├┤ └─┐ │ ║  ├─┤├─┤││││└─┐
//   ╚═╝╚└─┘└─┘└─┘ ┴ ╚═╝┴ ┴┴ ┴┴┘└┘└─┘

import "../libraries/BookCommons.sol";
import "./IBookToken.sol";

interface IBook {
    enum Status {
        init,
        review,
        pass,
        fail
    }

    struct ChapterDetails {
        bool paused;
        bool optional;
        bool skipReview;
    }

    event BookInit(string details, string[] chapters, bool paused);
    event BookEdited(address editor, string details);
    event ChaptersCreated(address creator, string[] detailsList);
    event ConfiguredChapters(
        address editor,
        uint256[] chapterIdList,
        ChapterDetails[] chapterDetails
    );
    event ChaptersEdited(
        address editor,
        uint256[] chapterIdList,
        string[] detailsList
    );
    event SetLimiter(address limiterContract);
    event ChapterProofsSubmitted(
        address user,
        uint256[] chapterIdList,
        string[] proofList
    );
    event ChapterProofsReviewed(
        address reviewer,
        address[] userList,
        uint256[] chapterIdList,
        bool[] successList,
        string[] detailsList
    );
    event BookTokenURIUpdated(string tokenURI);

    function init(BookCommons.BookInfo calldata _info) external;

    function setTokenURI(string memory _tokenURI) external;

    function edit(string calldata _details) external;

    function createChapters(string[] calldata _detailsList) external;

    function editChapters(
        uint256[] calldata _chapterIdList,
        string[] calldata _detailsList
    ) external;

    function configureChapters(
        uint256[] calldata _chapterIdList,
        ChapterDetails[] calldata _chapterDetails
    ) external;

    function submitProofs(
        uint256[] calldata _chapterIdList,
        string[] calldata _proofList
    ) external;

    function reviewProofs(
        address[] calldata _userList,
        uint256[] calldata _chapterIdList,
        bool[] calldata _successList,
        string[] calldata _detailsList
    ) external;

    function mintToken() external;

    function burnToken() external;

    // function upgrade() external;

    function complete() external view returns (bool);

    function bookFactory() external view returns (IBookFactory);

    function bookToken() external view returns (IBookToken);

    function bookId() external view returns (uint256);

    function getTokenURI() external view returns (string memory);

    function chapterStatus(
        address _user,
        uint256 _chapterId
    ) external view returns (Status);
}
