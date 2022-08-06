import { Contract, utils } from "ethers";
import {
    TOKEN_CONTRACT_ADDRESS, TOKEN_CONTRACT_ABI,
    EXCHANGE_CONTRACT_ADDRESS, EXCHANGE_CONTRACT_ABI
} from "../constants/index";

export const removeLiquidity = async (signer, address, amountLp) => {
    const tokenContract = new Contract(
        TOKEN_CONTRACT_ADDRESS,
        TOKEN_CONTRACT_ABI,
        signer);
    const exchangeContract = new Contract(
        EXCHANGE_CONTRACT_ADDRESS,
        EXCHANGE_CONTRACT_ABI,
        signer);
    const parsedAmountLp = utils.parseEther(amountLp);
    let tx = await exchangeContract.approve(address, EXCHANGE_CONTRACT_ADDRESS, parsedAmountLp);
    tx.wait(1);
    tx = await exchangeContract.removeLiquidity(parsedAmountLp);
    tx.wait(1);
}

export const getTokensAfterRemove = async (
    provider,
    amountLpWei,
    ethBalance,
    tokenReserve
) => {
    try {
        // Create a new instance of the exchange contract
        const exchangeContract = new Contract(
            EXCHANGE_CONTRACT_ADDRESS,
            EXCHANGE_CONTRACT_ABI,
            provider
        );
        // Get the total supply of `Crypto Dev` LP tokens
        const _totalSupply = await exchangeContract.totalSupply();
        // Here we are using the BigNumber methods of multiplication and division
        // The amount of Eth that would be sent back to the user after he withdraws the LP token
        // is calculated based on a ratio,
        // Ratio is -> (amount of Eth that would be sent back to the user / Eth reserve) = (LP tokens withdrawn) / (total supply of LP tokens)
        // By some maths we get -> (amount of Eth that would be sent back to the user) = (Eth Reserve * LP tokens withdrawn) / (total supply of LP tokens)
        // Similarly we also maintain a ratio for the `CD` tokens, so here in our case
        // Ratio is -> (amount of CD tokens sent back to the user / CD Token reserve) = (LP tokens withdrawn) / (total supply of LP tokens)
        // Then (amount of CD tokens sent back to the user) = (CD token reserve * LP tokens withdrawn) / (total supply of LP tokens)
        const _ethToRemove = ethBalance.mul(amountLpWei).div(_totalSupply);
        const _tokenToRemove = tokenReserve
            .mul(amountLpWei)
            .div(_totalSupply);
        return {
            _ethToRemove,
            _tokenToRemove,
        };
    } catch (err) {
        console.error(err);
    }
};