import { createClient } from "@supabase/supabase-js";
import dotenv from "dotenv";
dotenv.config()
// Create a single supabase client for interacting with your database
export default async function getCurrentMarket(marketId) {
    console.log(marketId)

    const supabase = createClient(
        `${process.env.SUPA_BASE_URL}`,
        `${process.env.SUPA_BASE_KEY}`
      );

    const { data, error } = await supabase.from("Markets").select().eq('market_id', marketId);

    console.log("data", data);
    console.log("error", error);
    return data;
}
