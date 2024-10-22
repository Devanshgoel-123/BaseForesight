import { createClient } from "@supabase/supabase-js";
import dotenv from "dotenv";
dotenv.config()

export default async function settleMarket(marketId,outcome) {
  console.log("tryin to settle market with id:",marketId);
try{
  const supabase = createClient(
    `${process.env.SUPA_BASE_URL}`,
    `${process.env.SUPA_BASE_KEY}`
  );
   const { data: markets } = await supabase.from("Markets").select().eq("market_id", marketId).limit(1);
    let currentMarket = markets[0];
    for (let i = 0; i < currentMarket.outcomes.length; i++) {
        if (outcome==i) {
            currentMarket.outcomes[i].winner=true;
            console.log(currentMarket.outcomes[i].winner)
        }
        else {
            currentMarket.outcomes[i].winner=false;
            console.log(currentMarket.outcomes[i].winner)
        }
    }
  const { data,error} = await supabase.from("Markets").update({
    active:false,
    settled:true,
    outcomes: [
      {
          name: currentMarket.outcomes[0].name,
          winner: currentMarket.outcomes[0].winner,
          numSharesInPool: currentMarket.outcomes[0].numSharesInPool,
      },
      {
          name: currentMarket.outcomes[1].name,
          winner: currentMarket.outcomes[1].winner,
          numSharesInPool: currentMarket.outcomes[1].numSharesInPool,
      },
  ]
  }).eq("market_id",marketId)
 console.log(data,error);
 return {data,error}

}catch(err){
  return "Some error has Occured"
  console.log(err);
}
  
}
