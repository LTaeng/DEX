// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";

contract Dex is ERC20 {
    using SafeERC20 for IERC20;

    IERC20 _tokenX;
    IERC20 _tokenY;
    uint public k;

    constructor(address tokenX, address tokenY) ERC20("DreamAcademy DEX LP token", "DA-DEX-LP") {
        require(tokenX != tokenY, "DA-DEX: Tokens should be different");

        _tokenX = IERC20(tokenX);
        _tokenY = IERC20(tokenY);
    }

    function swap(uint256 tokenXAmount, uint256 tokenYAmount, uint256 tokenMinimumOutputAmount)
        external
        returns (uint256 outputAmount)
    {
        (IERC20 inputToken, IERC20 outputToken, uint input, uint output) = 
            (tokenXAmount < tokenYAmount) ? (_tokenY, _tokenX, tokenYAmount, tokenXAmount) : (_tokenX, _tokenY, tokenXAmount, tokenYAmount);

        require(input != 0 && output == 0, "DEX: One of the two must be zero");
        return _swap(inputToken, outputToken, input, tokenMinimumOutputAmount);
    }

    function _swap(IERC20 inputToken, IERC20 outputToken, uint value, uint minimum) internal returns (uint256 outputAmount) {

        uint reserveInput = inputToken.balanceOf(address(this));
        uint reserveOutput = outputToken.balanceOf(address(this));

        require(inputToken.balanceOf(msg.sender) >= value, "DEX: Over than your balances");

        uint fee = (value > 1000) ? value / 1000 : 1;
        uint input = value - fee;

        outputAmount = reserveOutput - k / (reserveInput + input);
        require(outputAmount >= minimum, "DEX: lower than minimum output Tokens");

        inputToken.transferFrom(msg.sender, address(this), value);
        outputToken.transfer(msg.sender, outputAmount);
        k = (reserveInput + value) * (reserveOutput - outputAmount);
    }


    function addLiquidity(uint256 tokenXAmount, uint256 tokenYAmount, uint256 minimumLPTokenAmount)
        external
        returns (uint256 LPTokenAmount)
    {
        uint reserveX = IERC20(_tokenX).balanceOf(address(this));
        uint reserveY = IERC20(_tokenY).balanceOf(address(this));

        IERC20(_tokenX).transferFrom(msg.sender, address(this), tokenXAmount);
        IERC20(_tokenY).transferFrom(msg.sender, address(this), tokenYAmount);
        k = (reserveX + tokenXAmount) * (reserveY + tokenYAmount);

        if (totalSupply() == 0) {
            LPTokenAmount = sqrt(tokenXAmount * tokenYAmount);
        } else {
            LPTokenAmount = min(tokenXAmount * totalSupply() / reserveX, tokenYAmount * totalSupply() / reserveY);
        }

        require(LPTokenAmount > 0, "DEX: INSUFFICIENT_LIQUIDITY_MINTED");
        require(LPTokenAmount >= minimumLPTokenAmount, "DEX: lower than minimum LP Tokens");
        _mint(msg.sender, LPTokenAmount);
    }

    function removeLiquidity(uint256 LPTokenAmount, uint256 minimumTokenXAmount, uint256 minimumTokenYAmount)
        external returns (uint256 transferX, uint256 transferY)
    {
        require(balanceOf(msg.sender) >= LPTokenAmount, "DEX: Over than your balances");

        uint reserveX = IERC20(_tokenX).balanceOf(address(this));
        uint reserveY = IERC20(_tokenY).balanceOf(address(this));

        transferX = LPTokenAmount * reserveX / totalSupply();
        transferY = LPTokenAmount * reserveY / totalSupply();

        require(transferX >= minimumTokenXAmount, "DEX: lower than minimum X Tokens");
        require(transferY >= minimumTokenYAmount, "DEX: lower than minimum Y Tokens");

        _burn(msg.sender, LPTokenAmount);

        IERC20(_tokenX).transfer(msg.sender, transferX);
        IERC20(_tokenY).transfer(msg.sender, transferY);
        k = (reserveX - transferX) * (reserveY - transferY);
    }

    // From UniSwap core
    function sqrt(uint256 y) private pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }
}
