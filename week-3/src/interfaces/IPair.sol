// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {ERC20} from "@solady/tokens/ERC20.sol";

/// @title IPair Interface
/// @notice Interface for the Pair contract in a decentralized exchange
interface IPair is ERC20 {
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

  /// @notice The minimum liquidity required
  function MINIMUM_LIQUIDITY() external pure returns (uint256);

  /// @notice The factory address that created this pair
  function factory() external view returns (address);

  /// @notice The address of the first token in the pair
  function token0() external view returns (address);

  /// @notice The address of the second token in the pair
  function token1() external view returns (address);

  /// @notice The cumulative price of token0, used for TWAP calculations
  function price0CumulativeLast() external view returns (uint256);

  /// @notice The cumulative price of token1, used for TWAP calculations
  function price1CumulativeLast() external view returns (uint256);

  /// @notice The product of the reserves, used for collecting fees
  function kLast() external view returns (uint256);

  /// @notice Initializes the pair with two tokens
  /// @param tokenA The address of the first token
  /// @param tokenB The address of the second token
  function initialize(address tokenA, address tokenB) external;

  /// @notice Mints liquidity tokens
  /// @param to The address to receive the minted liquidity tokens
  /// @return liquidity The amount of liquidity tokens minted
  function mint(address to) external returns (uint256 liquidity);

  /// @notice Burns liquidity tokens
  /// @param to The address to receive the underlying assets
  /// @return amount0 The amount of token0 sent to the recipient
  /// @return amount1 The amount of token1 sent to the recipient
  function burn(address to) external returns (uint256 amount0, uint256 amount1);

  /// @notice Swaps tokens
  /// @param amount0Out The amount of token0 to receive
  /// @param amount1Out The amount of token1 to receive
  /// @param to The recipient of the swap
  function swap(uint256 amount0Out, uint256 amount1Out, address to) external;

  /// @notice Syncs the current balances to the reserves
  function sync() external;

  // Flash Loan Functions
  /// @notice Returns the maximum flash loan amount for a given token
  /// @param token The address of the token
  /// @return The maximum flash loan amount
  function maxFlashLoan(address token) external view returns (uint256);

  /// @notice Calculates the fee for a flash loan
  /// @param token The address of the token to be borrowed
  /// @param amount The amount to be borrowed
  /// @return The fee for the flash loan
  function flashFee(address token, uint256 amount) external view returns (uint256);

  /// @notice Initiates a flash loan
  /// @param receiver The contract receiving the tokens, needs to implement the IERC3156FlashBorrower interface
  /// @param token The loan currency
  /// @param amount The amount of tokens lent
  /// @param data Arbitrary data structure, intended to contain user-defined parameters
  /// @return true if the flash loan was successful
  function flashLoan(IERC3156FlashBorrower receiver, address token, uint256 amount, bytes calldata data)
    external
    returns (bool);

  /// @notice Returns the current reserves and the last block timestamp
  /// @return reserve0 The current reserve of token0
  /// @return reserve1 The current reserve of token1
  /// @return blockTimestampLast The timestamp of the last block in which an interaction occurred
  function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}
