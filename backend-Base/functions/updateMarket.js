import { createClient } from "@supabase/supabase-js";
import dotenv from "dotenv";
dotenv.config()
// Create a single supabase client for interacting with your database
export default async function updateMarket(marketId, outcomeIndex, amount, isBuy, sharesUpdated) {

    console.log(marketId, outcomeIndex, amount, isBuy, sharesUpdated);

    const supabase = createClient(
        `${process.env.SUPA_BASE_URL}`,
        `${process.env.SUPA_BASE_KEY}`
      );

    const { data: markets } = await supabase.from("Markets").select().eq("market_id", marketId).limit(1);
    let currentMarket = markets[0];
    console.log("current market is ",currentMarket)
    for (let i = 0; i < currentMarket.outcomes.length; i++) {
        let outcome = currentMarket.outcomes[i];
        console.log("The outcomes is:",outcome);
        if (isBuy) {
            if (i == outcomeIndex) {
                outcome.numSharesInPool = parseInt(outcome.numSharesInPool) + parseInt(amount) - parseInt(sharesUpdated);
                console.log(outcome.numSharesInPool)
            } else {
                outcome.numSharesInPool= parseInt(outcome.numSharesInPool) + parseInt(amount);
                console.log(outcome.numSharesInPool)
            }
        }
        else {
            if (i == outcomeIndex) {
                outcome.numSharesInPool = parseInt(outcome.numSharesInPool) + parseInt(sharesUpdated) - parseInt(amount);
                console.log(outcome.numSharesInPool)
            } else {
                outcome.numSharesInPool = parseInt(outcome.numSharesInPool) - parseInt(amount);
                console.log(outcome.numSharesInPool)
            }
        }
    }

    const { data, error } = await supabase.from("Markets").update({
        outcomes: [
            {
                name: currentMarket.outcomes[0].name,
                winner: false,
                numSharesInPool: currentMarket.outcomes[0].numSharesInPool,
            },
            {
                name: currentMarket.outcomes[1].name,
                winner: false,
                numSharesInPool: currentMarket.outcomes[1].numSharesInPool,
            },
        ],
    }).eq("market_id", marketId);
    console.log("data", data);
    console.log("error", error);
}