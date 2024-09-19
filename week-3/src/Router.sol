// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {Library} from "./Library.sol";

contract Router {
  address public immutable factory;
  address public immutable WETH;

  error ExpiredDeadline();

  constructor(address _factory, address _WETH) {
    factory = _factory;
    WETH = _WETH;
  }

  modifier ensure(uint256 deadline) {
    if (deadline < block.timestamp) revert ExpiredDeadline();
    _;
  }

  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deaadline
  ) external ensure(deaadline) returns (uint256[] memory amounts) {
    // amounts = Library.getAmountsOut()
  }

  function swapTokensForExactTokens() external returns (uint256[] memory amounts) {}
}
