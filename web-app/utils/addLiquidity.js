import { Contract, utils } from "ethers";
import {
    TOKEN_CONTRACT_ADDRESS, TOKEN_CONTRACT_ABI,
    EXCHANGE_CONTRACT_ADDRESS, EXCHANGE_CONTRACT_ABI
} from "../constants/index";
import { getEtherBalance, getReserveOfTokens } from "./getAmount";

async function _calculateTokens(signer, amountEth) {
    const parsedAmountEth = utils.parseEther(amountEth);
    const etherBalance = await getEtherBalance(signer, EXCHANGE_CONTRACT_ADDRESS);
    const tokenReserves = await getReserveOfTokens(signer);
    return (parsedAmountEth * tokenReserves) / etherBalance;
}

export const addLiquidity = async function addLiquidity(signer, address, amountEth) {
    try {
        const tokenContract = new Contract(
            TOKEN_CONTRACT_ADDRESS,
            TOKEN_CONTRACT_ABI,
            signer
        );
        const exchangeContract = new Contract(
            EXCHANGE_CONTRACT_ADDRESS,
            EXCHANGE_CONTRACT_ABI,
            signer
        )
        amountToken = await _calculateTokens(signer, amountEth);

        let tx = await tokenContract.approve(address, EXCHANGE_CONTRACT_ADDRESS, amountToken);
        await tx.wait(1);
        tx = await exchangeContract.addLiquidity(amountToken, { value: amountEth });
        await tx.wait(1);
    }
    catch (error) {
        console.error(error);
    }
}