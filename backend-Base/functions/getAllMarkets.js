import { createClient } from "@supabase/supabase-js";
import dotenv from "dotenv";
import contractData from "./setup.js";
dotenv.config()
import { ethers } from "ethers";

export default async function getAllMarkets() {
  const { abi, contractAddress } = contractData;
    const provider = new ethers.providers.JsonRpcProvider(`${process.env.ALCHEMY_NODE_API}`);
    const signer = new ethers.Wallet(`${process.env.PRIVATE_KEY}`, provider);
    const marketContract = new ethers.Contract(contractAddress, abi, signer);
   const reason=await (marketContract.currentLiquidity())
   console.log(reason);
  const supabase = createClient(
    `${process.env.SUPA_BASE_URL}`,
    `${process.env.SUPA_BASE_KEY}`
  );

  const { data, error } = await supabase.from("Markets").select();

  console.log("error", error);

  return data;
}