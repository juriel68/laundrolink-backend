// src/config/externalServices.js
import { v2 as cloudinary } from "cloudinary";
import sgMail from '@sendgrid/mail';
import dotenv from 'dotenv';
// 🟢 NEW: Import PayPal SDK
import paypal from '@paypal/checkout-server-sdk';

dotenv.config();

// --- SendGrid Mail ---
sgMail.setApiKey(process.env.SENDGRID_API_KEY);

// --- Cloudinary ---
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

// --- 🟢 NEW: PayPal Setup ---
const clientId = process.env.PAYPAL_CLIENT_ID;
const clientSecret = process.env.PAYPAL_CLIENT_SECRET;

// Choose environment based on .env
let environment = new paypal.core.SandboxEnvironment(clientId, clientSecret);
if (process.env.PAYPAL_MODE === 'live') {
    environment = new paypal.core.LiveEnvironment(clientId, clientSecret);
}

const paypalClient = new paypal.core.PayPalHttpClient(environment);

export { cloudinary, sgMail, paypalClient, paypal };