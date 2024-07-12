// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {Trio} from "../src/Trio.sol";

contract TrioTest is Test {
    Trio public trio;

    function setUp() public {
        trio = new Trio();
    }
}
