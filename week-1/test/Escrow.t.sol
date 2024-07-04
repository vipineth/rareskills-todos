// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Escrow} from "../src/Escrow.sol";
import {SampleERC20} from "./SampleERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "forge-std/console.sol";

contract EscrowTest is Test {
    Escrow public escrow;
    SampleERC20 public sampleToken;

    address user1;
    address user2;
    uint256 escrowTime;

    function setUp() public {
        escrow = new Escrow();
        sampleToken = new SampleERC20();

        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        escrowTime = escrow.ESCROW_TIME();
    }

    function test_CreateEscrow() public {
        vm.startPrank(user1);

        uint256 mintAmount = 100;
        uint256 escrowAmount = 100;
        uint256 expectedEscrowId = 0;
        uint256 expectedReleaseTime = block.timestamp + escrowTime;

        uint256 escrowId = createEscrowHelper(
            user1,
            mintAmount,
            escrowAmount,
            user2
        );

        (
            address token,
            address sender,
            address recipient,
            uint256 amount,
            uint256 releaseTime,
            bool isReleased
        ) = escrow.escrows(expectedEscrowId);

        assertEq(escrowId, expectedEscrowId, "Escrow ID should be 0");
        assertEq(token, address(sampleToken), "Token address should match");
        assertEq(sender, user1, "Sender should be user1");
        assertEq(recipient, user2, "Recipient should be user2");
        assertEq(amount, escrowAmount, "Amount should be 100");
        assertEq(
            releaseTime,
            expectedReleaseTime,
            "Release time should be current block timestamp + 3 days"
        );
        assertEq(isReleased, false, "isReleased should be false");

        vm.stopPrank();
    }

    function test_Withdraw() public {
        uint256 mintAmount = 100;
        uint256 escrowAmount = 50;

        vm.startPrank(user1);
        uint256 escrowId = createEscrowHelper(
            user1,
            mintAmount,
            escrowAmount,
            user2
        );
        vm.stopPrank();

        vm.startPrank(user2);
        skip(escrowTime);
        escrow.withdraw(escrowId);

        vm.stopPrank();
    }

    function testFail_Withdraw() public {
        vm.startPrank(user2);
        skip(escrowTime);
        escrow.withdraw(0);
        vm.stopPrank();
    }

    function testFail_CreateEscrowWithZeroAmount() public {
        vm.startPrank(user1);
        uint256 mintAmount = 100;
        uint256 escrowAmount = 0;

        vm.expectRevert("InvalidAmount");
        createEscrowHelper(user1, mintAmount, escrowAmount, user2);

        vm.stopPrank();
    }

    function testFail_CreateEscrowWithInvalidRecipient() public {
        vm.startPrank(user1);
        uint256 mintAmount = 100;
        uint256 escrowAmount = 50;

        vm.expectRevert("InvalidAddress");
        createEscrowHelper(user1, mintAmount, escrowAmount, address(0));

        vm.stopPrank();
    }

    function testFail_WithdrawBeforeReleaseTime() public {
        uint256 mintAmount = 100;
        uint256 escrowAmount = 50;

        vm.startPrank(user1);
        uint256 escrowId = createEscrowHelper(
            user1,
            mintAmount,
            escrowAmount,
            user2
        );
        vm.stopPrank();

        vm.startPrank(user2);
        vm.expectRevert("EscrowTimeNotPassed");
        escrow.withdraw(escrowId);

        vm.stopPrank();
    }

    function testFail_WithdrawByNonRecipient() public {
        uint256 mintAmount = 100;
        uint256 escrowAmount = 50;

        vm.startPrank(user1);
        uint256 escrowId = createEscrowHelper(
            user1,
            mintAmount,
            escrowAmount,
            user2
        );
        vm.stopPrank();

        vm.startPrank(user1);
        skip(escrowTime);
        vm.expectRevert("NotRecipient");
        escrow.withdraw(escrowId);

        vm.stopPrank();
    }

    function createEscrowHelper(
        address sender,
        uint256 mintAmount,
        uint256 escrowAmount,
        address recipient
    ) internal returns (uint256 escrowId) {
        sampleToken.mint(sender, mintAmount);
        IERC20(sampleToken).approve(address(escrow), escrowAmount);

        return
            escrow.createEscrow(address(sampleToken), recipient, escrowAmount);
    }
}
