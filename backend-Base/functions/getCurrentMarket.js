import { createClient } from "@supabase/supabase-js";
import dotenv from "dotenv";
import contractData from "./setup.js";
import { ethers } from "ethers";
dotenv.config()
// Create a single supabase client for interacting with your database
export default async function getCurrentMarket(marketId) {
    console.log(marketId)

    const supabase = createClient(
        `${process.env.SUPA_BASE_URL}`,
        `${process.env.SUPA_BASE_KEY}`
      );

    const { data, error } = await supabase.from("Markets").select().eq('market_id', marketId);
    const {contractAddress,abi}=contractData;
    const provider = new ethers.providers.JsonRpcProvider(`${process.env.ALCHEMY_NODE_API}`);
    const signer = new ethers.Wallet(`${process.env.PRIVATE_KEY}`, provider);
    const marketContract =new ethers.Contract(contractAddress,abi, signer); 
    const numMarkets=await marketContract.getNumMarkets();
    console.log(numMarkets);
    const response=await marketContract.getMarket(marketId);
    const outcome1=await marketContract.getOutcome(marketId,0);
    const outcome2=await marketContract.getOutcome(marketId,1);
    console.log(outcome1,outcome2);
    return data;
}
