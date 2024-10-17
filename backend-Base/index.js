import express from "express"
import cors from "cors";
import bodyParser from "body-parser";
import createMarket from "./functions/createMarket.js";
import getAllMarkets  from "./functions/getAllMarkets.js";
import getCurrentMarket from "./functions/getCurrentMarket.js";
import updateMarket from "./functions/updateMarket.js";
import addLiquidity from "./functions/AddLiquidity.js";
const app=express();
const PORT=4000;

app.use(bodyParser.urlencoded({extended:true}));
app.use(express.json());
app.use(cors());

app.post("/create-market", async (req, res) => {
  console.log(req.body);
    try {
      let { deadline, description, icon, question, outcome1, outcome2, category, fightImage } = req.body;
       await createMarket({deadline, description, icon, question, outcome1, outcome2, category, fightImage});
      res.status(200).send("Market Created!");
    } catch (error) {
      console.error("Error creating market:", error);
      res.status(500).send("An error occurred while creating market");
    }
  })
  app.get("/get-current-market/:market_id", async (req, res) => {
    try {
      const data = await getCurrentMarket(req.params.market_id);
      res.status(200).send(data);
    } catch (error) {
      console.error("Error getting current market:", error);
      res.status(500).send("An error occurred while getting current market");
    }
  })
  
  app.get("/get-all-markets", async (req, res) => {
    try {
      const data = await getAllMarkets();
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
     await addLiquidity();
     res.status(200).send({
      message:"Added Liquidity"
     })
    }catch(err){
      console.log(err);
    }  
  })
  
app.get('/',(req,res)=>{
    console.log("i got called");
    res.send({
        message:"Hi there"
    })
    
})
app.listen(PORT,()=>{
    console.log(`Listening on PORT : ${PORT}`)
})