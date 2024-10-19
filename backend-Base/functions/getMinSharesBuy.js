import { ethers } from "ethers";
import contractData from "./setup.js";
import { parseEther } from "ethers/lib/utils.js";

export default async function getMinSharesBuy(betAmount,marketId,outcomeIndex) {
    const {contractAddress,abi}=contractData;
    const provider = new ethers.providers.JsonRpcProvider(`${process.env.ALCHEMY_NODE_API}`);
    const signer = new ethers.Wallet(`${process.env.PRIVATE_KEY}`, provider);
    const etherAmount=parseEther(betAmount);
    const marketContract =new ethers.Contract(contractAddress,abi, signer); 
    const minSharesToBuy=await marketContract.calcBuyAmount(marketId,etherAmount,outcomeIndex);
    return minSharesToBuy;
}