# SalesTheory.io - AI-Driven Sales Coaching Platform

Real-time AI coaching that helps salespeople close more deals with intelligent, context-aware suggestions.

## 🚀 Features

- **Real-Time Suggestions**: Get contextual responses during live sales calls
- **Deep Intelligence**: AI understands your company and prospects
- **Continuous Learning**: Improves with every call through ML
- **Live Transcription**: Real-time speech-to-text processing
- **Prospect Research**: Automated enrichment and pain point detection
- **Playbook Optimization**: Track what works and optimize sales methodologies

## 🛠️ Tech Stack

- **Frontend**: Next.js 14, TypeScript, Tailwind CSS
- **Database**: Supabase (PostgreSQL)
- **AI**: OpenAI/Anthropic APIs
- **Real-time**: WebSockets, WebRTC
- **Transcription**: Deepgram/Whisper API
- **Vector DB**: Pinecone for embeddings
- **Deployment**: Vercel

## 📦 Installation

1. Clone the repository:
```bash
git clone https://github.com/thedarksco/salestheory-io.git
cd salestheory-io
```

2. Install dependencies:
```bash
npm install
```

3. Set up environment variables:
```bash
cp .env.example .env
```
Fill in your API keys and Supabase credentials.

4. Run the development server:
```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) to view the application.

## 🗄️ Database Setup

1. Create a Supabase project at [supabase.com](https://supabase.com)
2. Run the migration script in `supabase/migrations/001_initial_schema.sql`
3. Update `.env` with your Supabase credentials

## 🚢 Deployment

The app is configured for easy deployment on Vercel:

[![Deploy with Vercel](https://vercel.com/button)](https://vercel.com/new/clone?repository-url=https://github.com/thedarksco/salestheory-io)

## 📝 Environment Variables

Required environment variables:

- `NEXT_PUBLIC_SUPABASE_URL`: Your Supabase project URL
- `NEXT_PUBLIC_SUPABASE_ANON_KEY`: Your Supabase anon key
- `SUPABASE_SERVICE_ROLE_KEY`: Your Supabase service role key
- `OPENAI_API_KEY`: OpenAI API key for AI suggestions
- `DEEPGRAM_API_KEY`: Deepgram API key for transcription

See `.env.example` for all variables.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License.