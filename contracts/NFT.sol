//SPDX-License-Identifier: None
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract P_NFTs is Context, Ownable, ERC721Enumerable, ERC721Pausable {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.AddressSet;

    /** @notice Capped max supply */
    uint256 public immutable supplyCap = 10;

    /** @notice Each address has a mint quota */
    uint16 public immutable quota = 2;

    string private _baseTokenURI;

    //Token ID counter declared
    Counters.Counter private _tokenIds;

    /**
     * Token URIs will be autogenerated based on `baseURI` and their token IDs.
     * See {ERC721-tokenURI}.
     */
    bool public isFrozen;
    bool public isOpen;

    //Mapping to track number of mints per address
    mapping(address => uint256) public userMintCount;

    modifier mintOpen() {
        require(isOpen, "Public mint not open.");
        _;
    }

    //Functions related to minting or changing NFT metadata are inaccessible after freezing
    modifier nonFrozen() {
        require(!isFrozen, "NFT metadata is frozen.");
        _;
    }

    constructor() ERC721("Test", "TST") {
        _baseTokenURI = "ipfs://<temp CID>/";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /** @notice Owner can change baseURI */
    function setBaseURI(string memory baseTokenURI)
        external
        onlyOwner
        nonFrozen
    {
        _baseTokenURI = baseTokenURI;
    }

    //Open public mint
    function openMint() external onlyOwner nonFrozen {
        isOpen = true;
    }

    //End public mint
    function closeMint() external onlyOwner nonFrozen {
        isOpen = false;
    }

    /**
     * @dev Creates a new token for `to`. Its token ID will be automatically
     * assigned (and available on the emitted {IERC721-Transfer} event), and the token
     * URI autogenerated based on the base URI passed at construction.
     *
     * See {ERC721-_mint}.
     */
    function mintPNFT() public mintOpen {
        //require(msg.sender == tx.origin, "no bots");
        require(userMintCount[msg.sender] < quota, "Exceed quota");

        require(totalSupply() < supplyCap, "Exceed cap");
        require(!paused(), "Paused");
        userMintCount[msg.sender]++;

        _mint(_msgSender(), _tokenIds.current() + 1);
        _tokenIds.increment();
    }

    /** @notice Contract owner can burn token he owns */
    function burn(uint256 _id) external onlyOwner {
        require(ownerOf(_id) == _msgSender());
        _burn(_id);
    }

    /** @notice Pass an array of address to batch mint
     * @param _recipients List of addresses to receive the batch mint
     */
    function batchMint(address[] calldata _recipients)
        external
        nonFrozen
        onlyOwner
    {
        require(
            totalSupply() + _recipients.length - 1 < supplyCap,
            "Exceed cap"
        );

        for (uint256 i = 0; i < _recipients.length; i++) {
            _mint(_recipients[i], _tokenIds.current() + 1);
            _tokenIds.increment();
        }
    }

    /** @notice Owner can batch mint to itself
     * @param _amount Number of tokens to be minted
     */
    function batchMintForOwner(uint256 _amount) external onlyOwner nonFrozen {
        require(totalSupply() + _amount - 1 < supplyCap, "Exceed cap");

        for (uint256 i = 0; i < _amount; i++) {
            _mint(_msgSender(), _tokenIds.current() + 1);
            _tokenIds.increment();
        }
    }

    /**
     * @dev Pauses all token transfers and mint
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses all token transfers and mint.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    //Prevent most token functions being called thereby freezing metadata
    function freeze() external onlyOwner {
        isFrozen = true;
    }

    function isMintActive() external view returns (bool) {
        return isOpen;
    }

    function totalMintCount() external view returns (uint256) {
        return _tokenIds.current();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
