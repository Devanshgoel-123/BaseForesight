import express from "express"
import cors from "cors";
import bodyParser from "body-parser";
import createMarket from "../functions/createMarket.js";
import getAllMarkets  from "../functions/getAllMarkets.js";
import getCurrentMarket from "../functions/getCurrentMarket.js";
import updateMarket from "../functions/updateMarket.js";
import getOutcomes from "../functions/getOutcomes.js";
import addLiquidity from "../functions/AddLiquidity.js";
import getMinSharesBuy from "../functions/getMinSharesBuy.js";
import getMarketsforUsers from "../functions/getMarketsForUser.js";
import getMinAmountSell from "../functions/getMinAmountOnSellShares.js";
import settleMarket from "../functions/settleMarket.js";
const app=express();
const PORT=3000;

app.use(bodyParser.urlencoded({extended:true}));
app.use(express.json());
app.use(cors());

app.post("/settleMarket",async(req,res)=>{
  console.log("Trying to Settle");
  try{
    const {marketId}=req.body;
    console.log("trying to settle")
    const response=await settleMarket(marketId);
    return response;
  }catch(err){
    console.log(err);
  }
})
app.get('/min-amount-sell/:marketId/:outcomeIndex/:betAmount',async(req,res)=>{
  try {
    const {betAmount,outcomeIndex,marketId}=req.params;
    if (!betAmount || isNaN(betAmount)) {
      return res.status(400).send("Invalid bet amount");
    }
    const data = await getMinAmountSell(betAmount,marketId,outcomeIndex);
    res.status(200).send(data._hex);
  } catch (error) {
    console.error("Error getting current market:", error);
    res.status(500).send("An error occurred while getting current market");
  }
})
app.get('/min-shares-buy/:marketId/:outcomeIndex/:betAmount',async(req,res)=>{
  try {
    const {betAmount,outcomeIndex,marketId}=req.params;
    if (!betAmount || isNaN(betAmount)) {
      return res.status(400).send("Invalid bet amount");
    }
    const data = await getMinSharesBuy(betAmount,marketId,outcomeIndex);
    res.status(200).send(data._hex);
  } catch (error) {
    console.error("Error getting current market:", error);
    res.status(500).send("An error occurred while getting current market");
  }
})
app.get('/getmarketsforUser/:address',async(req,res)=>{
  try{
    const address=req.params.address;
    const response=await getMarketsforUsers(address);
    console.log("THe received response is :",response);
    res.status(200).send(response)
  }catch(err){
    console.log(err);
  }
})

app.post("/create-market", async (req, res) => {
    try {
      let { deadline, description, icon, question, outcome1, outcome2, category, fightImage } = req.body;
       const response=await createMarket({deadline, description, icon, question, outcome1, outcome2, category, fightImage});
       if(response==="Market Created Successfully"){
        res.status(200).send("Market Created!");
       }else{
        res.status(400).send("Some Error has Occured")
       }
    } catch (error) {
      console.error("Error creating market:", error);
      res.status(500).send("An error occurred while creating market");
    }
  })
  app.get("/get-current-market/:market_id", async (req, res) => {
    try {
      const data = await getCurrentMarket(req.params.market_id);
      console.log(data);
      res.status(200).send(data);
    } catch (error) {
      console.error("Error getting current market:", error);
      res.status(500).send("An error occurred while getting current market");
    }
  })
  app.get("/get-outcomes/:market_id", async (req, res) => {
    try {
      const {outcome1,outcome2} = await getOutcomes(req.params.market_id);
      res.status(200).send([outcome1,outcome2]);
    } catch (error) {
      console.error("Error getting current market:", error);
      res.status(500).send("An error occurred while getting current market");
    }
  })
  
  app.get("/get-all-markets", async (req, res) => {
    try {
      const data = await getAllMarkets();
      console.log(data)
      res.status(200).send(data);
    } catch (error) {
      console.error("Error getting all markets:", error);
      res.status(500).send("An error occurred while getting all markets");
    }
  })
  
  app.post("/update-market", async (req, res) => {
    try {
      let { marketId, outcomeIndex, amount, isBuy, sharesUpdated } = req.body;
      await updateMarket(marketId, outcomeIndex, amount, isBuy, sharesUpdated); 
      res.status(200).send("Market Updated!");
    } catch (error) {
      console.error("Error updating market:", error);
      res.status(500).send("An error occurred while updating market");
    }
  })

  app.get('/add-liquidity',async (req,res)=>{
    try{
      console.log("Adding liquidity")
     const response=await addLiquidity();
     if(res=="Error has occured while adding liquidity"){
       res.status(500).send(response)
     }else{
      res.status(200).send({
        message:"Added Liquidity"
       })
     }
    }catch(err){
      console.log(err);
    }  
  })

app.get("/", (req, res) => res.send("Express on Vercel"));

app.listen(PORT,()=>{
    console.log(`Listening on PORT : ${PORT}`)
})

export default app;