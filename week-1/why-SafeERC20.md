# Why SafeERC20 exists?

SafeERC20 is a wrapper around the ERC20 standard which provides a set of functions that allow for safe interactions with standard and non-standard ERC20 tokens.

- It helps to make sure that transaction reverts when the ERC20 method returns `false`. If `token` returns no value, non-reverting calls are assumed to be successful. So this makes sure to work with both standard and no-standard ERC20 tokens.

- The `safeIncreaseAllowance` and `safeDecreaseAllowance` functions ensure that the change in allowance is safe.

- The `forceApprove` function is designed for tokens that require the approval to be set to zero before setting it to a non-zero value, such as USDT. It handles this process in a safe manner, ensuring that the approval is set successfully.

- `transferAndCallRelaxed` function provides a safe and flexible way to handle ERC1363 transfers and approvals
