// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {BitMaps} from "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract TrioNFT is ERC721, ERC2981, Ownable {
    using BitMaps for BitMaps.BitMap;

    uint256 public constant MAX_SUPPLY = 1000;
    uint96 public constant ROYALTY_FEE = 250; // 2.5% royalty fee
    uint256 public constant MINT_PRICE = 0.01 ether;
    uint256 public constant DISCOUNT_PERCENTAGE = 30;

    uint256 private _currentSupply;
    bytes32 public immutable _merkleRoot;
    BitMaps.BitMap private _discountedAddresses;

    error NotEligibleForDiscount();
    error AlreadyMintedWithDiscountPrice();
    error MaxSupplyReached();
    error InsufficientBalance();
    error InvalidProof();
    error WithdrawFailed();

    constructor(bytes32 merkleRoot) ERC721("Trio", "TRO") Ownable(msg.sender) {
        _merkleRoot = merkleRoot;
        _setDefaultRoyalty(msg.sender, ROYALTY_FEE);
    }

    function mint() public payable {
        if (msg.value < MINT_PRICE) {
            revert InsufficientBalance();
        }
        if (_currentSupply >= MAX_SUPPLY) {
            revert MaxSupplyReached();
        }
        _currentSupply++;
        _mint(msg.sender, _currentSupply);
    }

    function mintWithDiscount(
        bytes32[] memory proofs,
        uint256 index
    ) public payable {
        uint256 discountedPrice = (MINT_PRICE * (100 - DISCOUNT_PERCENTAGE)) /
            100;

        if (!_verifyProof(proofs, index)) {
            revert InvalidProof();
        }
        if (this.isNftClaimed(index)) {
            revert AlreadyMintedWithDiscountPrice();
        }
        if (msg.value < discountedPrice) {
            revert InsufficientBalance();
        }
        if (_currentSupply >= MAX_SUPPLY) {
            revert MaxSupplyReached();
        }

        _verifyProof(proofs, index);
        _discountedAddresses.setTo(index, true);

        _currentSupply++;

        _mint(msg.sender, _currentSupply);
    }

    function withdrawFunds(address to) public onlyOwner {
        (bool success, ) = payable(to).call{value: address(this).balance}("");
        if (!success) {
            revert WithdrawFailed();
        }
    }

    function _verifyProof(
        bytes32[] memory proofs,
        uint256 index
    ) private view returns (bool) {
        bytes32 leaf = keccak256(abi.encode(msg.sender, index));
        return MerkleProof.verify(proofs, _merkleRoot, leaf);
    }

    function isNftClaimed(uint256 tokenId) external view returns (bool) {
        return _discountedAddresses.get(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
