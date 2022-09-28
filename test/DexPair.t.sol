// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Test.sol";
import "../lib/forge-std/src/console2.sol";
import "../src/ERC20Mintable.sol";
import "../src/DexPair.sol";

contract LPTokenTest is Test {
    DexPair public dexPair;
    ERC20Mintable public coinX;
    ERC20Mintable public coinY;

    address internal constant alice = address(1);
    address internal constant bob = address(2);
    address internal constant carol = address(3);
    address internal constant dave = address(4);

    function setUp() public {
        coinX = new ERC20Mintable("Coin X", "COX");
        coinY = new ERC20Mintable("Coin Y", "COY");

        dexPair = new DexPair(address(coinX), address(coinY));
        
        coinX.mint(alice, 100 ether);
        coinY.mint(alice, 400 ether);

        coinX.mint(bob, 400 ether);
        coinY.mint(bob, 400 ether);

        coinX.mint(carol, 40 ether);
        coinY.mint(carol, 0 ether);

        coinX.mint(dave, 0 ether);
        coinY.mint(dave, 150 ether);
    }

    function testFirstAddLiquidity() public {
        vm.startPrank(alice);
        coinX.approve(address(dexPair), 100 ether);
        coinY.approve(address(dexPair), 400 ether);

        dexPair.addLiquidity(100 ether, 400 ether, 0);

        assertEq(dexPair.balanceOf(alice), 200 ether);
        assertEq(coinX.balanceOf(alice), 0);
        assertEq(coinY.balanceOf(alice), 0);
 
        assertEq(coinX.balanceOf(address(dexPair)), 100 ether);
        assertEq(coinY.balanceOf(address(dexPair)), 400 ether);
    }

    function testFailAddLiquidity() public {
        vm.startPrank(alice);
        coinX.approve(address(dexPair), 100 ether);
        coinY.approve(address(dexPair), 400 ether);

        dexPair.addLiquidity(100 ether, 400 ether, 500 ether);
    }

    function testMultiAddLiquidity() public {
        vm.startPrank(alice);
        coinX.approve(address(dexPair), 100 ether);
        coinY.approve(address(dexPair), 400 ether);

        dexPair.addLiquidity(100 ether, 400 ether, 0);
        vm.stopPrank();

        vm.startPrank(bob);
        coinX.approve(address(dexPair), 20 ether);
        coinY.approve(address(dexPair), 80 ether);

        dexPair.addLiquidity(20 ether, 80 ether, 0);
        vm.stopPrank();
    }

    function testRemoveLiquidity() public {
        testMultiAddLiquidity();

        vm.startPrank(alice);
        
        dexPair.removeLiquidity(200 ether, 100 ether, 400 ether);
        vm.stopPrank();

        assertEq(coinX.balanceOf(address(alice)) != 0, true);
        assertEq(coinY.balanceOf(address(alice)) != 0, true);
    }

    function testSwap1() public {
        vm.startPrank(alice);
        coinX.approve(address(dexPair), 100 ether);
        coinY.approve(address(dexPair), 400 ether);

        dexPair.addLiquidity(100 ether, 400 ether, 0);
        vm.stopPrank();

        uint beforeXCarol = coinX.balanceOf(address(carol));
        uint beforeYCarol = coinY.balanceOf(address(carol));
        
        uint beforeXDex = coinX.balanceOf(address(dexPair));
        uint beforeYDex = coinY.balanceOf(address(dexPair));

        vm.startPrank(carol);
        coinX.approve(address(dexPair), 20 ether);
        
        uint output = dexPair.swap(20 ether, 0, 20 ether);
        vm.stopPrank();

        assertEq(coinX.balanceOf(address(carol)), beforeXCarol - 20 ether);
        assertEq(coinY.balanceOf(address(carol)), beforeYCarol + output);

        assertEq(coinX.balanceOf(address(dexPair)), beforeXDex + 20 ether);
        assertEq(coinY.balanceOf(address(dexPair)), beforeYDex - output);
    }

    function testSwap2() public {
        vm.startPrank(alice);
        coinX.approve(address(dexPair), 100 ether);
        coinY.approve(address(dexPair), 400 ether);

        dexPair.addLiquidity(100 ether, 400 ether, 0);
        vm.stopPrank();

        uint beforeXDave = coinX.balanceOf(address(dave));
        uint beforeYDave = coinY.balanceOf(address(dave));
        
        uint beforeXDex = coinX.balanceOf(address(dexPair));
        uint beforeYDex = coinY.balanceOf(address(dexPair));


        vm.startPrank(dave);
        coinY.approve(address(dexPair), 100 ether);
        
        uint output = dexPair.swap(0 ether, 100 ether, 4 ether);
        vm.stopPrank();

        assertEq(coinX.balanceOf(address(dave)), beforeXDave + output);
        assertEq(coinY.balanceOf(address(dave)), beforeYDave - 100 ether);

        assertEq(coinX.balanceOf(address(dexPair)), beforeXDex - output);
        assertEq(coinY.balanceOf(address(dexPair)), beforeYDex + 100 ether);
    }

    function testFailSwap1() public {
        vm.startPrank(alice);
        coinX.approve(address(dexPair), 100 ether);
        coinY.approve(address(dexPair), 400 ether);

        dexPair.addLiquidity(100 ether, 400 ether, 0);
        vm.stopPrank();
        
        coinX.balanceOf(address(dexPair));

        vm.startPrank(carol);
        coinX.approve(address(dexPair), 22 ether);
        
        dexPair.swap(20 ether, 0, 100 ether);
        vm.stopPrank();
    }

    function testFailSwap2() public {
        vm.startPrank(alice);
        coinX.approve(address(dexPair), 100 ether);
        coinY.approve(address(dexPair), 400 ether);

        dexPair.addLiquidity(100 ether, 400 ether, 0);
        vm.stopPrank();
        
        coinX.balanceOf(address(dexPair));

        vm.startPrank(carol);
        coinX.approve(address(dexPair), 22 ether);
        
        dexPair.swap(20 ether, 10 ether, 100 ether);
        vm.stopPrank();
    }

    function testRemoveLiquidityWithFee() public {
        testSwap1();

        vm.startPrank(alice);
        dexPair.removeLiquidity(200 ether, 100 ether, 300 ether);
        vm.stopPrank();
        
        assertEq(coinX.balanceOf(address(alice)) > 100 ether, true);
        assertEq(coinY.balanceOf(address(alice)) > 300 ether, true);
    }

    function testBugFix() public {
        vm.startPrank(alice);
        coinX.approve(address(dexPair), 100 ether);
        coinY.approve(address(dexPair), 100 ether);

        dexPair.addLiquidity(100 ether, 100 ether, 0);
        vm.stopPrank();

        vm.startPrank(dave);
        coinY.approve(address(dexPair), 1000);
        
        uint output = dexPair.swap(0 ether, 999, 0);
        vm.stopPrank();

        console2.log(output);

        assertEq(output, 999 - 1);
    }


    receive() external payable {}
}
