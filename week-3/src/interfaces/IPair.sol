// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

/// @title IPair Interface
/// @notice Interface for the Pair contract in a decentralized exchange
interface IPair {
  /// @notice Thrown when an unauthorized address attempts to initialize
  error Unauthorized();

  /// @notice Thrown when there's not enough liquidity for an operation
  error InsufficientLiquidity();

  /// @notice Thrown when an attempt to add zero liquidity
  error ZeroLiquidity();

  /// @notice Thrown when an invalid address is provided as the recipient
  error InvalidToAddress();

  /// @notice Thrown when a zero amount is provided for an operation
  error ZeroAmount();

  /// @notice Thrown when the K value is insufficient after an operation
  error InsufficientKValue();

  /// @notice Thrown when an unsupported token is used for borrowing in a flash loan
  /// @param token The address of the unsupported token
  error UnsupportedBorrowToken(address token);

  /// @notice Thrown when the flash loan callback fails
  error FlashloanCallbackFailed();

  /// @notice Thrown when an invalid amount is provided for a flash loan
  error FlashloanInvalidAmount();

  /// @notice Thrown when the flash loan repayment fails
  error FlashloanRepayFailed();

  /// @notice Emitted when a swap occurs
  /// @param sender The address initiating the swap
  /// @param amount0In The amount of token0 input
  /// @param amount1In The amount of token1 input
  /// @param amount0Out The amount of token0 output
  /// @param amount1Out The amount of token1 output
  /// @param to The recipient address of the swap
  event Swap(
    address indexed sender,
    uint256 amount0In,
    uint256 amount1In,
    uint256 amount0Out,
    uint256 amount1Out,
    address indexed to
  );

  /// @notice Emitted when liquidity is minted
  /// @param to The address receiving the minted liquidity tokens
  /// @param amount0 The amount of token0 added to the liquidity pool
  /// @param amount1 The amount of token1 added to the liquidity pool
  event Mint(address indexed to, uint256 amount0, uint256 amount1);

  /// @notice Emitted when liquidity is burned
  /// @param sender The address initiating the burn
  /// @param amount0 The amount of token0 removed from the liquidity pool
  /// @param amount1 The amount of token1 removed from the liquidity pool
  /// @param to The address receiving the tokens from the burned liquidity
  event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);

  /// @notice Emitted when a flash loan occurs
  /// @param receiver The address receiving the flash loan
  /// @param token The address of the borrowed token
  /// @param amount The amount borrowed
  /// @param fee The fee charged for the flash loan
  /// @param data Additional data passed to the flash loan
  event FlashLoan(address indexed receiver, address token, uint256 amount, uint256 fee, bytes data);

  function initialize(address tokenA, address tokenB) external;
  function mint(address to) external returns (uint256 liquidity);
  function burn(address to) external returns (uint256 amount0, uint256 amount1);
  function swap(uint256 amount0Out, uint256 amount1Out, address to) external;
  function sync() external;
  function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}
