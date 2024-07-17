// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {Count} from "../src/prime/Count.sol";
import {NFTEnumerable} from "../src/prime/NFTEnumerable.sol";

contract PrimeCountTest is Test {
    Count public countContract;
    NFTEnumerable public nftEnumerable;

    address public user1;
    address public user2;

    function setUp() public {
        nftEnumerable = new NFTEnumerable();
        countContract = new Count(address(nftEnumerable));

        user1 = vm.addr(1);
        user2 = vm.addr(2);

        nftEnumerable.mint(user1, 2);
        nftEnumerable.mint(user1, 3);
        nftEnumerable.mint(user1, 4);
        nftEnumerable.mint(user2, 5);
        nftEnumerable.mint(user2, 6);
        nftEnumerable.mint(user2, 7);
    }

    function test_CountPrimeTokens_User1() public view {
        uint256 primeCount = countContract.count(user1);
        assertEq(primeCount, 2);
    }

    function test_CountPrimeTokens_User2() public view {
        uint256 primeCount = countContract.count(user2);
        assertEq(primeCount, 2);
    }

    function test_CountPrimeTokens_NoPrimes() public {
        address user3 = address(0x789);
        nftEnumerable.mint(user3, 8);
        nftEnumerable.mint(user3, 9);

        uint256 primeCount = countContract.count(user3);
        assertEq(primeCount, 0);
    }

    function test_CountPrimeTokens_AllPrimes() public {
        address user4 = address(0xABC);
        nftEnumerable.mint(user4, 11);
        nftEnumerable.mint(user4, 13);
        nftEnumerable.mint(user4, 17);

        uint256 primeCount = countContract.count(user4);
        assertEq(primeCount, 3);
    }
}
