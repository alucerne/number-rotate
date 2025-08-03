// mark-number/index.ts

import { serve } from "https://deno.land/std/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js";

interface MarkRequest {
  sha256_id: string;
  mobile_number: string;
  disposition: string;
  first_name?: string;
  last_name?: string;
  source?: string;
  agent_id?: string;
}

// Serve the function
serve(async (req) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      status: 200,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
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
    // Parse the request body
    const body: MarkRequest = await req.json();
    const { sha256_id, mobile_number, disposition, first_name, last_name, source, agent_id } = body;

    // Validate input
    if (!sha256_id || !mobile_number || !disposition) {
      return new Response(JSON.stringify({
        error: "Missing sha256_id, mobile_number, or disposition"
      }), { 
        status: 400,
        headers: { 
          "Content-Type": "application/json",
          'Access-Control-Allow-Origin': '*',
        }
      });
    }

    // Determine outcome
    let new_status: string;
    if (["wrong_number", "disconnected", "no_answer"].includes(disposition)) {
      new_status = "failed";
    } else if (["connected_good", "positive_interaction"].includes(disposition)) {
      new_status = "verified";
    } else {
      return new Response(JSON.stringify({
        error: "Invalid disposition"
      }), { 
        status: 400,
        headers: { 
          "Content-Type": "application/json",
          'Access-Control-Allow-Origin': '*',
        }
      });
    }

    const now = new Date().toISOString();

    // Check if candidate exists
    const { data: existingCandidate, error: fetchError } = await supabase
      .from("phone_candidates")
      .select("*")
      .eq("sha256_id", sha256_id)
      .eq("mobile_number", mobile_number)
      .single();

    if (fetchError && fetchError.code !== 'PGRST116') { // PGRST116 is "not found"
      return new Response(JSON.stringify({ error: fetchError.message }), { 
        status: 500,
        headers: { 
          "Content-Type": "application/json",
          'Access-Control-Allow-Origin': '*',
        }
      });
    }

    if (existingCandidate) {
      // Update existing candidate
      const { error: updateError } = await supabase
        .from("phone_candidates")
        .update({ 
          status: new_status,
          last_attempted_at: now,
          last_attempted_by: agent_id
        })
        .eq("sha256_id", sha256_id)
        .eq("mobile_number", mobile_number);

      if (updateError) {
        return new Response(JSON.stringify({ error: updateError.message }), { 
          status: 500,
          headers: { 
            "Content-Type": "application/json",
            'Access-Control-Allow-Origin': '*',
          }
        });
      }
    } else {
      // Insert new candidate
      const { error: insertError } = await supabase
        .from("phone_candidates")
        .insert({
          sha256_id,
          mobile_number,
          first_name,
          last_name,
          source,
          priority_order: 0,
          status: new_status,
          last_attempted_at: now,
          last_attempted_by: agent_id
        });

      if (insertError) {
        return new Response(JSON.stringify({ error: insertError.message }), { 
          status: 500,
          headers: { 
            "Content-Type": "application/json",
            'Access-Control-Allow-Origin': '*',
          }
        });
      }
    }

    // If verified, upsert into validated_phones
    if (["connected_good", "positive_interaction"].includes(disposition)) {
      const { error: upsertError } = await supabase
        .from("validated_phones")
        .upsert({
          sha256_id,
          mobile_number,
          first_name,
          last_name,
          wrong_number: false,
          disconnected: false,
          positive_interaction: (disposition === "positive_interaction"),
          verified_at: now
        });

      if (upsertError) {
        return new Response(JSON.stringify({ error: upsertError.message }), { 
          status: 500,
          headers: { 
            "Content-Type": "application/json",
            'Access-Control-Allow-Origin': '*',
          }
        });
      }
    }

    // Return success response
    return new Response(JSON.stringify({ 
      status: "success", 
      updated_status: new_status 
    }), {
      headers: { 
        "Content-Type": "application/json",
        'Access-Control-Allow-Origin': '*',
      },
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
