// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {ERC20} from "solady/tokens/ERC20.sol";
import {FixedPointMathLib} from "solady/utils/FixedPointMathLib.sol";
import {ReentrancyGuard} from "solady/utils/ReentrancyGuard.sol";

contract Pair is ERC20, ReentrancyGuard {
  uint256 public constant MINIMUM_LIQUIDITY = 10 ** 3;
  bytes4 private constant TRANSFER_SELECTOR = bytes4(keccak256(bytes("transfer(address,uint256)")));

  address public factory;
  address public token0;
  address public token1;

  uint112 private reserve0;
  uint112 private reserve1;
  uint32 private blockTimestampLast;

  uint256 private price0CumulativeLast;
  uint256 private price1CumulativeLast;
  uint256 private kLast; // reserve0 * reserve1

  event Swap(
    address indexed sender,
    uint256 amount0In,
    uint256 amount1In,
    uint256 amount0Out,
    uint256 amount1Out,
    address indexed to
  );
  event Mint(address indexed to, uint256 amount0, uint256 amount1);
  event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);

  error Unauthorized();
  error InsufficientAmount();
  error InsufficientLiquidity();
  error InvalidToAddress();
  error TransferFailed();
  error ZeroInputAmount();
  error InsufficientKValue();

  function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
    _reserve0 = reserve0;
    _reserve1 = reserve1;
    _blockTimestampLast = blockTimestampLast;
  }

  function _safeTransfer(address token, address to, uint256 amount) private {
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(TRANSFER_SELECTOR, to, amount));
    // handling for tokens that doesn't return on transfer like USDT
    if (!success || (data.length != 0 && !abi.decode(data, (bool)))) {
      revert TransferFailed();
    }
  }

  constructor() {
    factory = msg.sender;
  }

  function name() public pure override returns (string memory) {
    return "Swap LP";
  }

  function symbol() public pure override returns (string memory) {
    return "SLP";
  }

  function initialize(address _tokenA, address _tokenB) external {
    if (msg.sender != factory) revert Unauthorized();
    token0 = _tokenA;
    token1 = _tokenB;
  }

  function _update(uint256 balance0, uint256 balance1, uint112 _reserve0, uint112 _reserve1) private {
    // will calculate the twap time
    uint32 blockTimestamp = uint32(block.timestamp % 2 ** 32);
    uint32 timeElapsed = blockTimestamp - blockTimestampLast;

    if(timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
      unchecked {
        price0CumulativeLast += uint(timeElapsed * FixedPointMathLib.divWad(_reserve1, _reserve0));
        price1CumulativeLast += uint(timeElapsed * FixedPointMathLib.divWad(_reserve0, _reserve1));
      }
    }

    reserve0 = uint112(balance0);
    reserve1 = uint112(balance1);
    blockTimestampLast = blockTimestamp;
  }

  function mint(address to) external nonReentrant returns (uint256 liquidity) {
    (uint112 _reserve0, uint112 _reserve1,) = getReserves();

    uint256 balance0 = ERC20(token0).balanceOf(address(this));
    uint256 balance1 = ERC20(token1).balanceOf(address(this));

    uint256 amount0 = balance0 - _reserve0;
    uint256 amount1 = balance1 - _reserve1;

    uint256 _totalSupply = totalSupply();

    if (_totalSupply == 0) {
      liquidity = FixedPointMathLib.sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
      _mint(address(0), MINIMUM_LIQUIDITY);
    } else {
      // s = dx * totalSupply / reserve0 or dy * totalSupply / reserve1 (s is the liquidity)
      uint256 liquidity0 = (amount0 * _totalSupply) / _reserve0;
      uint256 liquidity1 = (amount1 * _totalSupply) / _reserve0;
      liquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
    }

    if (liquidity == 0) {
      revert InsufficientLiquidity();
    }

    _mint(to, liquidity);

    _update(balance0, balance1, _reserve0, _reserve1);
    emit Mint(msg.sender, amount0, amount1);
  }

  function burn(address to) external nonReentrant returns (uint256 amount0, uint256 amount1) {
    (uint112 _reserve0, uint112 _reserve1,) = getReserves();
    address _token0 = token0;
    address _token1 = token1;

    uint256 balance0 = ERC20(_token0).balanceOf(address(this));
    uint256 balance1 = ERC20(_token1).balanceOf(address(this));

    uint256 liquidity = balanceOf(address(this));

    uint256 _totalSupply = totalSupply();
    // dx = s * dx/x0 and dy = s * dy/y0 (s is the liquidity)
    amount0 = (liquidity * balance0) / _totalSupply;
    amount1 = (liquidity * balance1) / _totalSupply;

    if (amount0 == 0 || amount1 == 0) {
      revert InsufficientAmount();
    }

    _burn(address(this), liquidity);
    _safeTransfer(_token0, to, amount0);
    _safeTransfer(_token1, to, amount1);

    balance0 = ERC20(_token0).balanceOf(address(this));
    balance1 = ERC20(_token1).balanceOf(address(this));

    _update(balance0, balance1, _reserve0, _reserve1);
    emit Burn(msg.sender, amount0, amount1, to);
  }

  function swap(uint256 amount0Out, uint256 amount1Out, address to) external nonReentrant {
    if (amount0Out == 0 && amount1Out == 0) {
      revert InsufficientAmount();
    }
    (uint112 _reserve0, uint112 _reserve1,) = getReserves();
    if (amount0Out > _reserve0 || amount1Out > _reserve1) {
      revert InsufficientLiquidity();
    }
    uint256 balance0;
    uint256 balance1;

    {
      address _token0 = token0;
      address _token1 = token1;

      if (to == _token0 || to == _token1) {
        revert InvalidToAddress();
      }

      if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out);
      if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out);

      balance0 = ERC20(token0).balanceOf(address(this));
      balance1 = ERC20(token1).balanceOf(address(this));
    }

    uint256 amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
    uint256 amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;

    if (amount0In == 0 && amount1In == 0) {
      revert ZeroInputAmount();
    }
    // swap dx for dy => make sure (x0 + dx*(1-fee))(y0 - dy) >= x0y0
    {
      // balance0 - fee(3%) => balance0 - (amount0In*3/1000)
      uint256 balance0Adjusted = balance0 * 1000 - (amount0In * 3);
      uint256 balance1Adjusted = balance1 * 1000 - (amount1In * 3);
      if (balance0Adjusted * balance1Adjusted < uint256(_reserve0) * _reserve1 * (1000 ** 2)) {
        revert InsufficientKValue();
      }
    }
    _update(balance0, balance1, _reserve0, _reserve1);
    emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
  }
}
