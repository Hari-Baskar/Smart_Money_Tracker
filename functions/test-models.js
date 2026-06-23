const { GoogleGenerativeAI } = require('@google/generative-ai');

// Use the key they provided
const apiKey = "AQ.Ab8RN6IwhjZoaLgFto_wlOYDVbQbbUL3_g6puqm60ezpLP1rRw";
const genAI = new GoogleGenerativeAI(apiKey);

async function run() {
  try {
    console.log("Fetching available models...");
    // Wait, generative-ai SDK doesn't expose ListModels directly easily.
    // Let's just try to call gemini-1.5-flash and catch the error.
    const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });
    const result = await model.generateContent("Hello!");
    console.log("Success! Response:", result.response.text());
  } catch (error) {
    console.error("Error from Gemini API:", error.message);
  }
}

run();
