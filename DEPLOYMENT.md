# Deployment Instructions

This Flutter web app is deployed using GitHub Actions and Vercel.

## Setup

1. Get a Vercel token from: https://vercel.com/account/tokens
2. Add these secrets to GitHub repository:
   - `VERCEL_TOKEN` - Your Vercel API token
   - `VERCEL_ORG_ID` - Your organization ID (optional)
   - `VERCEL_PROJECT_ID` - Your project ID (optional)

## Manual Deployment

1. Build locally:
   ```bash
   flutter clean
   flutter pub get
   flutter build web --release
