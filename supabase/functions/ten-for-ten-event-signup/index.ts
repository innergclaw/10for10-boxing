import "jsr:@supabase/functions-js/edge-runtime.d.ts";

type SignupPayload = {
  event_name?: string;
  parent_guardian_name?: string;
  phone?: string;
  email?: string;
  child_name?: string;
  child_age?: string | number;
  preferred_class?: string;
  notes?: string;
  source_page?: string;
  _gotcha?: string;
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function clean(value: unknown, max = 2000) {
  return String(value ?? "").replace(/\s+/g, " ").trim().slice(0, max);
}

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json; charset=utf-8",
      "Cache-Control": "no-store",
    },
  });
}

function validEmail(value: string) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value);
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { status: 204, headers: corsHeaders });
  if (req.method !== "POST") return json({ ok: false, error: "Method not allowed" }, 405);

  let body: SignupPayload;
  try {
    body = await req.json();
  } catch {
    return json({ ok: false, error: "Invalid request body" }, 400);
  }

  if (clean(body._gotcha)) return json({ ok: true, skipped: true });

  const email = clean(body.email, 320).toLowerCase();
  const childAge = Number(body.child_age);
  const record = {
    event_name: clean(body.event_name, 200),
    parent_guardian_name: clean(body.parent_guardian_name, 200),
    phone: clean(body.phone, 80),
    email,
    child_name: clean(body.child_name, 200),
    child_age: childAge,
    preferred_class: clean(body.preferred_class, 200),
    notes: clean(body.notes, 3000),
    source_page: clean(body.source_page, 1000),
    raw_payload: body,
  };

  if (!record.event_name || !record.parent_guardian_name || !record.phone || !record.child_name || !record.preferred_class) {
    return json({ ok: false, error: "All required signup fields must be completed" }, 400);
  }
  if (!validEmail(email)) return json({ ok: false, error: "A valid email is required" }, 400);
  if (!Number.isInteger(childAge) || childAge < 6 || childAge > 14) {
    return json({ ok: false, error: "Child age must be between 6 and 14" }, 400);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceRoleKey) {
    return json({ ok: false, error: "Signup storage is not configured" }, 500);
  }

  const response = await fetch(`${supabaseUrl}/rest/v1/ten_for_ten_event_signups`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "apikey": serviceRoleKey,
      "Authorization": `Bearer ${serviceRoleKey}`,
      "Prefer": "return=representation",
    },
    body: JSON.stringify(record),
  });

  const saved = await response.json().catch(() => []);
  if (!response.ok) {
    return json({ ok: false, error: "Signup could not be saved", details: saved }, 500);
  }

  return json({ ok: true, signup_id: saved?.[0]?.id || null });
});
