const apiKey = "AQ.Ab8RN6IwhjZoaLgFto_wlOYDVbQbbUL3_g6puqm60ezpLP1rRw";

async function run() {
  try {
    const url = `https://generativelanguage.googleapis.com/v1beta/models?key=${apiKey}`;
    const response = await fetch(url);
    const data = await response.json();
    console.log("Available models:");
    if (data.models) {
      data.models.forEach(model => {
        console.log(`- ${model.name}`);
      });
    } else {
      console.log(data);
    }
  } catch (error) {
    console.error("Error fetching models:", error.message);
  }
}

run();
