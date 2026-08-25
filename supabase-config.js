// Safe to be public: this is the "publishable" key, designed to be used from
// browser code. Row Level Security on the database is what actually protects
// the data — this key alone cannot read or modify anything sensitive.
window.SUPABASE_URL = "https://srhopldaiqdyybomnhsh.supabase.co";
window.SUPABASE_ANON_KEY = "sb_publishable_NN--xuNPdjUxQ4_TVaA7LA_KUKJMOci";

async function submitContact({ nombre, email, whatsapp, consent, source, testAnswers, testResultTop, testResultSecond }) {
  const res = await fetch(`${window.SUPABASE_URL}/rest/v1/rpc/submit_contact`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "apikey": window.SUPABASE_ANON_KEY
    },
    body: JSON.stringify({
      p_name: nombre,
      p_email: email,
      p_whatsapp: whatsapp,
      p_consent: consent,
      p_source: source,
      p_test_answers: testAnswers || null,
      p_test_result_top: testResultTop || null,
      p_test_result_second: testResultSecond || null
    })
  });
  if (!res.ok) {
    throw new Error("No se pudo guardar tus datos. Inténtalo de nuevo.");
  }
}
