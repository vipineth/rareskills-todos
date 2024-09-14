// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

contract Router {
  function removeLiquidity() external {}

  function addLiquidity(
    address tokenA,
    address tokenB,
    uint256 amountADesired,
    uint256 amountBDesired,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  ) external virtual returns (uint256 amountA, uint256 amountB, uint256 liquidity) {}
}
