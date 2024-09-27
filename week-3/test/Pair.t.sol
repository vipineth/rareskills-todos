// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {Test, console, stdError} from "forge-std/Test.sol";
import {Pair} from "../src/Pair.sol";
import {Factory} from "../src/Factory.sol";
import {IPair} from "../src/interfaces/IPair.sol";
import {MockERC20} from "./MockERC20.sol";
import {FixedPointMathLib} from "solady/utils/FixedPointMathLib.sol";

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

  function testMintInitialLiquidity() public {
    uint256 amount0 = 1000 ether;
    uint256 amount1 = 2000 ether;

    uint256 liquidity = addLiquidity(amount0, amount1);

    uint256 expectedLiquidity = FixedPointMathLib.sqrt(amount0 * amount1) - pair.MINIMUM_LIQUIDITY();
    assertEq(liquidity, expectedLiquidity);
    assertEq(pair.balanceOf(address(this)), expectedLiquidity);
    assertEq(pair.totalSupply(), expectedLiquidity + pair.MINIMUM_LIQUIDITY());

    (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
    assertEq(reserve0, amount0);
    assertEq(reserve1, amount1);
  }

  function testMintAdditionalLiq() public {
    // first mint
    uint256 init0 = 50 ether;
    uint256 init1 = 80 ether;
    addLiquidity(init0, init1);

    // Second mint
    uint256 add0 = 80 ether;
    uint256 add1 = 60 ether;

    (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
    uint256 expectedLiquidity0 = (add0 * pair.totalSupply()) / reserve0;
    uint256 expectedLiquidity1 = (add1 * pair.totalSupply()) / reserve1;
    uint256 expectedLiquidity = expectedLiquidity0 > expectedLiquidity1 ? expectedLiquidity1 : expectedLiquidity0;

    uint256 liquidity = addLiquidity(add0, add1);
    assertEq(liquidity, expectedLiquidity);

    (uint112 updatedReserve0, uint112 updatedReserve1,) = pair.getReserves();
    assertEq(updatedReserve0, init0 + add0);
    assertEq(updatedReserve1, init1 + add1);
  }

  function testFuzzMint(uint256 amount0, uint256 amount1) public {
    amount0 = bound(amount0, 1e6, 1000 ether);
    amount1 = bound(amount1, 1e6, 2000 ether);

    // Test for ZeroLiquidity revert condition
    // if (amount0 == 0 || amount1 == 0) {
    //   vm.expectRevert(IPair.ZeroLiquidity.selector);
    //   addLiquidity(amount0, amount1);
    //   return;
    // }

    uint256 liquidity = addLiquidity(amount0, amount1);
    assertGt(liquidity, 0, "Liquidity should be greater than zero");

    uint256 totalSupply = pair.totalSupply();
    assertEq(
      totalSupply, liquidity + pair.MINIMUM_LIQUIDITY(), "Total supply should equal liquidity plus MINIMUM_LIQUIDITY"
    );

    (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
    assertEq(reserve0, amount0, "Reserve0 should equal amount0");
    assertEq(reserve1, amount1, "Reserve1 should equal amount1");

    uint256 k = uint256(reserve0) * reserve1;
    assertGe(k, uint256(amount0) * amount1, "K value should be maintained or increased");
  }


  function addLiquidity(uint256 amount0, uint256 amount1) internal returns (uint256) {
    token0.mint(address(pair), amount0);
    token1.mint(address(pair), amount1);

    vm.expectEmit(address(pair));
    emit IPair.Mint(address(this), amount0, amount1);

    return pair.mint(address(this));
  }
}
