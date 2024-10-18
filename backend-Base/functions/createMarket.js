import { createClient } from "@supabase/supabase-js";
import { ethers } from "ethers";
import contractData from "./setup.js";
import dotenv from "dotenv";
dotenv.config()


// Function to create a market
export default async function createMarket({
  deadline,
  description,
  icon,
  question,
  outcome1,
  outcome2,
  category,
  fightImage,
}) {
  console.log("I am active now");
  const {contractAddress,abi}=contractData;
  const provider = new ethers.JsonRpcProvider(`${process.env.ALCHEMY_NODE_API}`);
  const signer = new ethers.Wallet(`${process.env.PRIVATE_KEY}`, provider);
  const deadlineIn = Math.floor(new Date(deadline).getTime() / 1000);
  const marketContract =new ethers.Contract(contractAddress,abi, signer); 
try{
  const tx = await marketContract.initMarket(
    [
    outcome1,
    outcome2
  ],
    deadlineIn
  );
  
  console.log("Creating market...");
  const receipt = await tx.wait();
  console.log("✅ Market has been created -> Transaction Hash:", receipt.transactionHash);

  // Fetch current liquidity
  const currentLiq = await marketContract.currentLiquidity();
  console.log(currentLiq);
  // Initialize Supabase client
  const supabase = createClient(
    `${process.env.SUPA_BASE_URL}`,
    `${process.env.SUPA_BASE_KEY}`
  );

  // Get the latest market ID
  const { data: latestMarket, error: latestMarketError } = await supabase
      .from("Markets")
      .select("market_id")
      .order("market_id", { ascending: false })
      .limit(1)
      .single();

    // if (latestMarketError) {
    //   throw new Error(`Error fetching latest market ID: ${latestMarketError.message}`);
    // }
  const newMarketId = latestMarket ? latestMarket.market_id + 1 : 1;
  
  const { data, error } = await supabase.from("Markets").insert({
    market_id: newMarketId,
    active: true,
    deadline,
    description,
    icon,
    question,
    settled: false,
    category,
    created_at: new Date().toISOString(),
    outcomes: [
      {
        name: outcome1,
        winner: false,
        num_shares_in_pool: parseInt((currentLiq*2569/10**11).toString()) / 10 / 2,
      },
      {
        name: outcome2,
        winner: false,
        num_shares_in_pool: parseInt((currentLiq*2569/10**11).toString()) / 10 / 2,
      },
    ],
    fightimage: fightImage,
  });

  if (error) {
    console.error("Error inserting market into Supabase:", error);
  } else {
    console.log("Market inserted into Supabase:", data);
  }
}catch(err){
  console.log(err);
}
  
}
