// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {Library} from "./Library.sol";
import {SafeTransferLib} from "@solady/utils/SafeTransferLib.sol";
import {IPair} from "./interfaces/IPair.sol";
import {Factory} from "./Factory.sol";
import {IWETH} from "./interfaces/IWETH.sol";

contract Router {
  address public immutable factory;
  address public immutable WETH;

  error ExpiredDeadline();
  error InsufficientOutputAmount();
  error ExcessiveInputAmount();
  error InsufficientAmount();

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
    if (amounts[amounts.length - 1] < amountOutMin) {
      revert InsufficientOutputAmount();
    }

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

  function _addLiquidity(
    address tokenA,
    address tokenB,
    uint256 amountADesired,
    uint256 amountBDesired,
    uint256 amountAMin,
    uint256 amountBMin
  ) private returns (uint256 amountA, uint256 amountB) {
    if (Factory(factory).getPair(tokenA, tokenB) == address(0)) {
      Factory(factory).createPair(tokenA, tokenB);
    }
    (uint256 reserveA, uint256 reserveB) = Library.getReserves(factory, tokenA, tokenB);
    if (reserveA == 0 && reserveB == 0) {
      (amountA, amountB) = (amountADesired, amountBDesired);
    } else {
      uint256 amountBOptimal = Library.quote(amountADesired, reserveA, reserveB);
      if (amountBOptimal <= amountBDesired) {
        if (amountBOptimal < amountBMin) revert InsufficientAmount();
        (amountA, amountB) = (amountADesired, amountBOptimal);
      } else {
        uint256 amountAOptimal = Library.quote(amountBDesired, reserveB, reserveA);
        assert(amountAOptimal <= amountADesired);
        if (amountAOptimal < amountAMin) revert InsufficientAmount();
        (amountA, amountB) = (amountAOptimal, amountBDesired);
      }
    }
  }

  function addLiquidity(
    address tokenA,
    address tokenB,
    uint256 amountADesired,
    uint256 amountBDesired,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  ) external ensure(deadline) returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
    (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
    address pair = Library.pairFor(factory, tokenA, tokenB);
    SafeTransferLib.safeTransferFrom(tokenA, msg.sender, pair, amountA);
    SafeTransferLib.safeTransferFrom(tokenB, msg.sender, pair, amountB);
    liquidity = IPair(pair).mint(to);
  }

  function addLiquidityETH(
    address token,
    uint256 amountTokenDesired,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external payable ensure(deadline) returns (uint256 amountToken, uint256 amountETH, uint256 liquidity) {
    (amountToken, amountETH) = _addLiquidity(token, WETH, amountTokenDesired, msg.value, amountTokenMin, amountETHMin);
    address pair = Library.pairFor(factory, token, WETH);
    SafeTransferLib.safeTransferFrom(token, msg.sender, pair, amountToken);
    IWETH(WETH).deposit{value: amountETH}();
    assert(IWETH(WETH).transfer(pair, amountETH));
    liquidity = IPair(pair).mint(to);
    if (msg.value > amountETH) {
      SafeTransferLib.safeTransferETH(msg.sender, msg.value - amountETH);
    }
  }
}
