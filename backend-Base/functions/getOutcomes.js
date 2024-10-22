
import dotenv from "dotenv";
import contractData from "./setup.js";
import { ethers } from "ethers";
dotenv.config()
// Create a single supabase client for interacting with your database
export default async function getOutcomes(marketId) {
    
    const {contractAddress,abi}=contractData;
    const provider = new ethers.providers.JsonRpcProvider(`${process.env.ALCHEMY_NODE_API}`);
    const signer = new ethers.Wallet(`${process.env.PRIVATE_KEY}`, provider);
    const marketContract =new ethers.Contract(contractAddress,abi, signer); 
    const liquidity=await marketContract.currentLiquidity();
    console.log(liquidity);
    const outcome1=await marketContract.getOutcome(marketId,0);
    const outcome2=await marketContract.getOutcome(marketId,1);
    return {outcome1,outcome2};
}
