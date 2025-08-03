// next-number/index.ts

import { serve } from "https://deno.land/std/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js";

// Serve the function
serve(async (req) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      status: 200,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type',
      },
    });
  }

  // Create Supabase client using env vars
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!
  );

  try {
    // Get sha256_id from query parameters
    const url = new URL(req.url);
    const sha256_id = url.searchParams.get('sha256_id');

    if (!sha256_id) {
      return new Response(JSON.stringify({
        error: "Missing sha256_id parameter"
      }), { 
        status: 400,
        headers: { 
          "Content-Type": "application/json",
          'Access-Control-Allow-Origin': '*',
        }
      });
    }

    // 1. Check if validated number exists
    const { data: verified, error: verifiedError } = await supabase
      .from("validated_phones")
      .select("mobile_number, first_name, last_name")
      .eq("sha256_id", sha256_id)
      .single();

    if (verifiedError && verifiedError.code !== 'PGRST116') { // PGRST116 is "not found"
      return new Response(JSON.stringify({ error: verifiedError.message }), { 
        status: 500,
        headers: { 
          "Content-Type": "application/json",
          'Access-Control-Allow-Origin': '*',
        }
      });
    }

    if (verified) {
      return new Response(JSON.stringify({
        status: "verified",
        mobile_number: verified.mobile_number,
        first_name: verified.first_name,
        last_name: verified.last_name
      }), {
        headers: { 
          "Content-Type": "application/json",
          'Access-Control-Allow-Origin': '*',
        }
      });
    }

    // 2. Fallback to phone_candidates
    const { data: nextCandidate, error: candidateError } = await supabase
      .from("phone_candidates")
      .select("mobile_number, first_name, last_name")
      .eq("sha256_id", sha256_id)
      .eq("status", "untested")
      .order("priority_order", { ascending: true })
      .limit(1)
      .single();

    if (candidateError && candidateError.code !== 'PGRST116') { // PGRST116 is "not found"
      return new Response(JSON.stringify({ error: candidateError.message }), { 
        status: 500,
        headers: { 
          "Content-Type": "application/json",
          'Access-Control-Allow-Origin': '*',
        }
      });
    }

    if (nextCandidate) {
      return new Response(JSON.stringify({
        status: "candidate",
        mobile_number: nextCandidate.mobile_number,
        first_name: nextCandidate.first_name,
        last_name: nextCandidate.last_name
      }), {
        headers: { 
          "Content-Type": "application/json",
          'Access-Control-Allow-Origin': '*',
        }
      });
    }

    // No valid or untested numbers available
    return new Response(JSON.stringify({
      error: "No valid or untested numbers available"
    }), { 
      status: 404,
      headers: { 
        "Content-Type": "application/json",
        'Access-Control-Allow-Origin': '*',
      }
    });

  } catch (error) {
    return new Response(JSON.stringify({ 
      error: "Internal server error",
      details: error.message 
    }), { 
      status: 500,
      headers: { 
        "Content-Type": "application/json",
        'Access-Control-Allow-Origin': '*',
      }
    });
  }
});
