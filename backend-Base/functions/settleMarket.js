import { createClient } from "@supabase/supabase-js";
import dotenv from "dotenv";
dotenv.config()

export default async function settleMarket(marketId) {
try{
  const supabase = createClient(
    `${process.env.SUPA_BASE_URL}`,
    `${process.env.SUPA_BASE_KEY}`
  );
  const { data,error} = await supabase.from("Markets").update({
    active:false,
    settled:true
  }).eq("market_id",marketId)
 console.log(data,error);
 return {data,error}

}catch(err){
  return "Some error has Occured"
  console.log(err);
}
  
}
