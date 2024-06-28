import express from "express";
import { whatsapp } from "@controllers";

const router = express.Router();

router.post("/", whatsapp);

export default router;
