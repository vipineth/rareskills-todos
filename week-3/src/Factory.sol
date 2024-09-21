// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.27;

import {Pair} from "./Pair.sol";

/// @title Factory contract for creating and managing token pairs
/// @notice This contract allows creation of new token pairs and manages fees
contract Factory is Pair {
  address public feeTo;
  address public feeToSetter;

  mapping(address token0 => mapping(address token1 => address pair)) public getPair;
  uint256 public pairCount;

  event PairCreated(address indexed token0, address indexed token1, address pair);

  error IdenticalAddresses(address token0, address token1);
  error ZeroAddress();
  error ExistingPair();
  error UnauthorizedAccess();

  constructor(address _feeToSetter) {
    feeToSetter = _feeToSetter;
  }

  /// @notice Creates a new pair for two tokens
  /// @param tokenA The address of the first token
  /// @param tokenB The address of the second token
  /// @return pair The address of the newly created pair
  function createPair(address tokenA, address tokenB) external returns (address pair) {
    if (tokenA == tokenB) {
      revert IdenticalAddresses(tokenA, tokenB);
    }
    (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    if (token0 == address(0)) {
      revert ZeroAddress();
    }
    if (getPair[token0][token1] != address(0)) {
      revert ExistingPair();
    }

    bytes32 salt = keccak256(abi.encodePacked(token0, token1));
    pair = address(new Pair{salt: salt}());
    Pair(pair).initialize(token0, token1);

    getPair[token0][token1] = pair;
    getPair[token1][token0] = pair;
    pairCount++;

    emit PairCreated(token0, token1, pair);
  }

  /// @notice Sets the fee recipient address
  /// @param _feeTo The new fee recipient address
  function setFeeTo(address _feeTo) external {
    if (msg.sender != feeToSetter) revert UnauthorizedAccess();
    feeTo = _feeTo;
  }

  /// @notice Sets the fee setter address
  /// @param _feeToSetter The new fee setter address
  function setFeeToSetter(address _feeToSetter) external {
    if (msg.sender != feeToSetter) revert UnauthorizedAccess();
    feeToSetter = _feeToSetter;
  }
}
