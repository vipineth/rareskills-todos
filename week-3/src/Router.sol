// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {Library} from "./Library.sol";
import {SafeTransferLib} from "@solady/utils/SafeTransferLib.sol";
import {IPair} from "./interfaces/IPair.sol";

contract Router {
  address public immutable factory;
  address public immutable WETH;

  error ExpiredDeadline();
  error InsufficientOutputAmount();
  error ExcessiveInputAmount();

  constructor(address _factory, address _WETH) {
    factory = _factory;
    WETH = _WETH;
  }

  modifier ensure(uint256 deadline) {
    if (deadline < block.timestamp) revert ExpiredDeadline();
    _;
  }

  function _swap(uint256[] memory amounts, address[] calldata path, address to) private {
    for (uint256 i; i < path.length - 1; i++) {
      (address input, address output) = (path[i], path[i + 1]);
      (address token0,) = Library.sortTokens(input, output);
      uint256 amountOut = amounts[i + 1];
      (uint256 amount0Out, uint256 amount1Out) = input == token0 ? (uint256(0), amountOut) : (amountOut, uint256(0));
      address _to = i < path.length - 2 ? Library.pairFor(factory, output, path[i + 2]) : to;
      IPair(Library.pairFor(factory, input, output)).swap(amount0Out, amount1Out, _to);
    }
  }

  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external ensure(deadline) returns (uint256[] memory amounts) {
    amounts = Library.getAmountsOut(factory, amountIn, path);
    if (amounts[amounts.length - 1] < amountOutMin) revert InsufficientOutputAmount();

    SafeTransferLib.safeTransferFrom(path[0], msg.sender, Library.pairFor(factory, path[0], path[1]), amounts[0]);
    _swap(amounts, path, to);
  }

  function swapTokensForExactTokens(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external ensure(deadline) returns (uint256[] memory amounts) {
    amounts = Library.getAmountsIn(factory, amountOut, path);
    if (amounts[0] > amountInMax) revert ExcessiveInputAmount();
    SafeTransferLib.safeTransferFrom(path[0], msg.sender, Library.pairFor(factory, path[0], path[1]), amounts[0]);
    _swap(amounts, path, to);
  }
}
