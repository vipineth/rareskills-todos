// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract CappedGasFee is Ownable {
    uint256 public maxGasFee = 30 gwei;

    constructor() Ownable(msg.sender) {}

    error MaxGasFeeExceeded();

    modifier withCappedGasFee() {
        if (tx.gasprice > maxGasFee) revert MaxGasFeeExceeded();
        _;
    }

    function updateMaxGasFee(uint256 _maxGasFee) external onlyOwner {
        maxGasFee = _maxGasFee;
    }
}
