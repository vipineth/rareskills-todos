// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {Pair} from "./Pair.sol";
import {IPair} from "./interfaces/IPair.sol";

/// @title Library for AMM operations
/// @notice Provides utility functions for token swaps and liquidity calculations
/// @dev This contract is meant to be used as a library and should not be deployed independently
library Library {
  /// @notice Thrown when the input amount is insufficient for the operation
  error InsufficientInputAmount();
  /// @notice Thrown when there's not enough liquidity for the operation
  error InsufficientLiquidity();
  /// @notice Thrown when trying to operate on identical tokens
  error IdenticalToken();
  /// @notice Thrown when a zero address is provided where a valid address is required
  error ZeroAddress();
  /// @notice Thrown when a zero amount is provided
  error ZeroAmount();
  /// @notice Thrown when the provided path length is invalid
  error InvalidPathLength();

  /// @notice Sorts two token addresses
  /// @param tokenA The address of the first token
  /// @param tokenB The address of the second token
  /// @return token0 The address of the token that comes first in sort order
  /// @return token1 The address of the token that comes second in sort order
  function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
    if (tokenA == tokenB) revert IdenticalToken();
    if (tokenA == address(0)) revert ZeroAddress();

    (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
  }

  /// @notice Calculates the address of a pair contract
  /// @param factory The address of the factory contract
  /// @param tokenA The address of the first token in the pair
  /// @param tokenB The address of the second token in the pair
  /// @return pair The calculated address of the pair contract
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

  /// @notice Fetches the reserves for a pair of tokens
  /// @param factory The address of the factory contract
  /// @param tokenA The address of the first token
  /// @param tokenB The address of the second token
  /// @return reserveA The reserve of tokenA
  /// @return reserveB The reserve of tokenB
  function getReserves(address factory, address tokenA, address tokenB)
    internal
    view
    returns (uint256 reserveA, uint256 reserveB)
  {
    (address token0,) = sortTokens(tokenA, tokenB);
    (uint256 reserve0, uint256 reserve1,) = IPair(pairFor(factory, tokenA, tokenB)).getReserves();
    (reserveA, reserveB) = token0 == tokenA ? (reserve0, reserve1) : (reserve1, reserve0);
  }

  /// @notice Calculates the amount of tokenB equivalent to a given amount of tokenA
  /// @param amountA The amount of tokenA
  /// @param reserveA The reserve of tokenA
  /// @param reserveB The reserve of tokenB
  /// @return amountB The equivalent amount of tokenB
  function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) internal pure returns (uint256 amountB) {
    if (amountA == 0) revert ZeroAmount();
    if (reserveA == 0 || reserveB == 0) revert InsufficientLiquidity();
    amountB = (amountA * reserveB) / reserveA;
  }

  /// @notice Calculates the output amount for a swap
  /// @param amountIn The input amount
  /// @param reserveIn The reserve of the input token
  /// @param reserveOut The reserve of the output token
  /// @return amountOut The calculated output amount
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

  /// @notice Calculates the input amount required for a desired output amount
  /// @param amountOut The desired output amount
  /// @param reserveIn The reserve of the input token
  /// @param reserveOut The reserve of the output token
  /// @return amountIn The calculated required input amount
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
  /// @notice Calculates the amounts out for a given input amount along a path of token pairs
  /// @param factory The address of the factory contract
  /// @param amountIn The input amount
  /// @param path An array of token addresses representing the path
  /// @return amounts An array of amounts out for each step in the path

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

  /// @notice Calculates the amounts in required for a desired output amount along a path of token pairs
  /// @param factory The address of the factory contract
  /// @param amountOut The desired output amount
  /// @param path An array of token addresses representing the path
  /// @return amounts An array of amounts in required for each step in the path
  function getAmountsIn(address factory, uint256 amountOut, address[] calldata path)
    internal
    view
    returns (uint256[] memory amounts)
  {
    uint256 pathLength = path.length;

    if (pathLength < 2) revert InvalidPathLength();

    amounts = new uint256[](path.length);
    amounts[pathLength - 1] = amountOut;
    for (uint256 i = pathLength - 1; i > 0; i--) {
      (uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[i - 1], path[i]);
      amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
    }
  }
}
