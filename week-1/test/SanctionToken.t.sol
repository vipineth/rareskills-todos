// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {SanctionToken} from "../src/SanctionToken.sol";

contract SanctionTokenTest is Test {
    SanctionToken public sanctionToken;
    address public user1;
    address public user2;

    function setUp() public {
        sanctionToken = new SanctionToken();
        user1 = vm.addr(1);
        user2 = vm.addr(2);
    }

    function test_name() public view {
        assertEq(sanctionToken.name(), "SanctionToken");
    }

    function test_symbol() public view {
        assertEq(sanctionToken.symbol(), "SNT");
    }

    function test_owner() public view {
        assertEq(sanctionToken.owner(), address(this));
    }

    function test_balance() public view {
        assertEq(sanctionToken.balanceOf(address(this)), 1000 ether);
    }

    function test_senderBannedError() public {
        sanctionToken.transfer(user1, 5 ether);
        sanctionToken.ban(user1);

        vm.startPrank(user1);
        bytes memory encodedError = abi.encodeWithSignature("SenderBanned(address)", user1);
        vm.expectRevert(encodedError);
        sanctionToken.transfer(user2, 2 ether);
        vm.stopPrank();
    }
}
