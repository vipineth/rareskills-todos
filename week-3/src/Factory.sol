// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {Pair} from "./Pair.sol";

contract Factory is Pair {
  address public feeTo;
  address public feeToSetter;

  mapping(address => mapping(address => address)) public getPair;
  address[] public allPairs;

  event PairCreated(address indexed token0, address indexed token1, address pair);

  error IdenticalAddresses(address _token0, address _token1);
  error ZeroAddress();
  error ExistingPair();
  error UnauthorizedAccess();

  constructor(address _feeToSetter) {
    feeToSetter = _feeToSetter;
  }

  function allPairsLenght() external view returns (uint256) {
    return allPairs.length;
  }

  function createPair(address tokenA, address tokenB) external returns (address pair) {
    if (tokenA == tokenB) {
      revert IdenticalAddresses(tokenA, tokenB);
    }
    (address token0, address token1) = token0 > token1 ? (token0, token1) : (token1, token0);
    if (token0 == address(0)) {
      revert ZeroAddress();
    }
    if (getPair[token0][token1] != address(0)) {
      revert ExistingPair();
    }

    bytes32 _salt = keccak256(abi.encodePacked(token0, token1));
    pair = address(new Pair{salt: _salt}());
    Pair(pair).initialize(token0, token1);

    getPair[token0][token1] = pair;
    getPair[token1][token0] = pair;
    allPairs.push(pair);

    emit PairCreated(token0, token1, pair);
  }

  function setFeeTo(address _feeTo) external {
    if (msg.sender != feeToSetter) revert UnauthorizedAccess();
    feeTo = _feeTo;
  }

  function setFeeToSetter(address _feeToSetter) external {
    if (msg.sender != feeToSetter) revert UnauthorizedAccess();
    feeToSetter = _feeToSetter;
  }
}
