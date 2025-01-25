// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.0;

//   ╔═╗ ┬ ┬┌─┐┌─┐┌┬┐╔═╗┬ ┬┌─┐┬┌┐┌┌─┐
//   ║═╬╗│ │├┤ └─┐ │ ║  ├─┤├─┤││││└─┐
//   ╚═╝╚└─┘└─┘└─┘ ┴ ╚═╝┴ ┴┴ ┴┴┘└┘└─┘

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./interfaces/IQuestChain.sol";
import "./interfaces/IQuestChainToken.sol";

// author: @dan13ram

contract QuestChainToken is IQuestChainToken, ERC1155 {
    IQuestChainFactory public immutable factory;

    string public name = "dAcademy Achievement";
    string public symbol = "DAA";

    mapping(uint256 => string) private _uris;
    mapping(uint256 => address) private _owners;

    /**
     * @dev Access control modifier for functions callable by factory contract only
     */
    modifier onlyFactory() {
        require(msg.sender == address(factory), "QuestChainToken: not factory");
        _;
    }

    /**
     * @dev Access control modifier for functions callable by token owners only
     * @param _id the complete initialization data
     */
    modifier onlyTokenOwner(uint256 _id) {
        require(msg.sender == _owners[_id], "QuestChainToken: not token owner");
        _;
    }

    constructor() ERC1155("") {
        factory = IQuestChainFactory(_msgSender());
    }

    /*************************
     * ACCESS CONTROL FUNCTIONS
     *************************/

    /**
     * @dev Assigns quest chain ownership
     * @param _id the quest NFT identifier
     * @param _chain the address of the new QuestChain minimal proxy
     */
    function setTokenOwner(uint256 _id, address _chain) public onlyFactory {
        // assign quest chain address as quest token's owner
        _owners[_id] = _chain;
    }

    /**
     * @dev Assigns the metadata location for a quest line
     * @param _id the quest NFT identifier
     * @param _uri the URI pointer for locating token metadata
     */
    function setTokenURI(
        uint256 _id,
        string memory _uri
    ) public onlyTokenOwner(_id) {
        _uris[_id] = _uri;

        emit URI(_uri, _id);
    }

    /**
     * @dev Mints a quest achievement token to the user
     * @param _user the address of a successful questing user
     * @param _id the quest token identifier
     */
    function mint(address _user, uint256 _id) public onlyTokenOwner(_id) {
        require(balanceOf(_user, _id) == 0, "QuestChainToken: already minted");

        _mint(_user, _id, 1, "");
    }

    /**
     * @dev Burns a quest achievement token from the user
     * @param _user the address of a successful questing user
     * @param _id the quest token identifier
     */
    function burn(address _user, uint256 _id) public onlyTokenOwner(_id) {
        // place user balance on the stack
        uint256 balance = balanceOf(_user, _id);

        // enforce that user owns exactly one quest token
        require(balance > 0, "QuestChainToken: token not found");

        _burn(_user, _id, balance);
    }

    /*************************
     * VIEW AND PURE FUNCTIONS
     *************************/

    /**
     * @return Owner address of a quest token
     * @param _id the quest token identifier
     */
    function tokenOwner(uint256 _id) public view returns (address) {
        return _owners[_id];
    }

    /**
     * @return Metadata URI of a particular quest token
     * @param _id the quest token identifier
     */
    function uri(
        uint256 _id
    )
        public
        view
        override(IERC1155MetadataURI, ERC1155)
        returns (string memory)
    {
        return _uris[_id];
    }

    /*************************
     * OVERRIDES
     *************************/

    /**
     * @dev Prevents transferring the tokens and thus makes them SoulBound
     */
    function _beforeTokenTransfer(
        address,
        address _from,
        address _to,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) internal pure override {
        require(
            _to == address(0) || _from == address(0),
            "QuestChainToken: soulbound"
        );
    }

    /**
     * @dev Prevents approval of the tokens and thus makes them SoulBound
     */
    function _setApprovalForAll(address, address, bool) internal pure override {
        revert("QuestChainToken: soulbound");
    }

    function questChainFactory()
        external
        view
        override
        returns (IQuestChainFactory)
    {
        return factory;
    }
}
