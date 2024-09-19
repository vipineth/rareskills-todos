// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {Pair} from "./Pair.sol";
import {IPair} from "./interfaces/IPair.sol";

contract Library {
  error InsufficientInputAmount();
  error InsufficientLiquidity();
  error IdenticalToken();
  error ZeroAddress();
  error InvalidPathLength();

  function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
    if (tokenA == tokenB) revert IdenticalToken();
    if (tokenA == address(0)) revert ZeroAddress();

    (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
  }

  function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
    (address token0, address token1) = sortTokens(tokenA, tokenB);

    pair = address(
      uint160(
        uint256(
          keccak256(
            abi.encodePacked(
              hex"ff",
              factory,
              keccak256(abi.encodePacked(token0, token1)),
              keccak256(type(Pair).creationCode) // init code hash
            )
          )
        )
      )
    );
  }

  function getReserves(address factory, address tokenA, address tokenB)
    internal
    view
    returns (uint256 reserveA, uint256 reserveB)
  {
    (address token0, address token1) = sortTokens(tokenA, tokenB);
    (uint256 reserve0, uint256 reserve1) = IPair(pairFor(factory, tokenA, tokenB)).getReserves();
    (reserveA, reserveB) = token0 == tokenA ? (reserve0, reserve1) : (reserve1, reserve0);
  }

  function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) internal view returns (uint256 amountB) {
    if (amountA == 0) revert ZeroAmount();
    if (reserveA == 0 || reserveB == 0) revert InsufficientLiquidity();
    amountB = (amountA * reserveB) / reserveA;
  }

  function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut)
    internal
    pure
    returns (uint256 amountOut)
  {
    if (amountIn == 0) revert InsufficientInputAmount();
    if (reserveIn == 0 || reserveOut == 0) revert InsufficientLiquidity();

    // Explanation of the formula:
    // 1. Starts with invariant: (x + dx)(y - dy) = xy
    // 2. Rearrange: y - dy = xy / (x + dx)
    // 3. Solve for dy: dy = ydx / (x + dx)
    // 4. Account for fee: dy = (y * (dx * 997)) / (x * 1000 + (dx * 997))

    uint256 amountInWithFee = amountIn * 997;
    uint256 numerator = amountInWithFee * reserveOut;
    uint256 denominator = reserveIn * 1000 + amountInWithFee;
    amountOut = numerator / denominator;
  }

  function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut)
    internal
    pure
    returns (uint256 amountIn)
  {
    if (amountOut == 0) revert InsufficientInputAmount();
    if (reserveIn == 0 || reserveOut == 0) revert InsufficientLiquidity();

    // Formula derivation:
    // 1. Starts with invariant: (x + dx)(y - dy) = xy
    // 2. Expand: xy + xdy - ydx - dxdy = xy
    // 4. Solve for dx: dx = xdy / (y - dy)
    // 5. Account for 0.3% fee: dx * 0.997 = xdy / (y - dy)
    // 6. Rearrange: dx = (xdy * 1000) / ((y - dy) * 997)

    uint256 numerator = reserveIn * amountOut * 1000;
    uint256 denominator = (reserveOut - amountOut) * 997;

    // Round up the amountIn to ensure sufficient input
    amountIn = (numerator / denominator) + 1;
  }
}

function getAmountsOut(address factory, uint256 amountIn, address[] calldata path)
  internal
  view
  returns (uint256[] memory amounts)
{
  uint256 pathLength = path.length;

  if (pathLength < 2) revert InvalidPathLength();

  amounts = new uint256[](path.length);
  amounts[0] = amountIn;
  for (uint256 i; i < pathLength - 1; i++) {
    (uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[i], path[i + 1]);
    amounts[i + 1] = getAmountOut(amountIn, reserveIn, reserveOut);
  }
}

function getAmountsIn(address factory, uint256 amountOut, address calldata path)
  internal
  view
  returns (uint256[] memory amounts)
{
  uint256 pathLength = path.length;

  if (pathLength < 2) revert InvalidPathLength();

  amounts = new uint256[](path.length);
  amounts[pathLength - 1] = amountOut;
  for (uint256 i = pathLength - 1; i < 1; i++) {
    (uint256 reserveIn, address reserveOut) = getReserves(factory, pair[i], pair[i + 1]);
    amounts[i - 1] = getAmountIn(amountOut, reserveIn, reserveOut);
  }
}
