import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { createClient } from '@supabase/supabase-js';
import Groq from 'groq-sdk';

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json());

const PORT = process.env.PORT || 3000;
const GROQ_API_KEY = process.env.GROQ_API_KEY || '';
const GROQ_MODEL = process.env.GROQ_MODEL || 'llama-3.1-8b-instant';
const GROQ_FALLBACK_MODEL = process.env.GROQ_FALLBACK_MODEL || 'llama-3.3-70b-versatile';

const groq = new Groq({ apiKey: GROQ_API_KEY });

const SUPABASE_URL = process.env.SUPABASE_URL || '';
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY || '';
let supabase;
if (SUPABASE_URL && SUPABASE_SERVICE_ROLE_KEY) {
  supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
} else {
  console.warn('Warning: SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY not configured. Supabase client not initialized.');
}



// Helper: call Groq with automatic model fallback
async function callGroq(systemPrompt, userMessage) {
  const messages = [
    { role: 'system', content: systemPrompt },
    { role: 'user', content: userMessage },
  ];
  try {
    const completion = await groq.chat.completions.create({
      model: GROQ_MODEL,
      messages,
      temperature: 0.4,
      max_tokens: 512,
    });
    return completion.choices[0]?.message?.content || null;
  } catch (err) {
    console.warn(`Primary model (${GROQ_MODEL}) failed, trying fallback:`, err.message);
    const fallback = await groq.chat.completions.create({
      model: GROQ_FALLBACK_MODEL,
      messages,
      temperature: 0.4,
      max_tokens: 512,
    });
    return fallback.choices[0]?.message?.content || null;
  }
}

// --- Symptom Analysis Route ---
app.post('/analyze', async (req, res) => {
  try {
    const { description, answers = [] } = req.body;

    if (!description) {
      return res.status(400).json({ error: 'Symptom description is required.' });
    }

    if (!GROQ_API_KEY) {
      return res.status(503).json({ error: 'AI service is not configured. Please contact support.' });
    }

    const fullText = [description, ...answers].join(' ');

    const disclaimer = 'Clinical Disclaimer: Sharoni is an educational, research-based tool. It is NOT a certified medical device and should not replace professional medical evaluation, diagnosis, or treatment.';

    const systemPrompt = `You are Sharoni, a compassionate and knowledgeable medical triage assistant.
Analyze the patient's symptom description and return a JSON object with exactly these fields:
{
  "symptoms": [array of symptom strings detected],
  "possible_causes": "concise explanation of likely causes",
  "first_aid": "clear, step-by-step immediate self-care advice",
  "advice": "guidance on urgency and whether to see a doctor",
  "urgency_level": "routine | urgent | emergency"
}
Rules:
- Be concise but thorough. Respond ONLY with valid JSON — no markdown, no extra text.
- If chest pain is mentioned, always set urgency_level to "emergency".
- Always recommend professional care for high-risk symptoms.`;

    const aiResponse = await callGroq(systemPrompt, `Patient symptom report: "${fullText}"`);
    const parsed = JSON.parse(aiResponse);

    return res.json({
      status: 'complete',
      symptoms: parsed.symptoms || [],
      possible_causes: parsed.possible_causes,
      first_aid: parsed.first_aid,
      advice: parsed.advice,
      urgency_level: parsed.urgency_level || 'routine',
      disclaimer,
      ai_powered: true,
    });

  } catch (error) {
    console.error('Error in analyze route:', error);
    return res.status(500).json({ error: 'Failed to analyze symptoms. Please try again.' });
  }
});

app.listen(PORT, () => {
  console.log(`Sharoni backend listening on port ${PORT}`);
});
