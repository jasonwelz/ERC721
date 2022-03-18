//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
 * @dev {ERC721} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *  - token ID and URI autogeneration
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 *
 * _Deprecated in favor of https://wizard.openzeppelin.com/[Contracts Wizard]._
 */
contract NFT is Context, Ownable, ERC721Enumerable, ERC721Pausable {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.AddressSet;

    /** @notice Free mint 1 per wallet. Subsequent mint cost 0.1 ETH */
    EnumerableSet.AddressSet freeMint;
    uint256 public immutable costToMint = 0.1 ether;

    /** @notice Capped max supply */
    uint256 public immutable supplyCap = 100;

    Counters.Counter private _tokenIdTracker;

    string private _baseTokenURI;

    /**
     * Token URIs will be autogenerated based on `baseURI` and their token IDs.
     * See {ERC721-tokenURI}.
     */
    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI
    ) ERC721(name, symbol) {
        _baseTokenURI = baseTokenURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /** @notice Owner can change baseURI */
    function setBaseURI(string memory baseTokenURI) external onlyOwner {
        _baseTokenURI = baseTokenURI;
    }

    /**
     * @dev Creates a new token for `to`. Its token ID will be automatically
     * assigned (and available on the emitted {IERC721-Transfer} event), and the token
     * URI autogenerated based on the base URI passed at construction.
     *
     * See {ERC721-_mint}.
     */
    function mint(address to) public payable {
        require(!freeMint.contains(_msgSender()) || msg.value == costToMint);
        require(totalSupply() < supplyCap, "EXCEED CAP");
        require(!paused(), "PAUSED");

        // We cannot just use balanceOf to create the new tokenId because tokens
        // can be burned (destroyed), so we need a separate counter.
        _mint(to, _tokenIdTracker.current());
        _tokenIdTracker.increment();
    }

    function burn(uint256 _id) external onlyOwner {
        _burn(_id);
    }

    /** @notice Pass an array of address to batch mint */
    function batchMint(address[] calldata _recipients) external onlyOwner {
        for (uint256 i = 0; i < _recipients.length; i++) {
            _mint(_recipients[i], _tokenIdTracker.current());
            _tokenIdTracker.increment();
        }
    }

    /** @notice Owner can batch mint to itself */
    function batchMintForOwner(uint256 count) external onlyOwner {
        for (uint256 i = 0; i < count; i++) {
            _mint(_msgSender(), _tokenIdTracker.current());
            _tokenIdTracker.increment();
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