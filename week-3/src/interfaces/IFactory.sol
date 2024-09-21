// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.27;

/// @title IFactory
/// @notice Interface for the Factory contract
interface IFactory {
  /// @notice Emitted when a new pair is created
  /// @param token0 The address of the first token in the pair
  /// @param token1 The address of the second token in the pair
  /// @param pair The address of the newly created pair
  event PairCreated(address indexed token0, address indexed token1, address pair);

  /// @notice Thrown when trying to create a pair with identical addresses
  /// @param _token0 The address of the first token
  /// @param _token1 The address of the second token
  error IdenticalAddresses(address _token0, address _token1);

  /// @notice Thrown when trying to use the zero address
  error ZeroAddress();

  /// @notice Thrown when trying to create a pair that already exists
  error ExistingPair();

  /// @notice Thrown when an unauthorized address tries to perform an action
  error UnauthorizedAccess();

  // External Functions

  /// @notice Address where fees are sent
  function feeTo() external view returns (address);

  /// @notice Address that can change the fee recipient
  function feeToSetter() external view returns (address);

  /// @notice Get the address of a pair for two tokens
  /// @param tokenA The address of the first token
  /// @param tokenB The address of the second token
  /// @return pair The address of the pair
  function getPair(address tokenA, address tokenB) external view returns (address pair);

  /// @notice Get a pair address by index
  /// @param index The index of the pair
  /// @return The address of the pair at the given index
  function allPairs(uint256 index) external view returns (address);

  /// @notice Get the total number of pairs
  /// @return The length of the allPairs array
  function allPairsLength() external view returns (uint256);

  /// @notice Create a new pair
  /// @param tokenA The address of the first token
  /// @param tokenB The address of the second token
  /// @return pair The address of the newly created pair
  function createPair(address tokenA, address tokenB) external returns (address pair);

  /// @notice Set the fee recipient address
  /// @param _feeTo The new fee recipient address
  function setFeeTo(address _feeTo) external;

  /// @notice Set the address that can change the fee recipient
  /// @param _feeToSetter The new address that can set the fee recipient
  function setFeeToSetter(address _feeToSetter) external;
}
