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

    for (let i = 0; i < currentMarket.outcomes.length; i++) {
        let outcome = currentMarket.outcomes[i];
        if (isBuy) {
            if (i == outcomeIndex) {
                outcome.num_shares_in_pool = parseInt(outcome.num_shares_in_pool) + parseInt(amount*2569) - parseInt(sharesUpdated);
            } else {
                outcome.num_shares_in_pool = parseInt(outcome.num_shares_in_pool) + parseInt(amount*2569);
            }
        }
        else {
            if (i == outcomeIndex) {
                outcome.num_shares_in_pool = parseInt(outcome.num_shares_in_pool) + parseInt(sharesUpdated) - parseInt(amount*2569);
            } else {
                outcome.num_shares_in_pool = parseInt(outcome.num_shares_in_pool) - parseInt(amount*2569);
            }
        }
    }

    const { data, error } = await supabase.from("Markets").update({
        outcomes: [
            {
                name: currentMarket.outcomes[0].name,
                winner: false,
                num_shares_in_pool: currentMarket.outcomes[0].num_shares_in_pool,
            },
            {
                name: currentMarket.outcomes[1].name,
                winner: false,
                num_shares_in_pool: currentMarket.outcomes[1].num_shares_in_pool,
            },
        ],
    }).eq("market_id", marketId);

    console.log("data", data);
    console.log("error", error);
}