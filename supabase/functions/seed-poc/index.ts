// seed-poc/index.ts

import { serve } from "https://deno.land/std/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js";

interface SeedRequest {
  sha256_id: string;
  numbers: string[];
  first_name?: string;
  last_name?: string;
  source?: string;
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
    const body: SeedRequest = await req.json();
    const { sha256_id, numbers, first_name, last_name, source = "poc_source" } = body;

    // Validate input
    if (!sha256_id || !numbers || !Array.isArray(numbers) || numbers.length === 0) {
      return new Response(JSON.stringify({
        error: "Missing sha256_id or numbers array"
      }), { 
        status: 400,
        headers: { 
          "Content-Type": "application/json",
          'Access-Control-Allow-Origin': '*',
        }
      });
    }

    let insertedCount = 0;

    // Loop through and insert each number
    for (let index = 0; index < numbers.length; index++) {
      const number = numbers[index];

      // Check if candidate already exists
      const { data: existing, error: fetchError } = await supabase
        .from("phone_candidates")
        .select("id")
        .eq("sha256_id", sha256_id)
        .eq("mobile_number", number)
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

      // Only insert if not already existing
      if (!existing) {
        const { error: insertError } = await supabase
          .from("phone_candidates")
          .insert({
            sha256_id,
            mobile_number: number,
            first_name,
            last_name,
            source,
            status: "untested",
            priority_order: index
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

        insertedCount++;
      }
    }

    // Return success response
    return new Response(JSON.stringify({
      status: "success",
      inserted_count: insertedCount
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
