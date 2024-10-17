import { createClient } from "@supabase/supabase-js";
import dotenv from "dotenv";
dotenv.config()

export default async function getAllMarkets() {

  const supabase = createClient(
    `${process.env.SUPA_BASE_URL}`,
    `${process.env.SUPA_BASE_KEY}`
  );

  const { data, error } = await supabase.from("Markets").select();

  console.log("data", data);
  console.log("error", error);

  return data;
}