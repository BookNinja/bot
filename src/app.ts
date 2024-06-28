import express, { Request, Response } from "express";
import useWhatsapp  from "@routes/useWhatsapp";

const app = express();
const PORT = process.env.PORT || 4000;

app.use(express.urlencoded({ extended: true }));
app.use(express.json());

app.get("/", (req: Request, res: Response) => {
  res.send("I'm alive!");
});

app.use("/whatsapp", useWhatsapp);

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});

export default app;
