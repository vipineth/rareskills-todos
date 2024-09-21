// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.27;

/// @title IRouter
/// @notice Interface for the Router contract
interface IRouter {
    /// @notice Returns the factory address
    function factory() external view returns (address);

    /// @notice Returns the WETH address
    function WETH() external view returns (address);

    /// @notice Swaps an exact amount of input tokens for as many output tokens as possible
    /// @param amountIn The amount of input tokens to send
    /// @param amountOutMin The minimum amount of output tokens that must be received
    /// @param path An array of token addresses. path.length must be >= 2
    /// @param to Recipient of the output tokens
    /// @param deadline Unix timestamp after which the transaction will revert
    /// @return amounts The input token amount and all subsequent output token amounts
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    /// @notice Receive an exact amount of output tokens for as few input tokens as possible
    /// @param amountOut The amount of output tokens to receive
    /// @param amountInMax The maximum amount of input tokens that can be required
    /// @param path An array of token addresses. path.length must be >= 2
    /// @param to Recipient of the output tokens
    /// @param deadline Unix timestamp after which the transaction will revert
    /// @return amounts The input token amount and all subsequent output token amounts
    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    /// @notice Add liquidity to a ERC20⇄ERC20 pool
    /// @param tokenA The contract address of the first token
    /// @param tokenB The contract address of the second token
    /// @param amountADesired The amount of tokenA to add as liquidity
    /// @param amountBDesired The amount of tokenB to add as liquidity
    /// @param amountAMin Bounds the extent to which the B/A price can go up before the transaction reverts
    /// @param amountBMin Bounds the extent to which the A/B price can go up before the transaction reverts
    /// @param to Recipient of the liquidity tokens
    /// @param deadline Unix timestamp after which the transaction will revert
    /// @return amountA The amount of tokenA sent to the pool
    /// @return amountB The amount of tokenB sent to the pool
    /// @return liquidity The amount of liquidity tokens minted
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    /// @notice Add liquidity to a ERC20⇄WETH pool with ETH
    /// @param token The contract address of the token
    /// @param amountTokenDesired The amount of token to add as liquidity
    /// @param amountTokenMin Bounds the extent to which the WETH/token price can go up before the transaction reverts
    /// @param amountETHMin Bounds the extent to which the token/WETH price can go up before the transaction reverts
    /// @param to Recipient of the liquidity tokens
    /// @param deadline Unix timestamp after which the transaction will revert
    /// @return amountToken The amount of token sent to the pool
    /// @return amountETH The amount of ETH converted to WETH and sent to the pool
    /// @return liquidity The amount of liquidity tokens minted
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    /// @notice Remove liquidity from a ERC20⇄ERC20 pool
    /// @param tokenA The contract address of the first token
    /// @param tokenB The contract address of the second token
    /// @param liquidity The amount of liquidity tokens to remove
    /// @param amountAMin The minimum amount of tokenA that must be received for the transaction not to revert
    /// @param amountBMin The minimum amount of tokenB that must be received for the transaction not to revert
    /// @param to Recipient of the underlying assets
    /// @param deadline Unix timestamp after which the transaction will revert
    /// @return amountA The amount of tokenA received
    /// @return amountB The amount of tokenB received
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    /// @notice Remove liquidity from a ERC20⇄WETH pool and receive ETH
    /// @param token The contract address of the token
    /// @param liquidity The amount of liquidity tokens to remove
    /// @param amountTokenMin The minimum amount of token that must be received for the transaction not to revert
    /// @param amountETHMin The minimum amount of ETH that must be received for the transaction not to revert
    /// @param to Recipient of the underlying assets
    /// @param deadline Unix timestamp after which the transaction will revert
    /// @return amountToken The amount of token received
    /// @return amountETH The amount of ETH received
    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    /// @notice Remove liquidity from a ERC20⇄ERC20 pool with permit
    /// @param tokenA The contract address of the first token
    /// @param tokenB The contract address of the second token
    /// @param liquidity The amount of liquidity tokens to remove
    /// @param amountAMin The minimum amount of tokenA that must be received for the transaction not to revert
    /// @param amountBMin The minimum amount of tokenB that must be received for the transaction not to revert
    /// @param to Recipient of the underlying assets
    /// @param deadline Unix timestamp after which the transaction will revert
    /// @param approveMax Whether or not the approval amount in the signature is for liquidity or uint(-1)
    /// @param v The v component of the permit signature
    /// @param r The r component of the permit signature
    /// @param s The s component of the permit signature
    /// @return amountA The amount of tokenA received
    /// @return amountB The amount of tokenB received
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    /// @notice Remove liquidity from a ERC20⇄WETH pool with permit and receive ETH
    /// @param token The contract address of the token
    /// @param liquidity The amount of liquidity tokens to remove
    /// @param amountTokenMin The minimum amount of token that must be received for the transaction not to revert
    /// @param amountETHMin The minimum amount of ETH that must be received for the transaction not to revert
    /// @param to Recipient of the underlying assets
    /// @param deadline Unix timestamp after which the transaction will revert
    /// @param approveMax Whether or not the approval amount in the signature is for liquidity or uint(-1)
    /// @param v The v component of the permit signature
    /// @param r The r component of the permit signature
    /// @param s The s component of the permit signature
    /// @return amountToken The amount of token received
    /// @return amountETH The amount of ETH received
    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);
}