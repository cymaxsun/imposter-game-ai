# 🎭 Imposter Game AI

An AI-powered party game where players try to find the imposter! Built with **Ionic/Angular** for mobile and **Vercel Serverless Functions** for the backend.

## Features

- 🤖 **AI-Generated Word Lists** - Uses Google Gemini to create themed word lists
- 📱 **Mobile-First Design** - Built with Ionic for iOS and Android
- ⚡ **Serverless Backend** - Vercel functions with automatic model fallback
- 🔄 **Smart Fallback** - Automatically switches between Gemini models if quota is exceeded

## Project Structure

```
├── api/                    # Vercel Serverless Functions
│   └── generate-words.js   # AI word generation endpoint
├── mobile/                 # Ionic/Angular Mobile App
│   └── src/
└── vercel.json            # Vercel deployment config
```

## Getting Started

### Prerequisites
- Node.js 18+
- Vercel CLI (`npm install -g vercel`)
- Gemini API Key from [Google AI Studio](https://aistudio.google.com/)

### Setup

1. **Clone the repo**
   ```bash
   git clone https://github.com/cymaxsun/imposter-game-ai.git
   cd imposter-game-ai
   ```

2. **Install API dependencies**
   ```bash
   npm install
   ```

3. **Set up environment variables**
   ```bash
   echo "GEMINI_API_KEY=your_key_here" > .env
   ```

4. **Run the API locally**
   ```bash
   vercel dev --listen 3002
   ```

5. **Run the mobile app** (in a new terminal)
   ```bash
   cd mobile
   npm install
   npm run start
   ```

## Deployment

### Deploy API to Vercel
```bash
vercel --prod
```

Then add `GEMINI_API_KEY` in **Vercel Dashboard → Settings → Environment Variables**.

### Build Mobile App
```bash
cd mobile
ionic build
npx cap sync
```

## API Endpoints

### POST `/api/generate-words`

Generates a list of themed words using AI.

**Request:**
```json
{
  "topic": "Marvel Superheroes"
}
```

**Response:**
```json
{
  "words": ["Iron Man", "Thor", "Spider-Man", ...]
}
```

## Tech Stack

- **Frontend:** Ionic, Angular, Tailwind CSS
- **Backend:** Vercel Serverless Functions
- **AI:** Google Gemini API (`gemini-2.5-flash-lite` with fallback to `gemini-2.5-flash`)

## License

MIT
