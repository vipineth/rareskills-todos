// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {BitMaps} from "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Trio is ERC721, ERC2981, Ownable {
    using BitMaps for BitMaps.BitMap;

    uint256 public constant MAX_SUPPLY = 1000;
    uint96 public constant ROYALTY_FEE = 250; // 2.5% royalty fee
    uint256 public constant MINT_PRICE = 0.01 ether;
    uint256 public constant DISCOUNT_PERCENTAGE = 30;

    uint256 private _currentSupply;
    bytes32 public immutable _merkleRoot;
    BitMaps.BitMap private _discountedAddresses;

    error NotEligibleForDiscount();
    error AlreadyMinted();
    error MaxSupplyReached();
    error InsufficientBalance();
    error InvalidProof();
    error WithdrawFailed();

    constructor() ERC721("Trio", "TRO") Ownable(msg.sender) {
        _setDefaultRoyalty(msg.sender, ROYALTY_FEE);
    }

    function mint() public payable {
        require(msg.value >= MINT_PRICE, InsufficientBalance());
        require(_currentSupply < MAX_SUPPLY, MaxSupplyReached());
        _currentSupply++;
        _mint(msg.sender, _currentSupply);
    }

    function mintWithDiscount(
        bytes32[] memory proof,
        uint256 index
    ) public payable {
        uint256 discountedPrice = (MINT_PRICE * (100 - DISCOUNT_PERCENTAGE)) /
            100;

        require(_discountedAddresses.get(index), NotEligibleForDiscount());
        require(!_discountedAddresses.get(index), AlreadyMinted());
        require(msg.value >= discountedPrice, InsufficientBalance());
        require(_currentSupply < MAX_SUPPLY, MaxSupplyReached());

        _verifyProof(proof, index);
        _discountedAddresses.set(index);

        _currentSupply++;

        _mint(msg.sender, _currentSupply);
    }

    function withdrawFunds(address to) public onlyOwner {
        (bool success, ) = payable(to).call{value: address(this).balance}("");
        require(success, WithdrawFailed());
    }

    function _verifyProof(bytes32[] memory proof, uint256 index) private view {
        bytes32 leaf = keccak256(abi.encode(msg.sender, index));
        require(MerkleProof.verify(proof, _merkleRoot, leaf), InvalidProof());
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
