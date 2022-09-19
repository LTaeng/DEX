// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import './Math.sol';

contract DexPair is ERC20 {

    address public factory;
    address public tokenX;
    address public tokenY;

    uint public k;

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, "DEX: Locked");
        unlocked = 0;
        _;
        unlocked = 1;
    }

    constructor(address _tokenX, address _tokenY) ERC20("LTaeng LP Token", "LLT") {
        tokenX = _tokenX;
        tokenY = _tokenY;

        factory = msg.sender;
    }

    function swap(uint256 tokenXAmount, uint256 tokenYAmount, uint256 tokenMinimumOutputAmount) external lock returns (uint256 outputAmount) {
        (address inputToken, address outputToken, uint input, uint output) = 
            (tokenXAmount < tokenYAmount) ? (tokenY, tokenX, tokenYAmount, tokenXAmount) : (tokenX, tokenY, tokenXAmount, tokenYAmount);

        require(input != 0 && output == 0, "DEX: One of the two must be zero");
        return _swap(inputToken, outputToken, input, tokenMinimumOutputAmount);
    }

    function _swap(address inputToken, address outputToken, uint value, uint minimum) internal returns (uint256 outputAmount) {

        uint reserveInput = IERC20(inputToken).balanceOf(address(this));
        uint reserveOutput = IERC20(outputToken).balanceOf(address(this));

        require(IERC20(inputToken).balanceOf(msg.sender) >= value, "DEX: Over than your balances");

        uint input = value - (value / 1000);
        outputAmount = reserveOutput - k / (reserveInput + input);
        require(outputAmount >= minimum, "DEX: lower than minimum output Tokens");


        IERC20(inputToken).transferFrom(msg.sender, address(this), value);
        IERC20(outputToken).transfer(msg.sender, outputAmount);
    }


    function addLiquidity(uint256 tokenXAmount, uint256 tokenYAmount, uint256 minimumLPTokenAmount) external lock returns (uint256 LPTokenAmount) {
        require(IERC20(tokenX).balanceOf(msg.sender) >= tokenXAmount && 
                IERC20(tokenY).balanceOf(msg.sender) >= tokenYAmount, "DEX: Over than your balances");

        uint reserveX = IERC20(tokenX).balanceOf(address(this));
        uint reserveY = IERC20(tokenY).balanceOf(address(this));

        IERC20(tokenX).transferFrom(msg.sender, address(this), tokenXAmount);
        IERC20(tokenY).transferFrom(msg.sender, address(this), tokenYAmount);
        k = (reserveX + tokenXAmount) * (reserveY + tokenYAmount);

        if (totalSupply() == 0) {
            LPTokenAmount = Math.sqrt(tokenXAmount * tokenYAmount);
        } else {
            LPTokenAmount = Math.min(tokenXAmount * totalSupply() / reserveX, tokenYAmount * totalSupply() / reserveY);
        }

        require(LPTokenAmount > 0, "DEX: INSUFFICIENT_LIQUIDITY_MINTED");
        require(LPTokenAmount >= minimumLPTokenAmount, "DEX: lower than minimum LP Tokens");
        _mint(msg.sender, LPTokenAmount);

    }

    function removeLiquidity(uint256 LPTokenAmount, uint256 minimumTokenXAmount, uint256 minimumTokenYAmount) external lock {
        require(balanceOf(msg.sender) >= LPTokenAmount, "DEX: Over than your balances");

        uint reserveX = IERC20(tokenX).balanceOf(address(this));
        uint reserveY = IERC20(tokenY).balanceOf(address(this));

        uint tokenXAmount = LPTokenAmount * reserveX / totalSupply();
        uint tokenYAmount = LPTokenAmount * reserveY / totalSupply();

        require(tokenXAmount >= minimumTokenXAmount, "DEX: lower than minimum X Tokens");
        require(tokenYAmount >= minimumTokenYAmount, "DEX: lower than minimum Y Tokens");

        _burn(msg.sender, LPTokenAmount);

        IERC20(tokenX).transfer(msg.sender, tokenXAmount);
        IERC20(tokenY).transfer(msg.sender, tokenYAmount);
        k = (reserveX - tokenXAmount) * (reserveY - tokenYAmount);
    }


}