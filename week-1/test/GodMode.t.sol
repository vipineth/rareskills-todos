// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {GodMode} from "../src/GodMode.sol";

contract GodModeTest is Test {
    GodMode public godModeToken;
    address public user1;
    address public user2;

    function setUp() public {
        godModeToken = new GodMode();
        user1 = vm.addr(1);
        user2 = vm.addr(2);
    }

    function test_name() public view {
        assertEq(godModeToken.name(), "GodMode");
    }

    function test_symbol() public view {
        assertEq(godModeToken.symbol(), "GOD");
    }

    function test_owner() public view {
        assertEq(godModeToken.owner(), address(this));
    }

    function test_balance() public view {
        assertEq(godModeToken.balanceOf(address(this)), 1000 ether);
    }

    function test_godMode() public {
        godModeToken.transfer(user1, 10 ether);

        godModeToken.transferFrom(user1, user2, 5 ether);
        assertEq(godModeToken.balanceOf(user1), 5 ether);
        assertEq(godModeToken.balanceOf(user2), 5 ether);
    }
}
