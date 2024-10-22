import { createClient } from "@supabase/supabase-js";
import dotenv from "dotenv";
import contractData from "./setup.js";
import { ethers } from "ethers";


dotenv.config()
// Create a single supabase client for interacting with your database
export default async function getMarketsforUsers(address) {
    const {contractAddress,abi}=contractData;
    const provider = new ethers.providers.JsonRpcProvider(`${process.env.ALCHEMY_NODE_API}`);
    const signer = new ethers.Wallet(`${process.env.PRIVATE_KEY}`, provider);
    const marketContract =new ethers.Contract(contractAddress,abi, signer); 
    try{
        const userBets=await marketContract.getAllUserBets((address).toString());
        const userBetsArray=[];
        userBets.map((bet,index)=>{
            userBetsArray.push({
                marketId:bet[0],
                Outcome1Tokens:parseInt(bet[1][0],16),
                Outcome2Tokens:parseInt(bet[1][1],16),
                isActive:bet[2],
                isSettled:bet[3]
            })
        })
        return userBetsArray;
    }catch(err){
        console.log(err)
        return err
    }
    
}
