//SPDX-Licence-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Exchange is ERC20 {
    address public cryptoDevTokenAddress;

    constructor(address _cryptoDevToken)
        ERC20("Exchange Liquidity Token", "ELP")
    {
        require(_cryptoDevToken != address(0));
        cryptoDevTokenAddress = _cryptoDevToken;
    }

    function getReserve() public view returns (uint256) {
        return ERC20(cryptoDevTokenAddress).balanceOf(address(this));
    }

    function addLiquidity(uint256 _amount) public payable returns (uint256) {
        uint256 liquidity;
        uint256 ethBalance = address(this).balance;
        uint256 cryptoDevTokenReserve = getReserve();
        ERC20 cryptoDevToken = ERC20(cryptoDevTokenAddress);
        if (getReserve() == 0) {
            /* liquidity == ethBalance == msg.value */
            cryptoDevToken.transferFrom(msg.sender, address(this), _amount);
            liquidity = ethBalance;
            _mint(msg.sender, liquidity);
        } else {
            uint256 ethReserve = ethBalance - msg.value;
            uint256 cryptoDevTokenAmount = ((msg.value *
                cryptoDevTokenReserve) / (ethReserve));
            require(
                _amount >= cryptoDevTokenAmount,
                "Amount of tokens sent is less than the minimum tokens required"
            );
            cryptoDevToken.transferFrom(msg.sender, address(this), _amount);
            // (LP tokens to be sent to the user (liquidity)/ totalSupply of LP tokens in contract) = (Eth sent by the user)/(Eth reserve in the contract)
            liquidity = ((totalSupply() * msg.value) / ethReserve); // msg.value != liquidity ?
            _mint(msg.sender, liquidity);
        }
        return liquidity;
    }

    function removeLiquidity(uint256 _amount)
        public
        payable
        returns (uint256, uint256)
    {
        ERC20 cryptoDevToken = ERC20(cryptoDevTokenAddress);
        uint256 liquidityRatio = _amount / totalSupply();
        uint256 ethToWithdraw = address(this).balance * liquidityRatio;
        uint256 cryptoDevToWithdraw = getReserve() * liquidityRatio;
        require(balanceOf(msg.sender) > 0, "You do not have LP tokens");
        require(
            balanceOf(msg.sender) >= _amount,
            "You do not have such amount of LP tokens"
        );
        cryptoDevToken.transferFrom(
            address(this),
            msg.sender,
            cryptoDevToWithdraw
        );
        payable(address(this)).transfer(ethToWithdraw);
        _burn(msg.sender, _amount);
        // Transfer `ethAmount` of Eth from user's wallet to the contract
        payable(msg.sender).transfer(ethToWithdraw);
        // Transfer `cryptoDevTokenAmount` of Crypto Dev tokens from the user's wallet to the contract
        ERC20(cryptoDevTokenAddress).transfer(msg.sender, cryptoDevToWithdraw);
        return (ethToWithdraw, cryptoDevToWithdraw);
    }

    function getAmountOfTokens(
        uint256 inputAmount,
        uint256 inputReserve,
        uint256 outputReserve
    ) public pure returns (uint256) {
        require(inputReserve > 0 && outputReserve > 0, "invalid reserve");
        // We are charging a fee of `1%`
        // Input amount with fee = (input amount - (1*(input amount)/100)) = ((input amount)*99)/100
        uint256 inputAmountWithFee = (inputAmount * 99); // Not divided by 100 due to efficiency reasons
        // Because we need to follow the concept of `XY = K` curve
        // We need to make sure (x + Δx) * (y - Δy) = x * y
        // So the final formula is Δy = (y * Δx) / (x + Δx)
        // Δy in our case is `tokens to be received`
        // Δx = ((input amount)*99)/100, x = inputReserve, y = outputReserve
        // So by putting the values in the formula you can get the numerator and denominator
        uint256 numerator = inputAmountWithFee * outputReserve;
        // Below inputReserve must be multiplied with 100 because it was not devided in line 81
        uint256 denominator = (inputReserve * 100) + inputAmountWithFee;
        return (numerator / denominator);
    }

    function ethToCryptoDev(uint _minTokens) public payable {
        uint256 tokenReserve = getReserve();
        uint256 amountOfTokens = getAmountOfTokens(
            msg.value,
            (address(this).balance - msg.value),
            tokenReserve
        );
        require(
            amountOfTokens >= _minTokens,
            "Output value is lower than minTokens"
        );
        ERC20(cryptoDevTokenAddress).transfer(msg.sender, amountOfTokens);
    }

    function cryptoDevToEth(uint _tokensToSell, uint _minEth) public {
        uint256 tokenReserve = getReserve() - _tokensToSell;
        uint256 amountOfEth = getAmountOfTokens(
            _tokensToSell,
            tokenReserve,
            address(this).balance
        );
        require(amountOfEth > _minEth, "Output value is lower than minEth");
        ERC20(cryptoDevTokenAddress).transferFrom(
            msg.sender,
            address(this),
            _tokensToSell
        );

        payable(msg.sender).transfer(amountOfEth);
    }
}
