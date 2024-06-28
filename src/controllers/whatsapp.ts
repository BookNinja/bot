import { RequestHandler } from "express";

export const whatsapp: RequestHandler = (req, res) => {
  const incomingMsg = req.body.Body;
  const from = req.body.From;

  console.log(`Received message from ${from}: ${incomingMsg}`);

  // Respond to Twilio. This is required to let Twilio know you've received the message successfully.
  res.status(200).send("<Response></Response>"); // Send an empty TwiML response
};
