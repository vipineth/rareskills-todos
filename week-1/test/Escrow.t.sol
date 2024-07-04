// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Escrow} from "../src/Escrow.sol";
import {SampleERC20} from "./SampleERC20.sol";

contract EscrowTest is Test {
    Escrow public escrow;
    SampleERC20 public token;

    address user1;
    address user2;

    function setUp() public {
        escrow = new Escrow();
        token = new SampleERC20();

        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
    }

    function testCreateEscrow() public {
        token.mint(user1, 100);
        assertEq(token.balanceOf(user1), 100);
    }
}
