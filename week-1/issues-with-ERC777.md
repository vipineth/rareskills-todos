# Problems with ERC777

- Over-engineering: ERC777 is considered to be over-engineered, which makes it complex and difficult to understand. The complexity can lead to errors and security vulnerabilities.

- Delegated transfers: ERC777 introduces a infinite approve behavior, which can be a significant security risk.

- Reentrancy: ERC777 can cause reentrancy while using `send` or `operatorSend`method which calls `_callTokensReceived` function after the token is sent. This can lead to reentrancy vulnerability. The `_callTokensReceived` function is not inherently bad or wrong, but it can be misused. 

- ERC777Receiver: There are many possible ways to abuse ERC777Receiver. The only way to solve it is to work with whitelisted tokens only, which is not a good approach for DeFi.


