// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

contract UniswapPair {
    address public factory;
    address public token0;
    address public token1;

    uint112 private reserve0;
    uint112 private reserve1;
    uint32 private blockTimestampLast;

    uint256 private price0CumulativeLast;
    uint256 private price1CumulativeLast;
    uint256 private kLast; // reserve0 * reserve1

    error Unauthorized();

    function getReserves()
        public
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        )
    {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    constructor() {
        factory = msg.sender;
    }

    function initialize(address _tokenA, address _tokenB) external {
        if (msg.sender != factory) revert Unauthorized();
        token0 = _tokenA;
        token1 = _tokenB;
    }

    function _update(uint112 _reserve0, uint112 reserve1) private {}

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to
    ) external {}
}
