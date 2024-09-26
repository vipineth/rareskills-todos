// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {Test, console} from "forge-std/Test.sol";
import {Pair} from "../src/Pair.sol";
import {Factory} from "../src/Factory.sol";
import {IPair} from "../src/interfaces/IPair.sol";
import {MockERC20} from "./MockERC20.sol";

contract PairTest is Test {
  Pair pair;
  MockERC20 token0;
  MockERC20 token1;
  address user1;
  address user2;

  function setUp() public {
    pair = new Pair();
    token0 = new MockERC20("Token 1", "TKN1");
    token1 = new MockERC20("Token 2", "TKN2");
    pair.initialize(address(token0), address(token1));
  }

  function testInitialize() public view {
    assertEq(pair.token0(), address(token0));
    assertEq(pair.token1(), address(token1));

    (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = pair.getReserves();
    assertEq(reserve0, 0);
    assertEq(reserve1, 0);
    assertEq(blockTimestampLast, 0);

    assertEq(pair.name(), "Swap LP");
    assertEq(pair.symbol(), "SLP");
    assertEq(pair.totalSupply(), 0);

    assertEq(pair.MINIMUM_LIQUIDITY(), 10 ** 3);

    assertEq(pair.factory(), address(this));
  }

  function testInitializeUnauthorized() public {
    Pair newPair = new Pair();
    vm.prank(user1);
    vm.expectRevert(IPair.Unauthorized.selector);
    newPair.initialize(address(token0), address(token1));
  }
}
